extern crate actix;
extern crate serde;
extern crate serde_json;

use std::fs::{File, OpenOptions};
use std::io;
use std::io::{BufRead, BufReader, Read, Write};
use std::sync::{Arc, Mutex};

use self::actix::Actor;

pub trait EventSourced {
    type Msg;
    fn update(&self, msg: Self::Msg) -> Self;
}

pub struct ManagedState<S> {
    current_state: Arc<Mutex<S>>,
    writer_addr: actix::Addr<actix::Syn, MsgWriter>,
}

// TODO why does the derived version not work?
impl<S> Clone for ManagedState<S> {
    fn clone(&self) -> ManagedState<S> {
        ManagedState {
            current_state: self.current_state.clone(),
            writer_addr: self.writer_addr.clone(),
        }
    }
}

impl<S> ManagedState<S>
where
    S: EventSourced,
    S: serde::Serialize,
    S: serde::de::DeserializeOwned,
    S::Msg: serde::Serialize,
    S::Msg: serde::de::DeserializeOwned,
{
    pub fn new(initial_state: S) -> io::Result<ManagedState<S>> {
        let state = Self::replay().or_else(|err| {
            println!("error: {}", err);
            Self::store_initial(initial_state)
        })?;
        let log_file = OpenOptions::new().write(true).append(true).create(true).open("log.txt")?;
        let writer = MsgWriter { log_file };
        let writer_addr: actix::Addr<actix::Syn, _> = writer.start();
        Ok(ManagedState {
            current_state: Arc::new(Mutex::new(state)),
            writer_addr: writer_addr,
        })
    }

    fn replay() -> io::Result<S> {
        let mut init_file = File::open("init.txt")?;
        let log_file = File::open("log.txt")?;

        let mut init_string = String::new();
        init_file.read_to_string(&mut init_string)?;

        let mut state: S = serde_json::from_str(&init_string)?;

        for line_res in BufReader::new(log_file).lines() {
            let line = line_res?;
            let msg: S::Msg = serde_json::from_str(&line)?;
            state = state.update(msg);
        }
        println!("replay ok");

        Result::Ok(state)
    }

    fn store_initial(initial_state: S) -> io::Result<S> {
        let json_initial = serde_json::to_string(&initial_state)?;
        let mut init_file = File::create("init.txt")?;
        init_file.write_all(json_initial.as_bytes())?;
        Result::Ok(initial_state)
    }

    pub fn with_snapshot<F, A>(&self, f: F) -> A
    where
        F: Fn(&S) -> A,
    {
        let current_state = &*self.current_state.lock().unwrap();
        f(current_state)
    }

    pub fn dispatch(&self, msg: S::Msg) {
        let json_msg = serde_json::to_string(&msg).unwrap();
        let mut writer_msg = WriteMsg {
            data: Box::new(json_msg),
        };
        let mut current_state = self.current_state.lock().unwrap();
        // Yes this is a busy wait while holding a mutex but this will only
        // block if the write buffer is full and the system is at capacity so
        // it's acceptable
        loop {
            match self.writer_addr.try_send(writer_msg) {
                Ok(_) => break,
                Err(actix::prelude::SendError::Full(m)) => {
                    writer_msg = m;
                }
                Err(actix::prelude::SendError::Closed(m)) => {
                    writer_msg = m;
                }
            }
        }
        *current_state = current_state.update(msg);
    }
}

struct WriteMsg {
    data: Box<String>,
}

impl actix::Message for WriteMsg {
    type Result = ();
}

struct MsgWriter {
    log_file: File,
}

impl actix::Actor for MsgWriter {
    type Context = actix::Context<Self>;
}

impl actix::Handler<WriteMsg> for MsgWriter {
    type Result = ();
    fn handle(&mut self, msg: WriteMsg, _ctx: &mut actix::Context<Self>) -> Self::Result {
        self.log_file.write_all(msg.data.as_bytes()).unwrap();
        self.log_file.write_all(b"\n").unwrap();
    }
}
