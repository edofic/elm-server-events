extern crate actix_web;
extern crate serde_json;
#[macro_use]
extern crate serde_derive;

use actix_web::{http, server, App, HttpRequest, HttpResponse, Path, Responder, State};
use std::sync::{Arc, Mutex};

#[derive(Clone)]
struct AppState {
    orderbook: Arc<Mutex<Orderbook>>,
}

#[derive(Serialize)]
struct Orderbook {
    asks: Vec<Order>,
    bids: Vec<Order>,
}

#[derive(Serialize)]
struct Order {
    user_id: UserId,
    order_type: OrderType,
    price: Price,
}

type UserId = u32;

type Price = i32;

impl Orderbook {
    fn normalize(&mut self) {
        self.asks.sort_unstable_by_key(|o| o.price);
        self.bids.sort_unstable_by_key(|o| o.price);

        self.asks.truncate(100);
        self.bids.truncate(100);

        if self.asks.len() == 0 || self.bids.len() == 0 {
            return;
        }

        let bid_idx = self.bids.len() - 1;
        if self.asks[0].price <= self.bids[bid_idx].price {
            // match
            self.asks.remove(0);
            self.bids.remove(bid_idx);
        }
    }
}

#[derive(Serialize)]
enum OrderType {
    Buy,
    Sell,
}

fn index(_info: HttpRequest<AppState>) -> impl Responder {
    format!("Hello")
}

fn orderbook(state: State<AppState>) -> HttpResponse {
    let orderbook = &*state.orderbook.lock().unwrap();
    HttpResponse::Ok().json(orderbook)
}

fn place_order(state: State<AppState>, order: Order) {
    let mut orderbook = state.orderbook.lock().unwrap();
    match order.order_type {
        OrderType::Buy => orderbook.bids.push(order),
        OrderType::Sell => orderbook.asks.push(order),
    };
    orderbook.normalize();
}

fn place_bid(data: (State<AppState>, Path<(UserId, Price)>)) -> impl Responder {
    let state = data.0;
    let path = data.1;
    let order = Order {
        user_id: path.0,
        order_type: OrderType::Buy,
        price: path.1,
    };
    place_order(state, order);
    "ok"
}

fn place_ask(data: (State<AppState>, Path<(UserId, Price)>)) -> impl Responder {
    let state = data.0;
    let path = data.1;
    let order = Order {
        user_id: path.0,
        order_type: OrderType::Sell,
        price: path.1,
    };
    place_order(state, order);
    "ok"
}

fn main() {
    let initial_orderbook = Orderbook {
        asks: Vec::new(),
        bids: Vec::new(),
    };
    let initial_state = AppState {
        orderbook: Arc::new(Mutex::new(initial_orderbook)),
    };
    server::new(move || {
        App::with_state(initial_state.clone())
            .resource("/", |r| r.get().f(index))
            .route("/orderbook", http::Method::GET, orderbook)
            .route("/buy/{user}/{amount}", http::Method::GET, place_bid)
            .route("/sell/{user}/{amount}", http::Method::GET, place_ask)
    }).bind("127.0.0.1:8080")
        .unwrap()
        .run()
}
