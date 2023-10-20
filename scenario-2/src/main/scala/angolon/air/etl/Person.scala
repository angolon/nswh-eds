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
