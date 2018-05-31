use std::sync::{Arc, Mutex};

pub trait EventSourced {
    type Msg;
    fn update(&mut self, msg: Self::Msg);
}

pub struct ManagedState<S> {
    current_state: Arc<Mutex<S>>,
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
{
    pub fn new(initial_state: S) -> ManagedState<S> {
        ManagedState {
            current_state: Arc::new(Mutex::new(initial_state)),
        }
    }

    pub fn with_snapshot<F, A>(&self, f: F) -> A
    where
        F: Fn(&S) -> A,
    {
        let current_state = &*self.current_state.lock().unwrap();
        f(current_state)
    }

    pub fn dispatch(&self, msg: S::Msg) {
        let mut current_state = self.current_state.lock().unwrap();
        current_state.update(msg);
    }
}
