class CustomLogger {
  // Log level (1: error, 2: warn, 3: info, 4: debug)
  val level = 3

  // Prompt for numeric parameter via the command line
  def askInt(
    paramDescription: String,
    reTypeTitle: Boolean = true
  ): Int = {
    try {
      if(reTypeTitle) {
        print("Enter " + paramDescription + ": ")
      }
      scala.io.StdIn.readInt()
    } catch {
      case e: Exception =>
        print("Please, enter a valid " + paramDescription + ": ")
        askInt(paramDescription, false)
    }
  }

  // Prompt for numeric parameter via the command line
  def askString(
    paramDescription: String,
    reTypeTitle: Boolean = true
  ): String = {
    try {
      if(reTypeTitle) {
        print("Enter " + paramDescription + ": ")
      }
      scala.io.StdIn.readLine()
    } catch {
      case e: Exception =>
        print("Please, enter a valid " + paramDescription + ": ")
        askString(paramDescription, false)
    }
  }

  // Print a horizontal line
  def line(): Unit = {
    println("====================================================================================================")
  }

  // Print a newline character
  def newLine(): Unit = {
    println("")
  }

  // Log error
  def error(
    msg: String
  ): Unit = {
    if(level >= 1) {
      println("ERROR: " + msg)
    }
  }

  // Log warning
  def warn(
    msg: String
  ): Unit = {
    if(level >= 2) {
      println("WARN: " + msg)
    }
  }

  // Log info
  def info(
    msg: String
  ): Unit = {
    if(level >= 3) {
      println("INFO: " + msg)
    }
  }

  // Log debug
  def debug(
    msg: String
  ): Unit = {
    if(level >= 4) {
      println("DEBUG: " + msg)
    }
  }

  // Log results (always)
  def result(
    msg: String
  ): Unit = {
    println("INFO: " + msg)
  }
}
