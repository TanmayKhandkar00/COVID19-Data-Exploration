/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select * from [Portfolio Project]..CovidDeaths
--Where continent is not null
order by 3,4

-- Select data that we'll be using

Select location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project]..CovidDeaths
Order by 1,2

-- Looking at Total cases vs Total deaths
-- Shows the likelihood of dying from covid

Select location, date, total_cases, total_deaths, (convert(float,total_deaths)/ NULLIF(convert(float,total_cases),0))*100 as DeathPercentage
From [Portfolio Project]..CovidDeaths
Where location = 'India'
Order by 1,2

-- Looking at total Cases vs Population
-- Shows what percentage of population has covid

Select location, date, population, total_cases , (NULLIF(convert(float,total_cases),0)/population)*100 as PercentPopulationInfected
From [Portfolio Project]..CovidDeaths
--Where location = 'India'
Order by 1,2

-- Looking at countries with highest infection rates compared to popoulation

Select location, population, Max(total_cases) as HighestInfectionCount , Max((NULLIF(convert(float,total_cases),0)/population))*100 
as PercentPopulationInfected
From [Portfolio Project]..CovidDeaths
--Where location = 'India'
Group by location, population
Order by PercentPopulationInfected desc

--Will be creating a seperate table without the rows where location is a continent

Select * Into [Portfolio Project]..CovidDeaths1
From [Portfolio Project]..CovidDeaths
Where continent is not null;

select * from [Portfolio Project]..CovidDeaths1
order by 3,4


-- Showing the countries with Highest Death Count per Population

Select location, Max(convert(int,total_deaths)) as TotalDeathCount --or cast as int
From [Portfolio Project]..CovidDeaths1
Group by location
Order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

--Select continent, Max(convert(int,total_deaths)) as TotalDeathCount --or cast as int
--From [Portfolio Project]..CovidDeaths1
--Group by continent
--Order by TotalDeathCount desc

-- Showing Continent with highest Death Count

Select continent, sum(new_deaths) as TotalDeathCount             
From [Portfolio Project]..CovidDeaths1
Group by continent
Order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select continent, location, date, sum(new_cases) as TotalCases ,sum(new_deaths) as TotalDeathCount, 
(convert(float,sum(new_deaths))/NULLIF(convert(float,sum(new_cases)),0))*100  as DeathPercentage 
From [Portfolio Project]..CovidDeaths
Where continent is not null
Group by continent, location, date 
Order by 1,2,3

-- Total cases, deats and total death percentage

Select  sum(new_cases) as TotalCases ,sum(new_deaths) as TotalDeathCount, 
(convert(float,sum(new_deaths))/NULLIF(convert(float,sum(new_cases)),0))*100  as DeathPercentage 
From [Portfolio Project]..CovidDeaths
Where continent is not null
Order by 1,2

Select * from [Portfolio Project]..CovidVaccinations

-- Join Deaths and Vaccinations table

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from [Portfolio Project]..CovidDeaths1 dea
JOIN [Portfolio Project]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
Order by 1,2,3

-- New vaccinations per day, rolling count?

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationsRolling
from [Portfolio Project]..CovidDeaths1 dea
JOIN [Portfolio Project]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
Order by 1,2,3

-- Total population vs vaccination

-- USE CTE 
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, TotalVaccationsRolling)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationsRolling
from [Portfolio Project]..CovidDeaths1 dea
JOIN [Portfolio Project]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
)
Select *, (TotalVaccationsRolling/Population)*100
from PopvsVac

-- TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
TotalVaccinationsRolling bigint
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationsRolling
from [Portfolio Project]..CovidDeaths1 dea
JOIN [Portfolio Project]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
Select *, (TotalVaccinationsRolling/Population)*100
from #PercentPopulationVaccinated



-- CREATE VIEWS 
Create View TotalVaccinationsperDay as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationsRolling
from [Portfolio Project]..CovidDeaths1 dea
JOIN [Portfolio Project]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
--Order by 1,2,3

Create View TotalDeathPercentageIndia as
Select location, date, total_cases, total_deaths, (convert(float,total_deaths)/ NULLIF(convert(float,total_cases),0))*100 as DeathPercentage
From [Portfolio Project]..CovidDeaths1
Where location = 'India'
--Order by 1,2

-- using the continent column
Create view TotalDeathsinContinents as
Select continent, sum(new_deaths) as TotalDeathCount             
From [Portfolio Project]..CovidDeaths1
Group by continent
--Order by TotalDeathCount desc

Create view InfectionCountandPercent as
Select location, population, Max(total_cases) as HighestInfectionCount , Max((NULLIF(convert(float,total_cases),0)/population))*100 
as PercentPopulationInfected
From [Portfolio Project]..CovidDeaths1
--Where location = 'India'
Group by location, population
--Order by PercentPopulationInfected desc