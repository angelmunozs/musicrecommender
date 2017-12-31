class CustomLogger {
  // Log level (1: error, 2: warn, 3: info, 4: debug)
  val level = 3

  // Prompt for numeric parameter via the command line
  def ask(
    paramDescription: String,
    reTypeTitle: Boolean = true
  ): Int = {
    try {
      if(reTypeTitle) {
        println("Enter " + paramDescription + ":")
      }
      scala.io.StdIn.readLine().toInt
    } catch {
      case e: Exception =>
        println("Please, enter a valid " + paramDescription)
        ask(paramDescription, false)
    }
  }

  // Print a horizontal line
  def line(): Unit = {
    println("----------------------------------------------------------------------------------")
  }

  // Print a newline character
  def newLine(): Unit = {
    println("")
  }

  // Log error
  def error(
    msg: String
  ): Unit = {
    if(logLevel >= 1) {
      newLine()
      println("ERROR: " + msg)
    }
  }

  // Log warning
  def warn(
    msg: String
  ): Unit = {
    if(logLevel >= 2) {
      newLine()
      println("WARN: " + msg)
    }
  }

  // Log info
  def info(
    msg: String
  ): Unit = {
    if(logLevel >= 3) {
      newLine()
      println("INFO: " + msg)
    }
  }

  // Log debug
  def debug(
    msg: String
  ): Unit = {
    if(logLevel >= 4) {
      newLine()
      println("DEBUG: " + msg)
    }
  }

}
