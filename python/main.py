import base64
import collections
import json
import os.path
import pickle

from flask import Flask, Response

MAX_ORDERBOOK_LEN = 100

Order = collections.namedtuple('Order', 'user_id, order_type, price')

PlaceOrder = collections.namedtuple('PlaceOrder', 'order')


class OrderBook(collections.namedtuple('OrderBook', 'asks, bids')):

    @staticmethod
    def empty():
        return OrderBook((), ())

    def place_order(self, order):
        assert isinstance(order.user_id, int)
        assert order.order_type in ('buy', 'sell')
        assert isinstance(order.price, int)
        order = Order(order.user_id, order.order_type, order.price)
        asks, bids = list(self.asks), list(self.bids)
        if order.order_type == 'buy':
            bids.append(order)
            bids.sort(key=lambda bid: bid.price)
            while len(bids) > MAX_ORDERBOOK_LEN:
                bids.pop()
        else:
            asks.append(order)
            asks.sort(key=lambda ask: -ask.price)
            while len(asks) > MAX_ORDERBOOK_LEN:
                bids.pop()

        if bids and asks and bids[-1].price >= asks[-1].price:
            bids.pop()
            asks.pop()

        return OrderBook(tuple(asks), tuple(bids))

    def to_json(self):
        return json.dumps({
            'asks': self.asks,
            'bids': self.bids,
        })


class State(object):

    def __init__(self, initial_state, update_func):
        self._state = initial_state
        self._update_func = update_func
        if os.path.isfile('init.txt'):
            with open('init.txt', 'rb') as init_file:
                self._state = pickle.loads(
                    base64.decodebytes(init_file.read()))
                if os.path.isfile('log.txt'):
                    with open('log.txt', 'rb') as log_file:
                        for line in log_file.readlines():
                            if not line:
                                continue
                            msg = pickle.loads(base64.decodebytes(line))
                            self._state = update_func(msg, self._state)
        else:
            with open('init.txt', 'wb') as init_file:
                init_file.write(base64.b64encode(pickle.dumps(self._state)))
        self._log_file = open('log.txt', 'ab')

    def snapshot(self):
        return self._state

    def dispatch(self, msg):
        self._log_file.write(base64.b64encode(pickle.dumps(msg)))
        self._log_file.write(b'\n')
        self._state = self._update_func(msg, self._state)


def update(msg, state):
    if isinstance(msg, PlaceOrder):
        return state.place_order(msg.order)
    else:
        raise Exception("unknown message: " + str(msg))

app = Flask(__name__)
app.state = State(OrderBook.empty(), update)


@app.route('/')
def hello():
    return "Hello World!"


@app.route('/orderbook')
def orderbook():
    return Response(
        status=200,
        response=app.state.snapshot().to_json(),
        mimetype='application/json',
    )


@app.route('/buy/<int:user_id>/<int:price>')
def buy(user_id, price):
    app.state.dispatch(PlaceOrder(Order(user_id, 'buy', price)))
    return 'ok'


@app.route('/sell/<int:user_id>/<int:price>')
def sell(user_id, price):
    app.state.dispatch(PlaceOrder(Order(user_id, 'sell', price)))
    return 'ok'


if __name__ == '__main__':
    app.run(host='0.0.0.0', port='8080')
