# Scenario 2: Australian Immunisation Register (AIR) ETL
## 1. Design and Tooling
Given the description of the data made available by the AIR, I would opt for a fairly simple ETL
process. Given that the data is maintained by a third party, and provided in a friendly structure
with key fields that can be used to join the tables together as necessary, I would make the
following assumptions about our use cases for the data in this scenario:
 * We're primarily accessing this data for analysis/research/reporting purposes.
 * We're happy to trust the internal consistency of the data with regards to foreign key constraints
   and primary key uniqueness, as this is likely guaranteed by AIR. Obviously in the real world I
   would like to verify this assumption.

As such, my primary concern in the design is the volume of data, and the kinds of analysis we might
run on it. In the addendum section below I have a very 'stream-of-consciousness' attempt to estimate
the average number of vaccination episodes per day that would be added to the register, the result
of which is ~25,700/day. Whilst this is a relatively small number individually, for a single year
the estimate sums to ~9,400,000 records. Again, this is a very manageable volume of data for a
traditional RDBMS system. However if I blindly assume that my population and vaccination rate
estimates don't change significantly year-to-year, then multiplying the yearly total by several
years causes this estimate to grow quite quickly. For example, the AIR was extended to a
whole-of-life register in 2016, and that 7 years of data would amount to 65,800,000 vaccine episode
records. Extending this estimate over the prior years of data collection for the Australian
Children's Immunisation Register could easily see us dealing with hundreds of millions of records.

### Tool Choice: Apache Spark
Although I'd usually consider myself to be rather conservative when deciding to use Spark, dealing
with an order of magnitude in the hundreds of millions surpasses my personal rule of thumb, and so
I've elected to design and build using it. As spark is a distributed computing/data processing
engine, it should be able to easily handle analysing data of this volume.

### Design Summary
The ETL design is quite simple, as I believe that for analysis purposes, the main concern is likely
`FCT_VACCINATION_EPISODE`, and that the other tables don't need to be immediately joined to it:
 * `DM_PERSON` and `DM_VACCINE` can be treated like lookups, and joined to a query result after the
   query has produced a smaller dataset from `FCT_VACCINATION_EPISODE`. `vaccine_id` and `person_id`
should be sufficient to operate off of prior to any join operations.
 * `FCT_VACCINATION_STATUS` could be a complicating factor if it has the same cardinality as
   `FCT_VACCINATION_EPISODE`. However from the sample data, the only additional field it provides is
`vaccine_status`, which are all equal to `Completed` -- without more information I've assumed that I
should import the table for posterity, but it has little-to-no actual value.

With those caveats/assumptions, the ETL process is:
 * Read and parse all CSVs into spark datasets of the correct type.
 * Write `DM_PERSON` and `DM_VACCINE` directly into parquet files for later use.
 * Partition `FCT_VACCINE_STATUS` and `FCT_VACCINATION_EPISODE` by their date columns, to allow for
   performant date-range filtering of any queries that might be run against these tables. Then write
them both to parquet files.

### Potential Constraints and Limitations
* Spark doesn't provide any constraint or referential integrity enforcement out-of-the box. As I
  discussed in the rationale section, I've decided to trust the input as is provided from AIR.
* Although performant, Spark is not the most user-friendly software, and analysis and reporting over
  the loaded data may be difficult for non-technical users.
* In selecting any distributed tool, the cost of either on-prem hardware, or cloud resources, needs to
  be carefully considered, as they can be prohibitive.
  - With that said, due to being open source, Spark's cost would likely be lower than managed
    commercial offerings, such as Snowflake or BigTable. Of course this comes with the downside of
little to no 3rd party support.
* The sample code contained in the repository doesn't take full advantage of the date-based
  partitioning - it simply overwrites the full dataset each time it is run. Given that the AIR's
  dataset is updated daily, it might be possible to load delta sets each day into a new date
  partition. Compared to running a full load every day, this would be significantly quicker and less
  costly.

## 2. Code
The main entry point to the application is in [Main.scala](src/main/scala/angolon/air/etl/Main.scala).

