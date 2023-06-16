CREATE DATABASE CovidCaseAnalysis;
USE CovidCaseAnalysis;
SELECT * FROM dbo.covid_deaths;
SELECT * FROM dbo.covid_vaccinations;

------Global Covid19 Stats------

----Confirmed Cases and Deaths in the World----
-- Crude Mortality Rate is a mortality risk measure, calculating the share among entire population that 
-- have died from COVID-19. Whereas, Case Mortality Rate measures the risk of death for a person diagnosed with COVID-19

WITH cases_and_deaths_record AS
(SELECT population, SUM(new_cases) as confirmed_cases, SUM(new_deaths) as confirmed_deaths
from dbo.covid_deaths
where location = 'World'
group by location, population)
SELECT FORMAT(confirmed_cases, 'N0') as confirmed_cases, CONCAT(ROUND((CAST(confirmed_cases as float)/population)*100, 2),'%') as populationInfected, FORMAT(confirmed_deaths,'N0') AS confirmed_deaths, 
CONCAT(ROUND((CAST(confirmed_deaths AS float)/population)*100, 2),'%') as crudeMortalityRate, CONCAT(ROUND((CAST(confirmed_deaths AS float)/confirmed_cases)*100,2),'%') as caseFatalityRate
from cases_and_deaths_record;

----Vaccine Doses Administered in the World----

WITH vaccination_record as 
(SELECT population,  MAX(total_vaccinations) as total_vaccine_doses_administered, MAX(people_vaccinated) as one_dose_vaccinated_persons, MAX(people_fully_vaccinated) as persons_fully_vaccinated, MAX(total_boosters) as boosters_administered
from dbo.covid_deaths cd join dbo.covid_vaccinations cv on cd.location = cv.location and cd.date=cv.date
where cd.location='World'
group by cd.location, population)
SELECT FORMAT(total_vaccine_doses_administered, 'N0') as total_vaccine_doses_administered, FORMAT(one_dose_vaccinated_persons, 'N0') as one_dose_vaccinated_persons, CONCAT(ROUND((CAST(one_dose_vaccinated_persons as float)/population)*100, 2), '%') as populationVaccinated, FORMAT(persons_fully_vaccinated, 'N0') as persons_fully_vaccinated,
CONCAT(ROUND((CAST(persons_fully_vaccinated as float)/population)*100, 2),'%') as populationFullyVaccinated, FORMAT(boosters_administered, 'N0') as additionalDosesAdministered
from vaccination_record;

WITH daily_cases_record as (SELECT date, SUM(new_cases) as confirmed_cases, LAG(SUM(new_cases),1, 0) OVER (ORDER BY DATE) as previous_day_confirmed_cases, SUM(new_cases) - LAG(SUM(new_cases),1, 0) OVER (ORDER BY DATE) AS daily_change
from dbo.covid_deaths
where location='World'
group by date)
SELECT date, confirmed_cases, daily_change, (CASE WHEN previous_day_confirmed_cases=0 AND confirmed_cases=0 THEN 0 WHEN previous_day_confirmed_cases=0 THEN ROUND((daily_change/CAST(confirmed_cases AS FLOAT))*100,2) ELSE ROUND((daily_change/CAST(previous_day_confirmed_cases AS FLOAT))*100,2) END) AS daily_change_perc
from daily_cases_record 
order by date;

WITH daily_deaths_record as (SELECT date, SUM(new_deaths) as confirmed_deaths, LAG(SUM(new_deaths),1, 0) OVER (ORDER BY DATE) as previous_day_confirmed_deaths, SUM(new_deaths) - LAG(SUM(new_deaths),1, 0) OVER (ORDER BY DATE) AS daily_change
from dbo.covid_deaths
where location='World'
group by date)
SELECT date, confirmed_deaths, daily_change, (CASE WHEN previous_day_confirmed_deaths=0 AND confirmed_deaths=0 THEN 0 WHEN previous_day_confirmed_deaths=0 THEN ROUND((daily_change/CAST(confirmed_deaths AS FLOAT))*100,2) ELSE ROUND((daily_change/CAST(previous_day_confirmed_deaths AS FLOAT))*100,2) END) AS daily_change_perc
from daily_deaths_record
order by date;

