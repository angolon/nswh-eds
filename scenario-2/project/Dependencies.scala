import sbt._

object Dependencies {
  val sparkVersion = "3.5.0"
  val sparkCore = "org.apache.spark" %% "spark-core" % sparkVersion
  val sparkSql = "org.apache.spark" %% "spark-sql" % sparkVersion

  val dependencies = Seq(sparkCore, sparkSql)
}
