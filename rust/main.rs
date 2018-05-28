extern crate actix_web;
use actix_web::{server, App, HttpRequest, Responder};

fn index(_info: HttpRequest) -> impl Responder {
    format!("Hello")
}

fn main() {
    server::new(
        || App::new()
            .resource("/", |r| r.get().f(index)))
        .bind("127.0.0.1:8080")
        .unwrap()
        .run()
}
