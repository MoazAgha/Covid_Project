-- Remove rows that are not countries (continents, income class, etc...)
Select * From CovidProject..CovidDeaths
where continent is not null 
Order by 3,4

--Select * From CovidProject..CovidVacs
--Order by 3,4

-- Select the desired columns from Covid Deaths Table
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
where continent is not null 
Order By 1,2

-- Total cases vs. Total deaths
-- Likelihood of dying if you contract covid in the United States
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From CovidProject..CovidDeaths
--where location like '%states%'
where continent is not null 
Order By 1,2

-- Total cases vs. Population
-- Shows percentage of population that attracted covid
Select distinct Location, date, total_cases, population, (total_cases/population)*100 as Population_Infected_Rate
From CovidProject..CovidDeaths
--where location like '%states%'
Order By 1,2

--Countries with the highest infection rate compared to the population
Select Location, MAX(total_cases) as Highest_Infection_Rate, population, MAX((total_cases/population))*100 as Population_Infected_Rate
From CovidProject..CovidDeaths
where continent is not null 
Group By Location , Population
--where location like '%states%'
Order By Population_Infected_Rate desc	

-- Countries with the highest death rate per population
Select Location, MAX(cast(total_deaths as int)) as Total_Death_Count
From CovidProject..CovidDeaths
where continent is not null 
Group By Location
--where location like '%states%'
Order By Total_Death_Count desc

-- Filter death count results by continent and global areas
Select location, MAX(cast(total_deaths as int)) as Total_Death_Count
From CovidProject..CovidDeaths
where continent is null and location not like '%income%' and location not like 'international' -- remove rows related to income casualities (high, middle, low income)
Group By location
Order By Total_Death_Count desc


-- Daily death percentage by global numbers
Select date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as Death_Percentage_Globally
From CovidProject..CovidDeaths
where continent is not null 
Group by date
Order By 1,2

-- Death percentage of all time, including total cases and total death of all time
Select MAX(total_cases) as Total_Cases, MAX(cast(total_deaths as int)) as Total_Deaths,
MAX(cast(total_deaths as int))/MAX(total_cases) * 100 as Death_Percentage_Globally
From CovidProject..CovidDeaths 


-- Looking at total population vs. vaccinations
Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
SUM(convert(bigint, Vac.new_vaccinations)) Over (Partition by Dth.location order by Dth.location, convert(date,Dth.date)) AS RollingPeopleVaccinated,
-- RollingPeopleVaccinated / Dth.population) * 100 <--- Cannot perform this. RollingPeopleVaccinated is not recognized. Create Temporary table!
From CovidProject..CovidDeaths Dth
join CovidProject..CovidVacs Vac
	On Dth.date = Vac.date
	and Dth.location = Vac.location
where Dth.continent is not null
Order By 2,3

-- Temporary table: Query to create and edit percentage of vaccinataion per population over time
Drop Table if exists #PercentagePopulationVaccinated -- <-- helps us if we edit the insert statement later

Create Table #PercentagePopulationVaccinated (

Continent nvarchar(128),
Location nvarchar(128),
Date datetime,
Population Numeric,
New_Vaccinations Numeric,
RollingPeopleVaccinated Numeric)

Insert into #PercentagePopulationVaccinated
Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
SUM(convert(bigint, Vac.new_vaccinations)) Over (Partition by Dth.location order by Dth.location, convert(date,Dth.date)) AS RollingPeopleVaccinated
From CovidProject..CovidDeaths Dth
join CovidProject..CovidVacs Vac
	On Dth.date = Vac.date
	and Dth.location = Vac.location
where Dth.continent is not null

Select *, (RollingPeopleVaccinated / Population) *100
From #PercentagePopulationVaccinated


-- CREATING VIEWS
-- Store data for later visualizations

Create View PercentagePopulationVaccinated as
Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
SUM(convert(bigint, Vac.new_vaccinations)) Over (Partition by Dth.location order by Dth.location, convert(date,Dth.date)) AS RollingPeopleVaccinated
From CovidProject..CovidDeaths Dth
join CovidProject..CovidVacs Vac
	On Dth.date = Vac.date
	and Dth.location = Vac.location
where Dth.continent is not null


Create View DeathPercentageGlobally as 
Select date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as Death_Percentage_Globally
From CovidProject..CovidDeaths
where continent is not null 
Group by date


Create View TotalDeathCountByContinent as 
Select location, MAX(cast(total_deaths as int)) as Total_Death_Count
From CovidProject..CovidDeaths
where continent is null and location not like '%income%' and location not like 'international' -- remove rows related to income casualities (high, middle, low income)
Group By location


Create View PopulationInfectedRateByCountry as 
Select Location, MAX(total_cases) as Highest_Infection_Rate, population, MAX((total_cases/population))*100 as Population_Infected_Rate
From CovidProject..CovidDeaths
where continent is not null 
Group By Location , Population


Create View DeathPercentageDaily as 
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From CovidProject..CovidDeaths
where continent is not null 
