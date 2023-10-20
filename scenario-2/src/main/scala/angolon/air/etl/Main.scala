package angolon.air.etl

import org.apache.spark.sql.{Encoder, Dataset, SaveMode, SparkSession}
import org.apache.spark.SparkConf

object Main extends App {
  val conf: SparkConf = new SparkConf()
    .setAppName("AIR ETL runner")
    // this setting configures spark to run locally for testing this scenario.
    .setMaster("local[*]") 
    .set("spark.sql.shuffle.partitions", "31")

  val spark: SparkSession =
    SparkSession.builder().config(conf).getOrCreate()

  spark.sparkContext.setLogLevel("ERROR")
  import spark.implicits._

  def readCsv[T: Encoder](path: String): Dataset[T] =
    spark.read
      .option("inferSchema", value = true)
      .option("header", value = true)
      .option("preferDate", value = true)
      .option("dateFormat", value = "yyyy-MM-dd")
      .csv(path)
      .as[T]

  def readVaccinationEpisodes: Dataset[VaccinationEpisode] =
    readCsv("../resources/FCT_VACCINATION_EPISODE.csv")

  def readVaccinationStatuses: Dataset[VaccinationStatus] =
    readCsv("../resources/FCT_VACCINE_STATUS.csv")

  def readPeople: Dataset[Person] =
    readCsv("../resources/DM_PERSON.csv")

  def readVaccines: Dataset[Vaccine] =
    readCsv("../resources/DM_VACCINE.csv")

  def etl(): Unit = {
    // Extract data from CSVs -- type based schemas will automatically
    // transform fields from the strings contained in the CSV into their
    // appropriately typed representation (or fail with an error if a field
    // can't be parsed).
    val people = readPeople
    val vaccines = readVaccines
    val vaccinationEpisodes = readVaccinationEpisodes
    val vaccinationStatuses = readVaccinationStatuses

    // Save dimensions to parquet files.
    people.write
      .mode(SaveMode.Overwrite)
      .parquet("./output/people.parquet")
  }

  etl()
}
