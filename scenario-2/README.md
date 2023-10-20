# Australian Immunisation Register (AIR) ETL scenario
## Design
Given the description of the data made available by the AIR, I would opt for a fairly simple ETL
process. Given that the data is maintained by a third party, and provided in a friendly structure
with key fields that can be used to join the tables together as necessary, I would make the
following assumptions about our use cases for the data in this scenario:
 * We're primarily accessing this data for analysis/research/reporting purposes.
 * We're happy to trust the internal consistency of the data with regards to foreign key constraints
   and primary key uniqueness, as this is likely guaranteed by AIR. Obviously in the real world I
   would like to verify this assumption.

As such, my primary concern in the design is the volume of data, and the kinds of analysis we might
run on it.


## Reasoning around technology choice
### Back of the envelope calculations with likely wildly inaccurate estimates
* According to the ABS's population clock, across australia there's one birth every 1m42s.
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
* Blindly assuming that none of the figures I've cited have changed hugely, over time, I'd simply
  multiply the annual number by the number of years that the AIR has been operating to get the total
number of events.
