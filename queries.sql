-- Question 1:
-- What are the states that had days with more than 100 new deaths both before and after June? 
-- What are their policies in response to the situation? Compare those stats with other states where the pandemic is mild.

-- Report the name of states that had days with more than 100 new deaths 
-- both before and after June and the closure policies, quarantine mandate these states enforced.
-- Report the states that have never had days with more than 10 new deaths (the "mild" states)
-- and the states that were recovering after June (had days with more than 100 new deaths before June but not after)
-- Compare their enforced policies.


SET SEARCH_PATH TO UnderPandemic;

-- Query 0.1 The States with information about enforced policy and population overview.
DROP VIEW IF EXISTS temp CASCADE;
CREATE VIEW temp AS
select distinct cp.scode, stateName, dateSchoolClosed, dateBusinessClosed, q.dateMandate as dateQuarantine, e.dateMandate as dateMask,
populationDensity as popu_density, pPeopleBelowPov as percent_poverty
from ClosurePolicies cp natural join StateOverview 
left join QuarantineMandate q on cp.scode = q.scode
left join EnforceMask e on cp.scode = e.scode 
order by scode;

-- Query 1.1 The States that had days with more than 100 new deaths per day before June.
DROP VIEW IF EXISTS over100_BeforeJune CASCADE;
CREATE VIEW over100_BeforeJune AS
select distinct scode
from Cases
where deathDaily > 100 and date_part('month', daterecord) < 6
order by scode;

-- Query 1.2 The States that had days with more than 100 new deaths per day after June.
DROP VIEW IF EXISTS over100_AfterJune CASCADE;
CREATE VIEW over100_AfterJune AS
select distinct scode
from Cases
where deathDaily > 100 and date_part('month', daterecord) >= 6
order by scode;

-- Query 2.1 The States that had days with more than 100 daily new deaths before June, but not after.
DROP VIEW IF EXISTS states_recovering CASCADE;
CREATE VIEW states_recovering AS
select distinct scode
from (select * from over100_BeforeJune 
except 
select * from over100_AfterJune) as tempTable;

-- Query 2.2 The States that had days with more than 100 new deaths both before and after June.
DROP VIEW IF EXISTS states_severe CASCADE;
CREATE VIEW states_severe AS
select distinct scode
from (select * from over100_BeforeJune 
intersect 
select * from over100_AfterJune) as tempTable;

-- Query 2.3 The States that have never had days with more than 10 new deaths.
DROP VIEW IF EXISTS states_mild CASCADE;
CREATE VIEW states_mild AS
select distinct scode
from (select distinct scode from Cases
except
select distinct scode from Cases
where deathDaily > 10) as tempTable2
order by scode;

-- Query 3.1 The policyies of those states in severe situation.
select ss.scode, stateName, dateSchoolClosed, dateBusinessClosed, datequarantine, datemask
from states_severe ss natural join temp 
order by scode;

-- Query 3.2 The policies of the states that were recovering.
select sr.scode, stateName, dateSchoolClosed, dateBusinessClosed, datequarantine, datemask
from states_recovering sr natural join temp 
order by scode;

-- Query 3.3 The policies of the states in mild pandemic.
select sm.scode, stateName, dateSchoolClosed, dateBusinessClosed, datequarantine, datemask
from states_mild sm natural join temp 
order by scode;


-- Question 2: 
-- Did the population and poverty level have a correlation with the coronavirus cases?

DROP VIEW IF EXISTS LowPoverty CASCADE;
DROP VIEW IF EXISTS ModeratePoverty CASCADE;
DROP VIEW IF EXISTS HighPoverty CASCADE;
DROP VIEW IF EXISTS LowPopDensity CASCADE;
DROP VIEW IF EXISTS HighPopDensity CASCADE;

-- Query 1.1: States that have low percentage of people whose income in the past 12 months is below the poverty level (less than 10%)
Create view LowPoverty as
select scode, ppeoplebelowpov
from stateoverview
where ppeoplebelowpov <= 10;

-- Query 1.2: States that have moderate percentage of people whose income in the past 12 months is below the poverty level (between 10% to 15%)
Create view ModeratePoverty as
select scode, ppeoplebelowpov
from stateoverview
where ppeoplebelowpov > 10 and ppeoplebelowpov <= 15;

