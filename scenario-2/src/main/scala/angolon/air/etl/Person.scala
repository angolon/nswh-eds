package angolon.air.etl

import java.time.LocalDate

case class Person(
  person_id: Int,
  first_name: String,
  last_name: String,
  dob: LocalDate,
  gender: String,
  postcode: String,
  phone: String,
  email: String
)

object Person {
  // Settings that would come from conf in the real world
  implicit val locations: Locatable[Person] = new Locatable[Person] {
    val extractCsvPath = "DM_PERSON.csv"
    val outputParquetPath = "person.parquet"
  }
}
