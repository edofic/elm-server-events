extern crate actix_web;
extern crate serde_json;
#[macro_use]
extern crate serde_derive;

mod lib;

use actix_web::{http, server, App, HttpRequest, HttpResponse, Path, Responder, State};

use lib::{EventSourced, ManagedState};

type AppState = ManagedState<Orderbook>;

#[derive(Serialize, Deserialize)]
struct Orderbook {
    asks: Vec<Order>,
    bids: Vec<Order>,
}

#[derive(Serialize, Deserialize)]
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

#[derive(Serialize, Deserialize)]
enum OrderType {
    Buy,
    Sell,
}

impl EventSourced for Orderbook {
    type Msg = Order;
    fn update(&mut self, msg: Self::Msg) {
        let order = msg;
        match order.order_type {
            OrderType::Buy => self.bids.push(order),
            OrderType::Sell => self.asks.push(order),
        };
        self.normalize();
    }
}

fn index(_info: HttpRequest<AppState>) -> impl Responder {
    format!("Hello")
}

fn orderbook(state: State<AppState>) -> HttpResponse {
    state.with_snapshot(|orderbook| HttpResponse::Ok().json(&orderbook))
}

fn place_bid(data: (State<AppState>, Path<(UserId, Price)>)) -> impl Responder {
    let state = data.0;
    let path = data.1;
    let order = Order {
        user_id: path.0,
        order_type: OrderType::Buy,
        price: path.1,
    };
    state.dispatch(order);
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
    state.dispatch(order);
    "ok"
}

fn main() {
    let initial_orderbook = Orderbook {
        asks: Vec::new(),
        bids: Vec::new(),
    };
    let initial_state = ManagedState::new(initial_orderbook).unwrap();
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
