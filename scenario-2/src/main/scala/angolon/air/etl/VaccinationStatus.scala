package angolon.air.etl

import java.time.LocalDate

case class VaccinationStatus(
  status_id: Int,
  vaccination_id: Int,
  vaccine_status: String,
  date_given: LocalDate
)