-- Query 1.3: States that have high percentage of people whose income in the past 12 months is below the poverty level (larger than 15%)
Create view HighPoverty as
select scode, ppeoplebelowpov
from stateoverview
where ppeoplebelowpov > 15;

-- Query 2.1: Showcases the daily average of positive cases and death cases for low poverty states 
select extract(month from daterecord) as month, round(avg(positivedaily)) as avg_positive_daily, round(avg(deathdaily)) as avg_death_daily
from LowPoverty natural join cases
group by extract(month from daterecord)
order by month;

-- Query 2.2: Showcases the daily average of positive cases and death cases for moderate poverty states 
select extract(month from daterecord) as month, round(avg(positivedaily)) as avg_positive_daily, round(avg(deathdaily)) as avg_death_daily
from ModeratePoverty natural join cases
where extract(month from daterecord) >= 3
group by extract(month from daterecord)
order by month;

-- Query 2.3: Showcases the daily average of positive cases and death cases for high poverty states 
select extract(month from daterecord) as month, round(avg(positivedaily)) as avg_positive_daily, round(avg(deathdaily)) as avg_death_daily
from HighPoverty natural join cases
where extract(month from daterecord) >= 3
group by extract(month from daterecord)
order by month;

-- Query 3.1: States that have low population density, which is less than 94 people per squared miles (the population density of us)
Create view LowPopDensity as
select scode, ppeoplebelowpov
from stateoverview
where populationdensity <= 94;

-- Query 3.2: States that have high population density, which is higher than 94 people per squared miles (the population density of us)
Create view HighPopDensity as
select scode, ppeoplebelowpov
from stateoverview
where populationdensity > 94;

-- Query 4.1: Showcases the daily average of positive cases and death cases for low population density states 
select extract(month from daterecord) as month, round(avg(positivedaily)) as avg_positive_daily, round(avg(deathdaily)) as avg_death_daily
from LowPopDensity natural join cases
group by extract(month from daterecord)
order by month;

-- Query 4.2: Showcases the daily average of positive cases and death cases for high population density states 
select extract(month from daterecord) as month, round(avg(positivedaily)) as avg_positive_daily, round(avg(deathdaily)) as avg_death_daily
from HighPopDensity natural join cases
where extract(month from daterecord) >= 3
group by extract(month from daterecord)
order by month;

-- Query 5.1: Showcases the daily average of positive cases and death cases for states that have low or moderate poverty and low population density.
select extract(month from daterecord) as month, round(avg(positivedaily)) as avg_positive_daily, round(avg(deathdaily)) as avg_death_daily
from (
    select * from LowPoverty
    UNION
    select * from ModeratePoverty
    INTERSECT
    select * from LowPopDensity
) t1 natural join cases
where extract(month from daterecord) >= 3
group by extract(month from daterecord)
order by month;

-- Query 5.2: Showcases the daily average of positive cases and death cases for states that have high poverty and high population density.
select extract(month from daterecord) as month, round(avg(positivedaily)) as avg_positive_daily, round(avg(deathdaily)) as avg_death_daily
from (
    select * from HighPoverty
    INTERSECT
    select * from HighPopDensity
) t1 natural join cases
where extract(month from daterecord) >= 3
group by extract(month from daterecord)
order by month;


-- Query 6.1: Showcases the population density and the percent of poverty of the states in severe situation.
DROP VIEW IF EXISTS severe_states_overview CASCADE;
CREATE VIEW severe_states_overview AS
select stateName, popu_density, percent_poverty
from states_severe natural join temp;

-- Query 6.2 Showcases the average population density and the average percent of poverty in the states in severe situation.
DROP VIEW IF EXISTS severe_states_avg CASCADE;
CREATE VIEW severe_states_avg AS
select avg(popu_density) as avg_density, avg(percent_poverty) as avg_percent_poverty
from states_severe natural join temp;

-- Query 6.3: Showcases the population density and the percent of poverty of the recovering states.
DROP VIEW IF EXISTS recovering_states_overview CASCADE;
CREATE VIEW recovering_states_overview AS
select stateName, popu_density, percent_poverty
from states_recovering natural join temp;

