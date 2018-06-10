package models

import play.api.libs.json._

case class UserId(id: Int) extends AnyVal

object UserId {
  implicit val jsonFormat = Json.format[UserId]
}

case class Price(price: Int) extends AnyVal

object Price {
  implicit val jsonFormat = Json.format[Price]
}

sealed trait OrderType

object OrderType {
  case object Buy extends OrderType
  case object Sell extends OrderType

  implicit val jsonFormat: Format[OrderType] = new Format[OrderType] {

    def reads(json: JsValue): JsResult[OrderType] = {
      json match {
        case JsString("buy")  => JsSuccess(Buy)
        case JsString("sell") => JsSuccess(Sell)
        case _                => JsError(Seq())
      }
    }

    def writes(o: OrderType) = o match {
      case Buy  => Json.toJson("buy")
      case Sell => Json.toJson("sell")
    }
  }
}

case class Order(user: UserId, orderType: OrderType, price: Price)

object Order {
  implicit val jsonFormat = Json.format[Order]
}

case class Orderbook(asks: Seq[Order], bids: Seq[Order]) {

  def placeOrder(order: Order): Orderbook = {
    val withNewOrder = order.orderType match {
      case OrderType.Buy =>
        Orderbook(this.asks, (this.bids :+ order).sortBy(_.price.price))
      case OrderType.Sell =>
        Orderbook((this.asks :+ order).sortBy(_.price.price), this.bids)
    }
    withNewOrder.normalize()
  }

  private def normalize(): Orderbook = {
    val MAX_ORDERBOOK_LEN = 100
    if (this.bids.length != 0 && this.asks.length != 0) {
      if (this.bids.last.price.price >= this.asks.head.price.price) {
        val matched = Orderbook(this.asks.tail, this.bids.init)
        return matched.normalize()
      }
    }
    if (this.bids.length > MAX_ORDERBOOK_LEN || this.asks.length > MAX_ORDERBOOK_LEN) {
      Orderbook(this.asks.take(MAX_ORDERBOOK_LEN),
                this.bids.take(MAX_ORDERBOOK_LEN))
    } else {
      this
    }
  }
}

object Orderbook {
  implicit val jsonFormat = Json.format[Orderbook]
  val empty = Orderbook(Seq.empty, Seq.empty)

}