------Continent/Region Covid19 Stats------

----Confirmed Cases and Deaths Per Continent----

SELECT continent, FORMAT(SUM(new_cases), 'N0') as confirmed_cases, FORMAT(SUM(new_deaths), 'N0') as confirmed_deaths
from dbo.covid_deaths
where continent is not null
group by continent
order by SUM(new_cases) desc

----Vaccination Doses Administered Per Continent----

SELECT continent, FORMAT(MAX(total_vaccinations), 'N0') as total_vaccine_doses_administered, 
FORMAT(MAX(people_vaccinated),'N0') as one_dose_vaccinated_persons, FORMAT(MAX(people_fully_vaccinated),'N0') as persons_fully_vaccinated, 
FORMAT(MAX(total_boosters),'N0') as boosters_administered
from dbo.covid_vaccinations
where continent is not null
group by continent
order by MAX(total_vaccinations) desc

WITH daily_cases_record as (SELECT continent, date, SUM(new_cases) as confirmed_cases, LAG(SUM(new_cases),1, 0) OVER (partition by continent ORDER BY DATE) as previous_day_confirmed_cases, SUM(new_cases) - LAG(SUM(new_cases),1, 0) OVER (partition by continent ORDER BY DATE) AS daily_change
from dbo.covid_deaths
where continent is not null
group by continent, date)
SELECT continent, date, confirmed_cases, daily_change, (CASE WHEN previous_day_confirmed_cases=0 AND confirmed_cases=0 THEN 0 WHEN previous_day_confirmed_cases=0 THEN ROUND((daily_change/CAST(confirmed_cases AS FLOAT))*100,2) ELSE ROUND((daily_change/CAST(previous_day_confirmed_cases AS FLOAT))*100,2) END) AS daily_change_perc
from daily_cases_record 
order by continent, date;

WITH daily_deaths_record as (SELECT continent, date, SUM(new_deaths) as confirmed_deaths, LAG(SUM(new_deaths),1, 0) OVER (PARTITION BY continent ORDER BY DATE) as previous_day_confirmed_deaths, SUM(new_deaths) - LAG(SUM(new_deaths),1, 0) OVER (PARTITION BY continent ORDER BY DATE) AS daily_change
from dbo.covid_deaths
where continent is not null
group by continent, date)
SELECT continent, date, confirmed_deaths, daily_change, (CASE WHEN previous_day_confirmed_deaths=0 AND confirmed_deaths=0 THEN 0 WHEN previous_day_confirmed_deaths=0 THEN ROUND((daily_change/CAST(confirmed_deaths AS FLOAT))*100,2) ELSE ROUND((daily_change/CAST(previous_day_confirmed_deaths AS FLOAT))*100,2) END) AS daily_change_perc
from daily_deaths_record
order by continent, date;

------Covid19 Stats By Country------

----Finding top 10 countries with highest risk of death if diagnosed with covid (Measured by Case Fatality Rate)----

WITH cases_and_deaths_record AS
(SELECT location, population, SUM(new_cases) as confirmed_cases, SUM(new_deaths) as confirmed_deaths
from dbo.covid_deaths
where continent is not null
group by location, population)
SELECT TOP 10 location, FORMAT(confirmed_cases, 'N0') as confirmed_cases, CONCAT(ROUND((CAST(confirmed_cases as float)/population)*100, 2),'%') as populationInfected, FORMAT(confirmed_deaths,'N0') AS confirmed_deaths, 
CONCAT(ROUND((CAST(confirmed_deaths AS float)/population)*100, 2),'%') as crudeMortalityRate, CONCAT(ROUND((CAST(confirmed_deaths AS float)/confirmed_cases)*100,2),'%') as caseFatalityRate
from cases_and_deaths_record
where confirmed_cases IS NOT NULL AND confirmed_deaths IS NOT NULL and confirmed_cases != 0 AND confirmed_deaths != 0
order by caseFatalityRate desc, crudeMortalityRate desc;

