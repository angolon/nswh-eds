package angolon.air.etl

/** An instance of this trait can be provided implicitly,
  * and provides the relative paths to read input from,
  * and write output to -- for entities of the type T
  */
trait Locatable[T] {
  def extractCsvPath: String
  def outputParquetPath: String
}