-- Query 6.4 Showcases the average population density and the average percent of poverty in the recovering states 
DROP VIEW IF EXISTS recovering_states_avg CASCADE;
CREATE VIEW recovering_states_avg AS
select avg(popu_density) as avg_density, avg(percent_poverty) as avg_percent_poverty
from states_recovering natural join temp;

-- Query 6.5: Showcases the population density and the percent of poverty of the states in mild situation.
DROP VIEW IF EXISTS mild_states_overview CASCADE;
CREATE VIEW mild_states_overview AS
select stateName, popu_density, percent_poverty
from states_mild natural join temp;

-- Query 6.6 Showcases the average population density and the average percent of poverty in the states with mild situation
DROP VIEW IF EXISTS mild_states_avg CASCADE;
CREATE VIEW mild_states_avg AS
select avg(popu_density) as avg_density, avg(percent_poverty) as avg_percent_poverty
from states_mild natural join temp;

select * from severe_states_overview;
select * from severe_states_avg;
select * from recovering_states_overview;
select * from recovering_states_avg;
select * from mild_states_overview;
select * from mild_states_avg;

-- Question 3: 
-- How does the outbreak of the COVID-19 pandemic directly impact the US stock markets and labour market?

-- Query 1.1: Stock market in 2020 from January to August that showcases the average price and volume for each month
select stock, extract(month from date) as month, round(avg((high+low)/2)) as avg_price, round(avg(volume)) as avg_volume
from stockmarket
where date >= '2020-01-01' and date <= '2020-08-31'
group by stock, extract(month from date)
order by stock, month;

-- Query 1.2: Stock market in 2019 from October to Decemeber that showcases the average price and volume for each month
select stock, extract(month from date) as month, round(avg((high+low)/2)) as avg_price, round(avg(volume)) as avg_volume
from stockmarket
where date < '2020-01-01'
group by stock, extract(month from date)
order by stock, month;


-- Query 2.1: Stock market in 2020 from Februray to March that showcases the percent chanege for price and volume since Februray for stock S&P
select s1.stock, s1.date, 1-round((((s1.high+s1.low)/2)/((s2.high+s2.low)/2))::numeric, 2) as price_prechange, round((s1.volume::numeric/s2.volume::numeric), 2) as volume_prechange
from stockmarket s1 join stockmarket s2 on s1.stock = s2.stock
where s2.date = '2020-02-03' and s1.date > '2020-02-20' and s1.date < '2020-04-01' and s1.stock = 'S&P';

-- Query 2.2: Stock market in 2020 from Februray to March that showcases the percent chanege for price and volume since Februray for stock Dow
select s1.stock, s1.date, 1-round((((s1.high+s1.low)/2)/((s2.high+s2.low)/2))::numeric, 2) as price_prechange, round((s1.volume::numeric/s2.volume::numeric), 2) as volume_prechange
from stockmarket s1 join stockmarket s2 on s1.stock = s2.stock
where s2.date = '2020-02-03' and s1.date > '2020-02-20' and s1.date < '2020-04-01' and s1.stock = 'Dow';

-- Query 2.3: Stock market in 2020 from Februray to March that showcases the percent chanege for price and volume since Februray for stock Nasdaq
select s1.stock, s1.date, 1-round((((s1.high+s1.low)/2)/((s2.high+s2.low)/2))::numeric, 2) as price_prechange, round((s1.volume::numeric/s2.volume::numeric)-1, 2) as volume_prechange
from stockmarket s1 join stockmarket s2 on s1.stock = s2.stock
where s2.date = '2020-02-03' and s1.date > '2020-02-20' and s1.date < '2020-04-01' and s1.stock = 'Nasdaq';

-- Query 3.1: Unemployment rate for California from January to August
select statename, month, rate
from unemployment natural join stateoverview
where statename = 'California'
order by statename;

-- Query 3.2: Unemployment rate for Washington from January to August
select statename, month, rate
from unemployment natural join stateoverview
where statename = 'Washington'
order by statename;

-- Query 3.3: Unemployment rate for Michigan from January to August
select statename, month, rate
from unemployment natural join stateoverview
where statename = 'Michigan'
order by statename;

-- Query 3.4: Unemployment rate for New York from January to August
select statename, month, rate
from unemployment natural join stateoverview
where statename = 'New York'
order by statename;

-- Query 4: Average unemployment rate for each month
select month, round(avg(rate)::numeric, 2) as rate 
from unemployment
group by month;