----Finding top 10 countries with highest death case or simply put, countries with highest confirmed deaths registered----

WITH death_rate_record AS
(SELECT location, population, SUM(new_cases) as non_formatted_confirmed_cases, SUM(new_deaths) as non_formatted_confirmed_deaths
from dbo.covid_deaths
where continent is not null
group by location, population)
SELECT TOP 10 location, FORMAT(non_formatted_confirmed_cases, 'N0') as confirmed_cases, CONCAT(ROUND((CAST(non_formatted_confirmed_cases as float)/population)*100, 2),'%') as populationInfected, FORMAT(non_formatted_confirmed_deaths,'N0') AS confirmed_deaths, 
CONCAT(ROUND((CAST(non_formatted_confirmed_deaths AS float)/population)*100, 2),'%') as crudeMortalityRate, CONCAT(ROUND((CAST(non_formatted_confirmed_deaths AS float)/non_formatted_confirmed_cases)*100,2),'%') as caseFatalityRate
from death_rate_record
where non_formatted_confirmed_cases IS NOT NULL AND non_formatted_confirmed_deaths IS NOT NULL and non_formatted_confirmed_cases != 0 AND non_formatted_confirmed_deaths != 0
order by non_formatted_confirmed_deaths desc;

----Tracking Vaccination doses administered around the world including percent of population receiving at least one dose, percent of population fully vaccinated and additional doses or booster doses administered----
WITH vaccination_record as 
(SELECT cd.location, (MAX(CAST(people_vaccinated AS float))/population)*100 as populationVaccinated, (MAX(CAST(people_fully_vaccinated AS float))/population)*100 as populationFullyVaccinated, ISNULL(MAX(total_boosters),0) as additionalDosesTotal, ISNULL(MAX(total_boosters_per_hundred),0) as additionalDosesPer100People
from dbo.covid_deaths cd join dbo.covid_vaccinations cv on cd.date = cv.date and cd.location = cv.location
where cd.continent is not null
group by cd.location, population)
SELECT location, (CASE WHEN populationVaccinated >= 100 THEN CONCAT('>',99, '%') WHEN populationVaccinated < 10 THEN CONCAT(ROUND(populationVaccinated,1), '%') ELSE CONCAT(ROUND(populationVaccinated,0), '%') END ) AS populationVaccinatedPercent,
(CASE WHEN populationFullyVaccinated >= 100 THEN CONCAT('>',99, '%') WHEN populationFullyVaccinated < 10 THEN CONCAT(ROUND(populationFullyVaccinated,1), '%')ELSE CONCAT(ROUND(populationFullyVaccinated,0), '%') END ) AS populationFullyVaccinatedPercent,
additionalDosesTotal, additionalDosesPer100People
from vaccination_record
where populationVaccinated is not null and populationFullyVaccinated is not null
order by populationVaccinated desc, populationFullyVaccinated desc;

----Analyzing if there is a slight correlation between gdp per capita of countries and the percent of population vaccinated against COVID-19 in countries with lower GDP----
SELECT location, gdp_per_capita, ISNULL(extreme_poverty, 0) as extreme_poverty
FROM dbo.covid_vaccinations
where continent is not null and gdp_per_capita is not null
GROUP by location, gdp_per_capita, extreme_poverty
order by gdp_per_capita;

--Analysing the lower records of vaccination_record CTE and the results of the query above, we can gather than there is disparity in the percent of population vaccinated against COVID-19
--in lower GDP countries with more poverty and countries with higher GDP. Countries with lower GDP might not have an organized system and resources to vaccinate its population.

