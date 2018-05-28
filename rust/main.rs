extern crate actix_web;
use actix_web::{http, server, App, HttpRequest, Responder, State};
use std::sync::{Arc, Mutex};

#[derive(Clone)]
struct AppState {
    counter: Arc<Mutex<i32>>,
}

fn index(_info: HttpRequest<AppState>) -> impl Responder {
    format!("Hello")
}

fn orderbook(state: State<AppState>) -> String {
    let mut current = state.counter.lock().unwrap();
    *current += 1;
    format!("hello {}", current)
}

fn main() {
    let initial_state = AppState {
        counter: Arc::new(Mutex::new(0)),
    };
    server::new(move || {
        App::with_state(initial_state.clone())
            .resource("/", |r| r.get().f(index))
            .route("/orderbook", http::Method::GET, orderbook)
    }).bind("127.0.0.1:8080")
        .unwrap()
        .run()
}
