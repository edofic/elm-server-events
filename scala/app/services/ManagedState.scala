package services

import java.io.{File, BufferedWriter, FileWriter}
import play.api.libs.json.{Json, Format}

class ManagedState[S: Format, M: Format](initial: S, update: (M, S) => S) {

  private[this] var current = replay()
  private[this] var logWriter = new BufferedWriter(
    new FileWriter(new File("log.txt"), true))

  def get = current

  def dispatch(msg: M): Unit = this.synchronized {
    logWriter.write(Json.stringify(Json.toJson(msg)))
    logWriter.write("\n")
    logWriter.flush()
    current = update(msg, current)
  }

  private def replay(): S = {
    val initFile = new File("init.txt")
    val logFile = new File("log.txt")
    if (initFile.exists()) {
      val initialString = scala.io.Source.fromFile("init.txt").getLines().next()
      val initial = Json.parse(initialString).asOpt[S].get
      scala.io.Source
        .fromFile("log.txt")
        .getLines()
        .map(line => Json.parse(line).asOpt[M].get)
        .foldLeft(initial)((s, m) => update(m, s))
    } else {
      val initWriter = new FileWriter(initFile)
      initWriter.write(Json.stringify(Json.toJson(initial)))
      initWriter.flush()
      initWriter.close()
      initial
    }
  }
}
