package controllers

import javax.inject.{Singleton, Inject}
import play.api._
import play.api.mvc._
import play.api.libs.json.Json

import services.State
import models.{Order, OrderType, UserId, Price}

@Singleton
class HomeController @Inject()(state: State, cc: ControllerComponents)
    extends AbstractController(cc) {

  def index() = Action { implicit request: Request[AnyContent] =>
    Ok(views.html.index())
  }

  def orderbook() = Action {
    Ok(Json.toJson(state.get))
  }

  def placeBuy(userId: Int, price: Int) = Action {
    state.dispatch(Order(UserId(userId), OrderType.Buy, Price(price)))
    Ok("ok")
  }

  def placeSell(userId: Int, price: Int) = Action {
    state.dispatch(Order(UserId(userId), OrderType.Sell, Price(price)))
    Ok("ok")
  }

}
