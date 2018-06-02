extern crate serde;
extern crate serde_json;

use std::fs::{File, OpenOptions};
use std::io;
use std::io::{Read, Write, BufRead, BufReader};
use std::sync::{Arc, Mutex};

pub trait EventSourced {
    type Msg;
    fn update(&mut self, msg: Self::Msg);
}

pub struct ManagedState<S> {
    current_state: Arc<Mutex<(S, File)>>,
}

// TODO why does the derived version not work?
impl<S> Clone for ManagedState<S> {
    fn clone(&self) -> ManagedState<S> {
        ManagedState {
            current_state: self.current_state.clone(),
        }
    }
}

impl<'de, 's, S> ManagedState<S>
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
        let log_file = OpenOptions::new().write(true).append(true).open("log.txt")?;
        Ok(ManagedState {
            current_state: Arc::new(Mutex::new((state, log_file))),
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
            state.update(msg)
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
        let (current_state, _) = &*self.current_state.lock().unwrap();
        f(current_state)
    }

    pub fn dispatch(&self, msg: S::Msg) {
        let json_msg = serde_json::to_string(&msg).unwrap();
        let mut current_state = self.current_state.lock().unwrap();
        // TODO do not block while holding the lock
        current_state.1.write_all(json_msg.as_bytes()).unwrap();
        current_state.1.write_all(b"\n").unwrap();
        current_state.0.update(msg);
    }
}
