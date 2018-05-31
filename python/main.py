import json
import collections

from flask import Flask, Response

MAX_ORDERBOOK_LEN = 100

Order = collections.namedtuple('Order', 'userId, orderType, price')


class OrderBook(collections.namedtuple('OrderBook', 'asks, bids')):

    @staticmethod
    def empty():
        return OrderBook((), ())

    def placeOrder(self, userId, orderType, price):
        assert isinstance(userId, int)
        assert orderType in ('buy', 'sell')
        assert isinstance(price, int)
        order = Order(userId, orderType, price)
        asks, bids = list(self.asks), list(self.bids)
        if orderType == 'buy':
            bids.append(order)
            bids.sort(key=lambda bid: bid.price)
            while len(bids) > MAX_ORDERBOOK_LEN:
                bids.pop()
        else:
            asks.append(order)
            asks.sort(key=lambda ask: -ask.price)
            while len(asks) > MAX_ORDERBOOK_LEN:
                bids.pop()

        if bids and asks and bids[-1].price > asks[-1].price:
            bids.pop()
            asks.pop()

        return OrderBook(tuple(asks), tuple(bids))

    def toJSON(self):
        return json.dumps({
            'asks': self.asks,
            'bids': self.bids,
        })


app = Flask(__name__)
app.orderbook = OrderBook.empty()


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
    app.orderbook = app.orderbook.placeOrder(userId, 'buy', price)
    return 'ok'


@app.route('/sell/<int:userId>/<int:price>')
def sell(userId, price):
    app.orderbook = app.orderbook.placeOrder(userId, 'sell', price)
    return 'ok'


if __name__ == '__main__':
    app.run(host='0.0.0.0', port='8080')