### Building and Running
Despite my best efforts, I was unable to build a development environment on my local machine with
nix, so to build and run this code you will need to have the following installed on your system:
 * [sbt v1.9.6](https://www.scala-sbt.org/)
 * JDK v17 (I've only tested against OpenJDK).

With those tools installed, with `scenario-2` as your working directory:
```bash
sbt compile # builds the project
sbt run # runs the etl pipeline against the test data in the repository.
ls -l output # Top level directory containing the output assets.
```

#### Caveat
The original CSV files had every line wrapped in quotes. Spark was unable to parse the data in this
format, and so I had to manually unquote the data. Scala isn't the best tool for manipulating text
data, and so I didn't add a pre-processing step as I did in scenario 1. With this ETL step embedded
in a real-world workflow/scheduling engine, I would pre-process the data with a tool such as `sed`.
Alternatively, I'd investigate the possibility of getting the AIRs dataset to conform to [RFC
4180: Common Format and MIME Type for Comma-Separated Values (CSV)
Files](https://datatracker.ietf.org/doc/html/rfc4180), which allows for quoting of individual
fields, but not whole records.

## 3. What steps would you take to validate the results of your code?
As-is, the code runs successfully against the provided sample data, and prints out some basic
statistical summaries of each table. To validate these results further, against more realistic data,
we could:
 * Manually implement constraint and referential integrity checks on top of spark. In the past I've
   worked on projects where we developed generic utilities to handle this enforcement/validation
  when provided with metadata representing the expected constraint checks.
 * Compare the row-counts against the file inputs. Ignoring potential size issues, a simple record
   count of the input could be confirmed using shell utilities, i.e. `wc -l
FCT_VACCINATION_EPISODE.csv`. After accounting for the header row, it should be relatively simple to
   automate this comparison for validating the ETL process after completion.
 * Run more sophisticated checks against the input and output data. If AIRs provided an API for
   accessing more granular statistics over the source data, that could be compared against
equivalent computations performed against the transformed data - e.g. comparing distinct counts of
each column.
   - If no such API exists, this could still potentially be performed with shell utilities (again
     modulo size constraints). For example, to compute the expected distinct number of `site` values
in `FCT_VACCINATION_EPISODE` from the raw csv data:
     ```bash
     tail -n+2 FCT_VACCINATION_EPISODE.csv | cut -d, -f5 | sort | uniq | wc -l
     ```
 * If I were extremely paranoid about the possibility of inconsistencies between the raw and
   transformed data, I might opt to re-export the transformed data as a CSV. By carefully matching
   the column order and record order in the source and re-exported data, we could produce two files
   which *should* be identical. From there we could simply compute a checksum over them both.

## Addendum: back of the envelope calculations with likely wildly inaccurate estimates
(Please don't feel obligated to read this)
* According to the ABS's population clock, across Australia there's one birth every 1m42s.
  - https://www.abs.gov.au/statistics/people/population/population-clock-pyramid
* The National Immunisation Program Schedule contains Hep B immunisation at birth, so
  this means approximately 847 vaccination events per day on newborns alone.
* Again, according to the population clock, the projection for 2023 is 307279 all up.
* From the Australian Institute of Health and Welfare, the indigenous population is ~3.8%
* Ignoring vaccines prescribed for children with specific medical risk conditions,
  there are 11 additional vaccines for non-indigenous children in the first year of life,
  and an additional 4 vaccines on top for indigenous children (ignoring statewide differences,
  which probably skews the results in strange ways due to NSW and VIC not being included in
  state specific lists)
* So annually, 0.962 * 307279 * 11 = 3251626.378 vaccination events for non-indigenous,
  and 0.038 * 307279 * 15 = 175149.03 events for indigenous infants - total 3426775.408.
* Daily for 2023, this would average ~9388.43 events.
* Similar reasoning for vaccine schedule at 18months:
  - 146400f 154356m = 300756.
  - 0.962 * 300756 * 3 = 867981.816, 0.038 * 300756 * 4 = 45714.912, total: 913696.728
  - daily average: ~2503.28
* Again for 4yo vaccinations:
  - population 306755
  - non-indigenous: 0.962 * 306755 (1 vaccine only) = 295098.31
  - indigenous: 0.038 * 306755 * 3 = 34970.07
  - total: 330068.38
  - daily average: ~904.30
* Year 7 (12-13yo) vaccinations (I've just taken the 13yo's, because of school enrolment
  weirdness).
  - population 329922
  - 2 vaccines for all children
  - total: 659844
  - daily average: ~1807.79
* Year 10 (14-16yo) vaccinations (again, only taking 16yo's)
  - population 318271, one vaccine each.
  - daily average: ~871.98
* Flatten adults to only those aged >= 65, and include annual influenza vaccine for those.
  - population 4487008,
  - daily average: ~12293.17
* Pregnancies: not accounting for pregnancy loss, or multiple pregnancy, I'll 
  assume the same number of individuals as the birth clock, multiplied by the two vaccines,
  so 1694 per day.
* So, very approximately, we're looking at 30,309.95 vaccination events per day.
* I can't easily find much good data on vaccine refusal/hesitancy. A few sources lead me to think I
  should peg it at around 15%, so let's reduce the daily average event number to 25763.4575
* Annually, 9403661.988 events.
