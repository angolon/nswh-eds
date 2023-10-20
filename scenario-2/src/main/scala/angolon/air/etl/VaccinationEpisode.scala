package angolon.air.etl

import java.time.LocalDate

case class VaccinationEpisode(
  vaccination_id: Int,
  person_id: Int,
  vaccine_id: Int,
  vaccination_date: LocalDate,
  site: String,
  provider: String,
  lot_number: String
)
