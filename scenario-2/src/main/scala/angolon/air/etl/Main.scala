package angolon.air.etl

import org.apache.spark.sql.{Encoder, Dataset, SaveMode, SparkSession}
import org.apache.spark.SparkConf
import java.nio.file.Path

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

  val extractDir = "../resources"
  val outputDir = "./output"

  def extractPath[T](implicit locations: Locatable[T]): String =
    Path.of(extractDir, locations.extractCsvPath).toString

  def outputPath[T](implicit locations: Locatable[T]): String =
    Path.of(outputDir, locations.outputParquetPath).toString

  def readCsv[T: Encoder : Locatable]: Dataset[T] =
    spark.read
      .option("inferSchema", value = true)
      .option("header", value = true)
      .option("preferDate", value = true)
      .option("dateFormat", value = "yyyy-MM-dd")
      .csv(extractPath[T])
      .as[T]

  def readParquet[T: Encoder : Locatable]: Dataset[T] =
    spark.read
      .parquet(outputPath[T])
      .as[T]

  def etl(): Unit = {
    // Extract data from CSVs -- type based schemas will automatically
    // transform fields from the strings contained in the CSV into their
    // appropriately typed representation (or fail with an error if a field
    // can't be parsed).
    val people: Dataset[Person] = readCsv
    val vaccines: Dataset[Vaccine] = readCsv
    val vaccinationEpisodes: Dataset[VaccinationEpisode] = readCsv
    val vaccinationStatuses: Dataset[VaccinationStatus] = readCsv

    // Save dimensions to parquet files.
    people.write
      .mode(SaveMode.Overwrite)
      .parquet(outputPath[Person])

    vaccines.write
      .mode(SaveMode.Overwrite)
      .parquet(outputPath[Vaccine])

    // Presuming that the real-world vaccination table is very large,
    // we partition the data on disk by the vaccination date.
    // This partitioning could allow for various performance benefits
    // in scenarios where we only wish to analyse the data for a subset
    // of the total time range that it contains -- and various other
    // potential clever tricks that are beyond the scope of this comment
    // block :-).
    // See the API docs for a brief explanation:
    // https://spark.apache.org/docs/latest/api/scala/org/apache/spark/sql/DataFrameWriter.html#partitionBy(colNames:String*):org.apache.spark.sql.DataFrameWriter[T]
    vaccinationEpisodes.write
      .mode(SaveMode.Overwrite)
      .partitionBy("vaccination_date")
      .parquet(outputPath[VaccinationEpisode])

    // Directory-Partition the vaccination status table similarly to
    // vaccination episodes - for the same reasons.
    vaccinationStatuses.write
      .mode(SaveMode.Overwrite)
      .partitionBy("date_given")
      .parquet(outputPath[VaccinationStatus])
  }

  def summarise(): Unit = {
    println("Person summary:")
    readParquet[Person].summary("count", "min", "max").show()

    println("Vaccine summary:")
    readParquet[Vaccine].summary("count", "min", "max").show()

    println("Vaccination Episode summary:")
    readParquet[VaccinationEpisode].summary("count", "min", "max").show()

    println("Vaccination Status summary:")
    readParquet[VaccinationStatus].summary("count", "min", "max").show()
  }

  etl()
  summarise()
}
