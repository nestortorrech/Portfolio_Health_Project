--Using Joins to bring together two table comparing Medicare Enrollment and Obesity Rates. Both by State and in 2014.
--Author: Nestor R. Torrech Boneta

--Medicare data set source:
--https://data.world/adamhelsinger/county-state-medicare-spend

--Obesity Rate data set source:
--https://data.world/health/obesity-by-state-2014

--NOTE: Information on the tables not relevant to the project has been omitted.

--Let's start by looking at both our tables

SELECT *
FROM Medicare_2014$

SELECT *
FROM Obesity_2014$

--Let's perform an Inner Join  to see which rows both tables have in common.

SELECT med.State_name, med.Medicare_enrollee_2014, ob.Value AS obesity_percentage
FROM Medicare_2014$ AS med 
	INNER JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location
ORDER BY ob.Value DESC

--Before we analyze further, let's see what got left out
SELECT ob.location, med.State_name, med.Medicare_enrollee_2014, ob.Value AS obesity_percentage
FROM Medicare_2014$ AS med 
	 FULL JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location
WHERE ob.location IS NULL OR med.State_name IS NULL
ORDER BY med.Medicare_enrollee_2014 ASC

--These nulls make sense. Two of the rows are the product of the original data sets having an empty row for aesthetic reasons. These
--are the ones that are null on all fields. Besides that, we see that Guam, Puerto Rico, and National are not included in the Medicare (med)
--table. This is due to them not being states. The first two are American territories and National is just an aggregate category of states.
--The last NULL value to account for is United States, which does not have an obesity_percentage due to it just being an aggregate from the
--medicare dataset

--Now that we've joined both tables, let's see what the average rate of obesity was per state in 2014

SELECT AVG(ob.Value) AS average_obesity
FROM Medicare_2014$ AS med 
	 FULL JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location

--Here we see that the average rate of obesity per state in 2014 was roughly 29.18%. Now let's see what the average medicare enrollment in states
--that were either above or below the mean was

SELECT COUNT(med.Medicare_enrollee_2014) AS medicare_enrollee_count, AVG(med.Medicare_enrollee_2014) AS avg_medicare_enrollee
FROM Medicare_2014$ AS med 
	 FULL JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location
WHERE ob.Value > 29.18
ORDER BY avg_medicare_enrollee, medicare_enrollee_count

--In the 28 States where the Obesity was HIGHER than the mean, there was an average medicare enrollee value of 522,018

SELECT COUNT(med.Medicare_enrollee_2014) AS medicare_enrollee_count, AVG(med.Medicare_enrollee_2014) AS avg_medicare_enrollee
FROM Medicare_2014$ AS med 
	 FULL JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location
WHERE ob.Value < 29.18
ORDER BY avg_medicare_enrollee, medicare_enrollee_count

--In the 23 States where Obesity was LOWER than the mean, there was an average medicare enrollee value of 499,193

--Other factors must be taken into consideration of course. So let's have a closer look at the details of each state that falls on either side of
--the distribution

SELECT med.State_name, med.Medicare_enrollee_2014, ob.Value
FROM Medicare_2014$ AS med 
	 INNER JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location
WHERE ob.Value > 29.18 
ORDER BY med.Medicare_enrollee_2014 DESC
 
 SELECT med.State_name, med.Medicare_enrollee_2014, ob.Value
FROM Medicare_2014$ AS med 
	 INNER JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location
WHERE ob.Value < 29.18
ORDER BY med.Medicare_enrollee_2014 DESC

 --Now, let's analyze by comparing the population of each state in 2014, to the amount of medicare enrollees.
 --To do this, we retrieved an additional dataset from the US census, whose link is the following:
 --https://www.census.gov/data/datasets/2014/demo/saipe/2014-state-and-county.html

 --Let's load up this new data!

 SELECT * 
 FROM state_pop_2014$

 --Alright. Everything seems to be in order. Now let's perform a join with the three prior tables
 --NOTE: Originally we had to format the geo_area column in state_pop_2014 because each geo_area began with a '.'
 --this made it so that, when we tried an inner join with Medicare_2014, I would only get an empty table. So make sure
 --you get rid of that '.' if you're trying to recreate this

 SELECT med.State_name, med.Medicare_enrollee_2014, pop.pop_estimate, ob.Value
FROM Medicare_2014$ AS med 
	 INNER JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location 
	INNER JOIN state_pop_2014$ AS pop
	ON med.State_name = pop.geo_area
ORDER BY med.Medicare_enrollee_2014 DESC

--With this information, we can find out the percentage of people enrolled in medicare per state, thus producing perhaps a more accurate
--analysis long term since it shall account for discrepancies in population

CREATE VIEW Medicare_Percentages_2014 AS
SELECT med.State_name, med.Medicare_enrollee_2014, pop.pop_estimate, ROUND(med.Medicare_enrollee_2014/pop.pop_estimate, 4) AS medicare_percentage,ob.Value
FROM Medicare_2014$ AS med 
	 INNER JOIN Obesity_2014$ AS ob
	ON med.State_name = ob.location 
	INNER JOIN state_pop_2014$ AS pop
	ON med.State_name = pop.geo_area

--Let's create a View from this to make things easier

SELECT * 
FROM Medicare_Percentages_2014

--Let's find the mean medicare_percentage. After this, we'll look at both sides of the distribution just like we did last time

SELECT ROUND(AVG(medicare_percentage),4) AS avg_medicare_percentage
FROM Medicare_Percentages_2014

--The average medicare enrollment percentage per state in 2014 was roughly 9.2%. Let's examine both sides of that distribution to the previous analysis
--we did

--Analysis that factors in population
SELECT State_name, pop_estimate, medicare_percentage, Value 
FROM Medicare_Percentages_2014
WHERE medicare_percentage > 0.092
ORDER BY Value DESC

SELECT ROUND(AVG(Value),2) AS percentage_obese 
FROM Medicare_Percentages_2014
WHERE medicare_percentage > 0.092

--Notice how, when taking into account the population's enrollment in medicare, when this exceeds 9.2%, it results
--in a mean obesity of 30.21%. Which is a full percentage point higher than the Average 29.18 percent we discussed earlier
--if you remember.

--Now let's look at the other side of that distribution.

SELECT State_name, pop_estimate, medicare_percentage, Value 
FROM Medicare_Percentages_2014
WHERE medicare_percentage < 0.092
ORDER BY Value DESC

SELECT ROUND(AVG(Value),2) AS percentage_obese 
FROM Medicare_Percentages_2014
WHERE medicare_percentage < 0.092

--Here we see a different picture. When a medicare_percentage is below 9.2%, this leads to
--a mean obesity of 28.28%. Once again, we find ourselves with almost a 1% change, this a time a decrease,
--in the obesity of the population


--In conclusion, while we can't say for certain the details of the relationship between Medicare and Obesity, this
--little project served to prove that there is a relationship of some sort. We also saw how we could use Joins in SQL
--to bring together three different tables from various datasets and merge them into one table.

--Thank you for reading!