----Creating a view with records of average deaths, icu patients and hospital patients per day of various countries----
CREATE VIEW icu_hospital_patient_record AS
Select location, AVG(new_deaths) AS avg_deaths, AVG(hosp_patients) AS avg_hospital_patients, AVG(icu_patients) AS avg_icu_patients
from dbo.covid_deaths
where continent is not null and icu_patients is not null and hosp_patients is not null
GROUP BY location
HAVING AVG(new_deaths) is not null

----Getting top 20 countries with highest median age indicating countries whose population on more on the older side and having more adults aged 65 or 70 over----
SELECT TOP 20 location, median_age, aged_65_older, aged_70_older
from dbo.covid_vaccinations
where continent is not null and location IN (SELECT location 
from dbo.icu_hospital_patient_record)
group by location, median_age, aged_65_older, aged_70_older
order by median_age desc;

----Getting top 20 countries with highest avg deaths recorded on a daily basis----
SELECT TOP 20 * FROM dbo.icu_hospital_patient_record
order by avg_deaths desc, avg_icu_patients desc;

--From the results of the above two queries we can gather that avg deaths with more icu patients registered in the hospital are usually countries having a higher median age with more middle age and older adults than young adults.
--The old generation may contribute to higher death toll and icu admissions due to preexisting health conditions and lower immunity levels attributed to their old age.


----UAE & India Covid19 Stats----

----Confirmed Cases, Deaths and Vaccination Doses Administered in the UAE and India----
SELECT cd.location, FORMAT(SUM(cd.new_cases),'N0') as diagnosed_cases, FORMAT(SUM(cd.new_deaths),'N0') as confirmed_deaths, FORMAT(MAX(cv.total_tests),'N0') as tests_conducted, FORMAT(MAX(cv.total_vaccinations),'N0') as total_vaccine_doses,
FORMAT(MAX(people_vaccinated),'N0') as one_dose_vaccinated_persons, FORMAT(MAX(people_fully_vaccinated),'N0') as persons_fully_vaccinated, 
FORMAT(MAX(total_boosters),'N0') as boosters_administered
from dbo.covid_deaths cd join dbo.covid_vaccinations cv on cd.location = cv.location and cd.date = cv.date
where cd.location IN ('United Arab Emirates','India') and cd.continent is not null
group by cd.location;

----7 Day Moving Average of New Cases Diagnosed with Covid in India & UAE from Jan 2020 to March 2023----
SELECT cd.location, cd.date, AVG(cd.new_cases) OVER (PARTITION BY cd.location ORDER BY cd.date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as confirmed_cases_7_day_rolling_average
from dbo.covid_deaths cd join dbo.covid_vaccinations cv 
on cd.location = cv.location and cd.date = cv.date
where cd.location IN ('United Arab Emirates','India')
and cd.continent is not null
ORDER BY cd.location, cd.date;

----7 Day Moving Average of New Deaths Occurring due to Covid in India & UAE from Jan 2020 to March 2023----
SELECT cd.location, cd.date, AVG(cd.new_deaths) OVER (PARTITION BY cd.location ORDER BY cd.date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as confirmed_deaths_7_day_rolling_average
from dbo.covid_deaths cd join dbo.covid_vaccinations cv 
on cd.location = cv.location and cd.date = cv.date
where cd.location IN ('United Arab Emirates','India')
and cd.continent is not null
ORDER BY cd.location, cd.date;

----Case Fatality Rate of COVID over the course of time between Jan 2020 to March 2023 in India & UAE----
SELECT cd.location, cd.date, ISNULL(ROUND((cd.total_deaths/CAST(cd.total_cases AS FLOAT))*100, 2), 0) AS caseFatalityRate
from dbo.covid_deaths cd join dbo.covid_vaccinations cv 
on cd.location = cv.location and cd.date = cv.date
where cd.location IN ('United Arab Emirates','India')
and cd.continent is not null
ORDER BY cd.location, cd.date;