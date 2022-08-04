/* Covid 19 Data Exploration
Skills used: joins, CTE's Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/
--SELECT * FROM CovidVaccinations
--ORDER BY location, date

SELECT * FROM CovidDeaths
WHERE continent is not NULL
ORDER BY location, date

-- select Data that we are going to be starting with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY iso_code, continent

--total cases vs total deaths
-- show likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
FROM CovidDeaths
WHERE location like '%nigeria%' and continent is not NULL
ORDER BY iso_code, continent


--total cases vs Population
-- shows what percentage of population infected with covid
SELECT location, date, total_cases, new_cases, total_deaths, (total_cases/population) * 100 as PercentPopulationIfected
FROM CovidDeaths
--WHERE location like '%nigeria%' and continent is not NULL
ORDER BY iso_code, continent

--countries with highest infection rate compared to population
SELECT Location, Population, MAX((total_cases/population ))* 100 as  PercentPopulationIfected
FROM CovidDeaths
Group by Location, Population
ORDER BY PercentPopulationIfected DESC


--countries with highest Deaths count per population
SELECT Location, MAX(cast(total_deaths as int )) as  TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL 
Group by Location
ORDER BY TotalDeathCount DESC


--BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with highest death count per population
SELECT continent, MAX(cast(total_deaths as int )) as  TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL
Group by continent
ORDER BY TotalDeathCount DESC


--GLOBAL NUMBERS
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_cases)*100 as DeathPercentage
FROM CovidDeaths 
WHERE continent is not NULL
ORDER BY 1,2

--Total Population vs Vaccinations
--Shows Percentage of Population that has received at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location 
ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

/*Using CTE to perform Calculation on Partition By in previous query*/
with PopvsVac (Continent, location, Date, population, new_Vaccinations, RollingPeopleVaccinated) as (

SELECT dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location 
ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
) SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
