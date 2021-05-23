drop schema if exists underpandemic cascade;
create schema underpandemic;
set search_path to underpandemic;
 
create domain StateCode as char(2);
 
create domain DataQuality as varchar(2)
   check (value in ('A+', 'A', 'B', 'C', 'D', 'F'));
 
create domain EnforcementType as text
   check (value in ('fines', 'charge', 'both', 'none'));
  
create domain People as text
   check (value in ('employee', 'all'));
 
create domain Stocks as text
   check (value in ('Dow', 'S&P', 'Nasdaq'));
 
create table StateOverview(
   sCode StateCode primary key,
   stateName text not null,
   population bigserial not null,
   under5 bigserial not null,
   over65 bigserial not null,
   populationDensity float not null,    
   nHouseBelowPov bigserial,
   pPeopleBelowPov float
);
 
create table Cases(
   dateRecord date,
   sCode StateCode references StateOverview,
   dataQuality DataQuality,
   testTotal integer,
   testDaily int,
   positive int,
   positiveDaily int,
   death int,
   deathDaily int,
   primary key (dateRecord, sCode)
);

create table ClosurePolicies(
   sCode StateCode primary key,
   dateSchoolClosed date,
   dateBusinessClosed date,
   quarantineMandate boolean,
   foreign key(sCode) references StateOverview
);

create table QuarantineMandate(
   sCode StateCode primary key,
   dateMandate date,
   foreign key(sCode) references StateOverview
);
 
create table MaskMandate(
   sCode StateCode primary key,
   enforcementLevel boolean not null,
   foreign key(sCode) references StateOverview
);
 
create table EnforceMask(
   sCode StateCode primary key,
   dateMandate date not null,
   people People not null,
   enforceType EnforcementType not null,
   foreign key(sCode) references MaskMandate
);
 
create table UnemployInsurance(
   sCode StateCode primary key,
   weeklyMax int not null,
   durationWeeks int not null,
   foreign key(sCode) references StateOverview
);
 
create table StockMarket(
   stock Stocks,
   date date,
   high float not null,
   low float not null,
   volume bigserial not null,
   primary key (stock, date)
);
 
create table Unemployment(
   month text,
   sCode StateCode references StateOverview,
   rate float,
   Primary key (month, sCode)
);