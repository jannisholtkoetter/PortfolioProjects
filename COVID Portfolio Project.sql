Select *
From PortfolioProject..CovidDeaths
order by 3,4


Select *
From PortfolioProject..CovidVaccs
order by 3,4

--Select specific data:
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Cases vs Total Deaths
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%Monaco%'
order by 1,2

-- Cases vs Population
Select location, date, population, total_cases, ROUND((total_cases/population)*100, 2) as PopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%Portugal%' OR location like '%Germany%'
order by 1,2

-- Countries with Highest Infection Rate / Population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PopulationInfected
From PortfolioProject..CovidDeaths
Group by location, population
order by PopulationInfected desc

--Countries with Highest Death Count
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc

--Continent with Highest Death Count
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc


--Calculate the population per continent
SELECT continent, SUM(population) AS TotalPopulation
FROM
(	
	SELECT location, continent, population
	, rn=ROW_NUMBER() OVER (PARTITION BY location ORDER BY location)
	FROM PortfolioProject.dbo.CovidDeaths
) q
WHERE rn = 1 AND continent IS NOT NULL
GROUP BY continent


--Global Numbers:
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS bigint)) AS total_deaths, SUM(cast(new_deaths AS bigint))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 




-- Vaccinations JOIN with Deaths
--		Total population vs vaccinations
-- (has to be partitioned by location and also ordered by date to be cumulative)
-- WITH ... AS -> CTE common table expression)
WITH vaccs_per_pop (Continent, Location, Date, Population, New_vaccinations, Cumulative_vaccinations)
AS
(
SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dth.location ORDER BY dth.location, CONVERT(date,dth.date)) AS cumulative_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dth
JOIN PortfolioProject.dbo.CovidVaccs vac
	ON dth.location = vac.location
	AND dth.date = vac.date
WHERE dth.continent IS NOT NULL AND dth.continent LIKE '%Europe%'
)
--Solution with CTE to caclulate vaccinations per population
SELECT *,(Cumulative_vaccinations/Population)*100 AS vaccs_percentage
FROM vaccs_per_pop



--Solution with temporary table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Cumulative_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dth.location ORDER BY dth.location, CONVERT(date,dth.date)) AS cumulative_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dth
JOIN PortfolioProject.dbo.CovidVaccs vac
	ON dth.location = vac.location
	AND dth.date = vac.date
WHERE dth.continent IS NOT NULL AND dth.continent LIKE '%Europe%'

SELECT *,(Cumulative_vaccinations/Population)*100 AS vaccs_percentage
FROM #PercentPopulationVaccinated





--Create Views to store data for later visualization

--View: 
CREATE VIEW PercentPopulationVaccinated AS
SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dth.location ORDER BY dth.location, CONVERT(date,dth.date)) AS cumulative_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dth
JOIN PortfolioProject.dbo.CovidVaccs vac
	ON dth.location = vac.location
	AND dth.date = vac.date
WHERE dth.continent IS NOT NULL AND dth.continent LIKE '%Europe%'
--ORDER BY 2,3


-- VIEW: Cases vs Population
CREATE VIEW CasesPerPopulation AS
Select location, date, population, total_cases, ROUND((total_cases/population)*100, 2) as PopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%Portugal%' OR location like '%Germany%'
--order by 1,2