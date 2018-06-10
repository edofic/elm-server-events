package services

import javax.inject.Singleton

import models.{Order, Orderbook}

@Singleton
class State {
  private[this] var orderbook = Orderbook.empty
  def get = orderbook

  def placeOrder(order: Order): Unit = {
    orderbook = orderbook.placeOrder(order)
  }
}
