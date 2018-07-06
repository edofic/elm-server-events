extern crate actix;
extern crate actix_web;
extern crate serde_json;
#[macro_use]
extern crate serde_derive;

mod lib;

use actix_web::{http, server, App, HttpRequest, HttpResponse, Path, Responder, State};

use lib::{EventSourced, ManagedState};

type AppState = ManagedState<Orderbook>;

#[derive(Serialize, Deserialize, Clone)]
struct Orderbook {
    asks: Vec<Order>,
    bids: Vec<Order>,
}

#[derive(Serialize, Deserialize, Clone)]
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

#[derive(Serialize, Deserialize, Clone)]
enum OrderType {
    Buy,
    Sell,
}

impl EventSourced for Orderbook {
    type Msg = Order;
    fn update(&self, msg: Self::Msg) -> Orderbook {
        // efficiency of this approach relies on cheap clones
        let mut orderbook = self.clone();
        let order = msg;
        match order.order_type {
            OrderType::Buy => orderbook.bids.push(order),
            OrderType::Sell => orderbook.asks.push(order),
        };
        orderbook.normalize();
        orderbook
    }
}

fn index(_info: HttpRequest<AppState>) -> impl Responder {
    format!("Hello")
}

fn orderbook(state: State<AppState>) -> HttpResponse {
    let orderbook = &*state.snapshot();
    HttpResponse::Ok().json(orderbook)
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
    let system = actix::System::new("main");
    let initial_orderbook = Orderbook {
        asks: Vec::new(),
        bids: Vec::new(),
    };
    let initial_state = ManagedState::new(initial_orderbook).unwrap();
    let server_address = "0.0.0.0:8080";
    server::new(move || {
        App::with_state(initial_state.clone())
            .resource("/", |r| r.get().f(index))
            .route("/orderbook", http::Method::GET, orderbook)
            .route("/buy/{user}/{amount}", http::Method::GET, place_bid)
            .route("/sell/{user}/{amount}", http::Method::GET, place_ask)
    }).bind(server_address)
        .unwrap()
        .start();
    println!("Started http server: {}", server_address);
    system.run();
}
