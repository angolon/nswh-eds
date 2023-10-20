package angolon.air.etl

import org.apache.spark.sql.{Dataset, SparkSession}
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

  def readVaccinationEpisodes: Dataset[VaccinationEpisode] =
    spark.read
      .option("inferSchema", value = true)
      .option("header", value = true)
      .option("preferDate", value = true)
      .option("dateFormat", value = "yyyy-MM-dd")
      .csv("../resources/FCT_VACCINATION_EPISODE.csv")
      .as[VaccinationEpisode]

  readVaccinationEpisodes.show()
}
