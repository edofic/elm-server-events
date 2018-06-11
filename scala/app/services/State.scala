package services

import javax.inject.Singleton

import models.{Order, Orderbook}

@Singleton
class State
    extends ManagedState[Orderbook, Order](
      Orderbook.empty,
      (msg, book) => book.placeOrder(msg)
    )
