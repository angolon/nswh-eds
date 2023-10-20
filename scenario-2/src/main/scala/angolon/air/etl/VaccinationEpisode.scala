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

object VaccinationEpisode {
  // Settings that would come from conf in the real world
  implicit val locations: Locatable[VaccinationEpisode] = new Locatable[VaccinationEpisode] {
    val extractCsvPath = "FCT_VACCINATION_EPISODE.csv"
    val outputParquetPath = "vaccinationEpisodes.parquet"
  }
}
