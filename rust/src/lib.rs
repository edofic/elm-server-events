extern crate serde;
extern crate serde_json;

use std::fs::File;
use std::io;
use std::io::Write;
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

impl<S> ManagedState<S>
where
    S: EventSourced,
    S: serde::Serialize,
    S::Msg: serde::Serialize,
{
    pub fn new(initial_state: S) -> io::Result<ManagedState<S>> {
        let json_initial = serde_json::to_string(&initial_state)?;
        let mut init_file = File::create("init.txt")?;
        init_file.write_all(json_initial.as_bytes())?;
        let log_file = File::create("log.txt")?;
        Ok(ManagedState {
            current_state: Arc::new(Mutex::new((initial_state, log_file))),
        })
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
