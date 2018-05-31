import json
import collections

from flask import Flask, Response

MAX_ORDERBOOK_LEN = 100

Order = collections.namedtuple('Order', 'userId, orderType, price')


class OrderBook(object):

    def __init__(self):
        self._bids = []
        self._asks = []

    def placeOrder(self, userId, orderType, price):
        assert isinstance(userId, int)
        assert orderType in ('buy', 'sell')
        assert isinstance(price, int)
        order = Order(userId, orderType, price)
        if orderType == 'buy':
            self._bids.append(order)
            self._bids.sort(key=lambda bid: bid.price)
            while len(self._bids) > MAX_ORDERBOOK_LEN:
                self._bids.pop()
        else:
            self._asks.append(order)
            self._asks.sort(key=lambda ask: -ask.price)
            while len(self._asks) > MAX_ORDERBOOK_LEN:
                self._bids.pop()

        if not (self._bids and self._asks):
            return

        if self._bids[-1].price >= self._asks[-1].price:
            self._bids.pop()
            self._asks.pop()

    def toJSON(self):
        return json.dumps({
          'asks': self._asks,
          'bids': self._bids,
        })


app = Flask(__name__)
app.orderbook = OrderBook()


@app.route('/')
def hello():
    return "Hello World!"


@app.route('/orderbook')
def orderbook():
    return Response(
        status=200,
        response=app.orderbook.toJSON(),
        mimetype='application/json',
    )


@app.route('/buy/<int:userId>/<int:price>')
def buy(userId, price):
    app.orderbook.placeOrder(userId, 'buy', price)
    return 'ok'


@app.route('/sell/<int:userId>/<int:price>')
def sell(userId, price):
    app.orderbook.placeOrder(userId, 'sell', price)
    return 'ok'


if __name__ == '__main__':
    app.run(host='0.0.0.0', port='8080')
