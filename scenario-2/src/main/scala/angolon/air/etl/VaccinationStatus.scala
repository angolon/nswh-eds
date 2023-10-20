package angolon.air.etl

import java.time.LocalDate

case class VaccinationStatus(
  status_id: Int,
  vaccination_id: Int,
  vaccine_status: String,
  date_given: LocalDate
)

object VaccinationStatus {
  // Settings that would come from conf in the real world
  implicit val locations: Locatable[VaccinationStatus] = new Locatable[VaccinationStatus] {
    val extractCsvPath = "FCT_VACCINE_STATUS.csv"
    val outputParquetPath = "vaccinationStatuses.parquet"
  }
}
