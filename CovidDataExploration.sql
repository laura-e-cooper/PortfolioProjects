-- Ensuring tables imported correctly
SELECT *
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
ORDER BY 3, 4
LIMIT 1000;

SELECT *
FROM `lofty-fort-277614.covid_portfolio_project.covid_vaccinations`
ORDER BY 3, 4
LIMIT 1000;

--Initial Exploration of needed data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
ORDER BY 1, 2;

--Identifying location data that are not countries
SELECT DISTINCT location
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NULL; 

--Looking at Total Cases vs. Total Deaths
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths / total_cases)*100,4) AS death_pct
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--Death Pct by Country
SELECT location, total_cases, total_deaths, ROUND((total_deaths / total_cases)*100,4) AS death_pct
FROM (
  SELECT location, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths
  FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
  WHERE continent IS NOT NULL
  GROUP BY location)
ORDER BY death_pct DESC;

--Death Pct by Country by Month
SELECT location, month, total_cases, total_deaths, ROUND((total_deaths / total_cases)*100,4) AS death_pct
FROM (
  SELECT location, DATE_TRUNC(date, month) AS month, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths
  FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
  WHERE continent IS NOT NULL
  GROUP BY location, month)
ORDER BY 1, 2 DESC;

--Death Pct in the US by Month
SELECT location, month, total_cases, total_deaths, ROUND((total_deaths / total_cases)*100,4) AS death_pct
FROM (
  SELECT location, DATE_TRUNC(date, month) AS month, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths
  FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
  GROUP BY location, month
  HAVING location LIKE '%States')
ORDER BY 1, 2 DESC;

--Total Cases vs. Population in US by day
SELECT location, date, population, total_cases, ROUND((total_cases / population)*100,4) AS infection_rate
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE location LIKE '%States'
ORDER BY 1, 2;

--On what date had more than 5% of the US population contracted Covid?
SELECT location, date, population, total_cases, ROUND((total_cases / population)*100,4) AS infection_rate
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE location LIKE '%States'
AND ROUND((total_cases / population)*100,4) >= 5
ORDER BY 1, 2
LIMIT 1;

--Which countries have the highest infection rates?
SELECT location, population, MAX(total_cases) AS max_case_count, ROUND((MAX(total_cases) / population)*100,4) AS infection_rate
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1, 2
ORDER BY 4 DESC;

--Which countries have the highest death count?
SELECT location, MAX(total_deaths) AS total_death_count
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

--Which countries have the highest death count compared to population?
SELECT location, population, MAX(total_deaths) AS total_death_count, ROUND((MAX(total_deaths) / population)*100,4) AS death_rate_pop
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1, 2
ORDER BY 4 DESC;

--Which countries have the highest death count compared to case count?
SELECT location, MAX(total_cases) AS total_case_count, MAX(total_deaths) AS total_death_count, ROUND((MAX(total_deaths) / MAX(total_cases))*100,4) AS death_rate_cases
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY 4 DESC;

--BREAKING THINGS DOWN BY CONTINENT
--Which continents have the highest infection rates?
WITH t1 AS (
SELECT DISTINCT continent, location, (MAX(population)) AS population, MAX(total_cases) AS total_cases  
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1, 2
),

t2 AS (
SELECT continent, SUM(population) as cont_population, SUM(total_cases) AS cont_total_cases
FROM t1
GROUP BY 1
)

SELECT t2.continent, cont_population, cont_total_cases, ROUND((MAX(cont_total_cases) / cont_population)*100,4) AS infection_rate
FROM t1, t2
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

--Which continents have the highest death count?
WITH t1 AS (
SELECT DISTINCT continent, location, MAX(total_deaths) AS death_count 
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1, 2
)

SELECT continent, SUM(death_count) AS cont_death_count
FROM t1
GROUP BY 1
ORDER BY 2 DESC;

--Which continents have the highest death count compared to population?
WITH t1 AS (
SELECT DISTINCT continent, location, (MAX(population)) AS population, MAX(total_deaths) AS death_count 
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1, 2
),

t2 AS (
SELECT continent, SUM(population) as cont_population, SUM(death_count) AS cont_death_count
FROM t1
GROUP BY 1
)

SELECT t2.continent, cont_population, cont_death_count, ROUND((MAX(cont_death_count) / cont_population)*100,4) AS death_rate
FROM t1, t2
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

--Which continent has the highest death count compared to case count?
SELECT continent, MAX(total_cases) AS total_case_count, MAX(total_deaths) AS total_death_count, ROUND((MAX(total_deaths) / MAX(total_cases))*100,4) AS death_rate_cases
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY 4 DESC;

--LET'S CALCULATE SOME GLOBAL NUMBERS
-- What's the global infection rate? 
WITH t1 AS (
  SELECT SUM(population) AS global_population
  FROM (SELECT DISTINCT location, population
    FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
    WHERE continent IS NOT NULL)
)

SELECT global_population, SUM(new_cases) AS global_case_count, ROUND(SUM(new_cases) / global_population * 100, 4) AS global_infection_rate
FROM t1, `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1;

--What's the global death count per population? - percent of people who have died from Covid
WITH t1 AS (
  SELECT SUM(population) AS global_population
  FROM (SELECT DISTINCT location, population
    FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
    WHERE continent IS NOT NULL)
)

SELECT global_population, SUM(new_deaths) AS global_death_count, ROUND(SUM(new_deaths) / global_population *100, 4) AS global_death_rate_pop
FROM t1,`lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY 1;

--What's the global death count per case count? - chance of dying if you contract Covid
SELECT SUM(new_cases) AS global_case_count, SUM(new_deaths) AS global_death_count,
  ROUND(SUM(new_deaths) / SUM(new_cases)*100, 4) AS global_death_rate_cases
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths`
WHERE continent IS NOT NULL;

--Join covid deaths & covid vaccination table and select data needed 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths` AS dea
JOIN `lofty-fort-277614.covid_portfolio_project.covid_vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

--Add column of rolling total of people vaccinated per country per day
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths` AS dea
JOIN `lofty-fort-277614.covid_portfolio_project.covid_vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

--Add column with rolling country vaccination rate using CTE
WITH t1 AS (
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
  FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths` AS dea
  JOIN `lofty-fort-277614.covid_portfolio_project.covid_vaccinations` AS vac
   ON dea.location = vac.location
   AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  )

SELECT *, ROUND((rolling_people_vaccinated / population)*100, 4) AS rolling_vacc_rate
FROM t1;

--Find total people vaccinated and vaccination rate by country
WITH t1 AS (
  SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location) AS rolling_people_vaccinated
  FROM `lofty-fort-277614.covid_portfolio_project.covid_deaths` AS dea
  JOIN `lofty-fort-277614.covid_portfolio_project.covid_vaccinations` AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  )

SELECT location, MAX(rolling_people_vaccinated) AS total_people_vaccinated, ROUND((MAX(rolling_people_vaccinated) / MAX(population))*100, 4) AS vaccination_rate
FROM t1
GROUP BY 1;

-- that's all, folks!