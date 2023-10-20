package angolon.air.etl

case class Vaccine(
  vaccine_id: Int,
  vaccine_name: String,
  manufacturer: String
)

object Vaccine {
  // Settings that would come from conf in the real world
  val extractCsvPath = "DM_VACCINE.csv"
  val outputParquetPath = "vaccine.parquet"
}
