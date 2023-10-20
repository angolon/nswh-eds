import Dependencies._

organization := "angolon"
name := "air-etl"

lazy val root = (project in file("."))
  .settings(
    name := "air-etl",
    scalaVersion := "2.13.12",
    libraryDependencies ++= dependencies
  )
