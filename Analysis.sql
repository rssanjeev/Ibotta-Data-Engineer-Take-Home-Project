

DROP PROCEDURE IF EXISTS Top10TA;
GO
create procedure Top10TA
as begin
select top 10 * from dbo.Traffic_Accidents end;

DROP PROCEDURE IF EXISTS Top10SR;
GO
create procedure Top10SR
as begin
select top 10 * from dbo.Service_Requests end;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Service Requests

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Neighborhood - Type of Cases
--select distinct Type from dbo.Service_Requests


--Are there seasonal trends to the different types of events?


--Weekday - Type of Cases
DROP PROCEDURE IF EXISTS WEEKDAY_CASES
GO

/*
Let us start with finding the number of cases that occur per day of the week. This is calculated considering the entire data as it would give us a better perspective 
of the issues that we would come across on a daily basis over the course of the week.
*/

CREATE PROCEDURE WEEKDAY_CASES
AS BEGIN
select DATENAME(WEEKDAY,CaseCreatedDttm) as Day_of_Week, 
		count(Type) Cases
from dbo.Service_Requests
group by DATENAME(WEEKDAY,CaseCreatedDttm)
order by count(Type) desc
END;
go

EXEC WEEKDAY_CASES;

/*
Inference:
The number of cases drastically drops during the weekend from around 85 thousand to 10 thousand.
*/

DROP PROCEDURE IF EXISTS WEEKDAY_TYPE_OF_CASES
GO

/*
Now let us cross-examine day of the week against the type of cases. This would give us a much better perspective for each type of case that are reported. 
*/

CREATE PROCEDURE WEEKDAY_TYPE_OF_CASES
AS BEGIN
select DATENAME(WEEKDAY,CaseCreatedDttm) as Day_of_Week,
		count(Case when Type='Compliment' then Type end) as 'Compliment', 
		count(Case when Type='Request' then Type end) as 'Request',
		count(Case when Type='Inquiry' then Type when Type='Inqury' then Type end) as 'Inquiry',
		count(Case when Type='Complaint' then Type end) as 'Complaint'
from dbo.Service_Requests 
group by DATENAME(WEEKDAY,CaseCreatedDttm)
order by count(Case when Type='Complaint' then Type end) desc
END;

EXEC WEEKDAY_TYPE_OF_CASES;

/*
Inference:
We can see that the number of complaints are at its peak during the first three days of the week starting from Monday. And again on Friday.
*/

DROP PROCEDURE IF EXISTS HOUR_CASES
GO

/*
Let us break out the cases across the hours of the day.
*/

CREATE PROCEDURE HOUR_CASES
AS BEGIN
select DATENAME(HOUR,CaseCreatedDttm) as Hour_of_the_Day,
		count(Type) Cases
from dbo.Service_Requests
group by DATENAME(HOUR,CaseCreatedDttm)
order by count(Type) desc
END;
go

EXEC HOUR_CASES;

/*
Inference: The number of cases are evenly distributed from 9 AM till 3 PM.
*/

--Hour - Type of Cases
DROP PROCEDURE IF EXISTS HOUR_TYPE_OF_CASES
GO

/*
Like before let us split the different type of cases across the hours of the day.
*/

CREATE PROCEDURE HOUR_TYPE_OF_CASES
AS BEGIN
select DATENAME(HOUR,CaseCreatedDttm) as Hour_of_the_Day,
		count(Case when Type='Compliment' then Type end) as 'Compliment', 
		count(Case when Type='Request' then Type end) as 'Request',
		count(Case when Type='Inquiry' then Type when Type='Inqury' then Type end) as 'Inquiry',
		count(Case when Type='Complaint' then Type end) as 'Complaint'
from dbo.Service_Requests 
group by DATENAME(HOUR,CaseCreatedDttm)
order by count(Case when Type='Complaint' then Type end) desc
END;
GO

EXEC HOUR_TYPE_OF_CASES;

/*
Inference: Towards the end of the day, the number of Compliants drops and Inquiries increases.
*/

-- Which types of events are more common by geographic areas, as defined by coordinates or neighborhood?
DROP PROCEDURE IF EXISTS NEIGHBORHOOD_CASES;
GO

/*
When we split the type of cases across various neighborhoods, we have the ability to have a better understanding of the neighborhoods that are source of various
types of cases along with the Council Districts. 
*/

CREATE PROCEDURE NEIGHBORHOOD_CASES
AS BEGIN
select Neighborhood, 
		count(Case when Type='Compliment' then Type end) as 'Compliment', 
		count(Case when Type='Inquiry' then Type when Type='Inqury' then Type end) as 'Inquiry',
		count(Case when Type='Request' then Type end) as 'Request',
		count(Case when Type='Complaint' then Type end) as 'Complaint'
from dbo.Service_Requests
where Neighborhood is not null
group by Neighborhood
order by count(Case when Type='Complaint' then Type end) desc
END;

EXEC NEIGHBORHOOD_CASES;

--Top 4 Neighborhoods and their respective Council_Districts with highest complaints, Request & Inquiries.

DROP PROCEDURE IF EXISTS Top_Districts_Neighborhoods;
GO

CREATE PROCEDURE Top_Districts_Neighborhoods
AS BEGIN
select distinct CouncilDistrict, Neighborhood from
(select 
	distinct a.CouncilDistrict, 
	b.Neighborhood 
from dbo.Service_Requests a 
join
	(select 
		Neighborhood, 
		count(Type) Complaints, 
		rank() over (order by count(Type) desc) Ranky 
	from dbo.Service_Requests 
	where Type = 'Complaint' and Neighborhood is not null 
	group by Neighborhood ) b 
	on a.Neighborhood = b.Neighborhood
where b.Ranky<5 and a.PoliceDistrict is not null and b.Neighborhood is not null
union all
select 
	distinct a.CouncilDistrict, 
	b.Neighborhood 
from dbo.Service_Requests a 
join
	(select 
		Neighborhood, 
		count(Type) Inquiries, 
		rank() over (order by count(Type) desc) Ranky 
	from dbo.Service_Requests 
	where Type like '%Inq%' and Neighborhood is not null 
	group by Neighborhood ) b 
	on a.Neighborhood = b.Neighborhood
where b.Ranky<5 and a.PoliceDistrict is not null and b.Neighborhood is not null
union all
select 
	distinct a.CouncilDistrict, 
	b.Neighborhood 
from dbo.Service_Requests a 
join
	(select 
		Neighborhood, 
		count(Type) Inquiries, 
		rank() over (order by count(Type) desc) Ranky 
	from dbo.Service_Requests 
	where Type like '%Request%' and Neighborhood is not null 
	group by Neighborhood ) b 
	on a.Neighborhood = b.Neighborhood
where b.Ranky<5 and a.PoliceDistrict is not null and b.Neighborhood is not null) x
END;
GO

EXEC Top_Districts_Neighborhoods;

/*
Reason why not using the below query instead of the above one is that we will 
miss out the 'Westwood' neighborhood which is the 4th highest complaint receiving neighborhood,
select 
	distinct a.CouncilDistrict, 
	b.Neighborhood 
from dbo.Service_Requests a 
join
	(select 
		Neighborhood, 
		count(Type) Complaints, 
		rank() over (order by count(Type) desc) Ranky 
	from dbo.Service_Requests 
	where Type in ('Complaint','Request','Inquiry','Inqury') and Neighborhood is not null 
	group by Neighborhood ) b 
	on a.Neighborhood = b.Neighborhood
where b.Ranky<5 and a.PoliceDistrict is not null and b.Neighborhood is not null
*/

/*
Inference: We can see that Districts 3, 8, 9 & 11 have the most number of cases.
*/

--How long are typical response/resolution times? Do these differ by type of event, geography, or other factors?
/*
The Response time is calculated by the difference between the Time the case was created and the time it was closed.
*/

DROP PROCEDURE IF EXISTS AVG_SR_RESPONSE_TIME
GO

CREATE PROCEDURE AVG_SR_RESPONSE_TIME
AS BEGIN
select Avg(Cast(datediff(DAY,CaseCreatedDttm,CaseClosedDttm) as int)) Average_ResponseTime_Days
from dbo.Service_Requests 
where Neighborhood is not null and Type is not null and CaseClosedDttm is not null and CaseCreatedDttm is not null
END;
GO

EXEC AVG_SR_RESPONSE_TIME;

DROP PROCEDURE IF EXISTS AVG_SR_NEIGHBORHOOD_RESPONSE_TIME
GO

CREATE PROCEDURE AVG_SR_NEIGHBORHOOD_RESPONSE_TIME
AS BEGIN
select Neighborhood, 
		Avg(Cast(datediff(DAY,CaseCreatedDttm,CaseClosedDttm) as int)) Average_ResponseTime_Days
from dbo.Service_Requests 
where Neighborhood is not null and CaseClosedDttm is not null and CaseCreatedDttm is not null 
group by Neighborhood 
order by Avg(Cast(datediff(DAY,CaseCreatedDttm,CaseClosedDttm) as int)) desc
END;
GO

EXEC AVG_SR_NEIGHBORHOOD_RESPONSE_TIME;

--Avg Reponse Time for each Type of Traffic Offense
DROP PROCEDURE IF EXISTS AVG_SR_REQUEST_TYPE_RESPONSE_TIME
GO

CREATE PROCEDURE AVG_SR_REQUEST_TYPE_REPONSE_TIME
AS BEGIN
select Type, 
		Avg(Cast(datediff(DAY,CaseCreatedDttm,CaseClosedDttm) as bigint)) Average_ResponseTime_Days
from dbo.Service_Requests 
where Type is not null and CaseClosedDttm is not null and CaseCreatedDttm is not null 
group by Type 
order by Avg(Cast(datediff(DAY,CaseCreatedDttm,CaseClosedDttm) as bigint)) desc
END;
GO

EXEC AVG_SR_REQUEST_TYPE_REPONSE_TIME;

/*
Inference: The average reponse time for any type of complaint is 10 days no matter which type of case it is or the source. 'Valverde' takes the longest response time 
of 25 days followed by 'Auraria' with 17 days as average response time. When we analyze the average reponse time for various types of requests, an Inquiry gets the quickest 
response of 5 days while a Complaint takes 14 days on an average. 
*/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Traffic Accidents

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Let us apply similar analsis we did till now to the traffic accidents data.

--Seasonal Trend
/* While all the other years are folowing similar pattern over their months, 2020 alone stands out with drastic drop. I believe it to be 
 direct impact of COVID-19 as road transport drastically dropped during the pandemic and everyone stayed in-doors.
 It is evident as the month (February) with highest number of incidents in 2020 is ranked 57th overall followed by January at 75th.
*/

DROP PROCEDURE IF EXISTS MONTHWISE_ACCIDENTS
GO

CREATE PROCEDURE MONTHWISE_ACCIDENTS
AS BEGIN
select year(FIRST_OCCURRENCE_DATE) Years,
		month(FIRST_OCCURRENCE_DATE) Months, 
		count(INCIDENT_ID) Incidents 
from dbo.Traffic_Accidents 
where year(FIRST_OCCURRENCE_DATE)>2011 
group by year(FIRST_OCCURRENCE_DATE),month(FIRST_OCCURRENCE_DATE) 
order by count(INCIDENT_ID) desc
END;
GO

EXEC MONTHWISE_ACCIDENTS;

/*
Looks like 'Fatal Accidents' are the top most occuring Incident across all months over the past few years, between 2014 and 2020. 
Excluding 2020 as the data is affected by the pandemic.
*/

/*
Let us try to find out which type of Traffic Offense causes the most number of accidents
*/
DROP PROCEDURE IF EXISTS MONTHWISE_TRAFFIC_OFFENSE
GO

CREATE PROCEDURE MONTHWISE_TRAFFIC_OFFENSE
AS BEGIN
select a.Years, a.Months, a.TOP_TRAFFIC_ACCIDENT_OFFENSE,a.Incidents from 
(
	select 
		year(FIRST_OCCURRENCE_DATE) Years,
		month(FIRST_OCCURRENCE_DATE) Months, 
		TOP_TRAFFIC_ACCIDENT_OFFENSE, 
		count(INCIDENT_ID) Incidents, 
		rank() over (partition by year(FIRST_OCCURRENCE_DATE),month(FIRST_OCCURRENCE_DATE) order by count(INCIDENT_ID) desc) Ranky 
	from dbo.Traffic_Accidents
	where month(FIRST_OCCURRENCE_DATE)<>2020 and year(FIRST_OCCURRENCE_DATE)>2014
	group by year(FIRST_OCCURRENCE_DATE),month(FIRST_OCCURRENCE_DATE), TOP_TRAFFIC_ACCIDENT_OFFENSE
) a
where a.Ranky=1 order by a.Incidents desc
END;
GO

EXEC MONTHWISE_TRAFFIC_OFFENSE;

/*
Inference:

Its  the 'TRAF-ACCIDENT' without any other type across the data from 2014 till 2019. I didn't want to generalise the data by including data before 2014 
as they are very scarce and data from 2020 because of the pandemic.
*/


DROP PROCEDURE IF EXISTS NEIGHBORHOODWISE_TRAFFIC_OFFENSE
GO

CREATE PROCEDURE NEIGHBORHOODWISE_TRAFFIC_OFFENSE
AS BEGIN
select a.TOP_TRAFFIC_ACCIDENT_OFFENSE, a.NEIGHBORHOOD_ID, a.Incidents from 
(
select 
	TOP_TRAFFIC_ACCIDENT_OFFENSE, 
	NEIGHBORHOOD_ID, 
	count(INCIDENT_ID) Incidents, 
	rank() over (partition by TOP_TRAFFIC_ACCIDENT_OFFENSE order by count(INCIDENT_ID) desc) Ranky 
from dbo.Traffic_Accidents
where NEIGHBORHOOD_ID is not null
group by TOP_TRAFFIC_ACCIDENT_OFFENSE, NEIGHBORHOOD_ID
) a where a.Ranky<=3
END;
GO

EXEC NEIGHBORHOODWISE_TRAFFIC_OFFENSE;

/*
Inference:
Upon analyzing the type of Traffic Offsense against the Neighborhood, we can see that the 'Stapleton' is  a 
repeated member of the leaderboard topping 4 out of the 6 offenses.
*/

--How long are typical response/resolution times? Do these differ by type of event, geography, or other factors?
/*
The Response time is calculated by the difference between the First Occurrence Date and Reported Date.
*/
DROP PROCEDURE IF EXISTS AVG_TA_RESPONSE_TIME
GO

CREATE PROCEDURE AVG_TA_RESPONSE_TIME
AS BEGIN
select Avg(Cast(datediff(HOUR,FIRST_OCCURRENCE_DATE,REPORTED_DATE) as int)) Average_ResponseTime_Hours
from dbo.Traffic_Accidents 
where NEIGHBORHOOD_ID is not null and FIRST_OCCURRENCE_DATE is not null and REPORTED_DATE is not null
END;
GO

EXEC AVG_TA_RESPONSE_TIME;

/*
Average response time of any type of accident is 24 hours.
*/

--Avg Reponse Time for each Type of Traffic Offense
DROP PROCEDURE IF EXISTS AVG_TRAFFIC_OFFENSE_RESPONSE_TIME
GO

CREATE PROCEDURE AVG_TRAFFIC_OFFENSE_RESPONSE_TIME
AS BEGIN
select TOP_TRAFFIC_ACCIDENT_OFFENSE, 
		Avg(Cast(datediff(HOUR,FIRST_OCCURRENCE_DATE,REPORTED_DATE) as int)) Average_ResponseTime_Hours 
from dbo.Traffic_Accidents 
where NEIGHBORHOOD_ID is not null and FIRST_OCCURRENCE_DATE is not null and REPORTED_DATE is not null 
group by TOP_TRAFFIC_ACCIDENT_OFFENSE 
order by Avg(Cast(datediff(HOUR,FIRST_OCCURRENCE_DATE,REPORTED_DATE) as int)) desc
END;
GO

EXEC AVG_TRAFFIC_OFFENSE_RESPONSE_TIME;

/*
With DUI/DUID. SBI and FATAL accidents having less than an hour of average response time, HIT & RUN has the highest average response time of 36 hours.
*/

--Avg Reponse Time for each Neighborhood
DROP PROCEDURE IF EXISTS AVG_TA_NEIGHBORHOOD_REPSONSE_TIME
GO

CREATE PROCEDURE AVG_TA_NEIGHBORHOOD_RESPONSE_TIME
AS BEGIN
select NEIGHBORHOOD_ID, 
		Avg(Cast(datediff(HOUR,FIRST_OCCURRENCE_DATE,REPORTED_DATE) as int)) Average_ResponseTime_Hours 
from dbo.Traffic_Accidents 
where NEIGHBORHOOD_ID is not null and FIRST_OCCURRENCE_DATE is not null and REPORTED_DATE is not null 
group by NEIGHBORHOOD_ID 
order by Avg(Cast(datediff(HOUR,FIRST_OCCURRENCE_DATE,REPORTED_DATE) as int)) desc
END;
GO

EXEC AVG_TA_NEIGHBORHOOD_RESPONSE_TIME;

/*
While 'Wellshire' has an hour as  average response time, 'Civic Center' has the highest average response time of 285 hours.
*/

--Avg Reponse Time for each Light Condition
DROP PROCEDURE IF EXISTS AVG_TA_LIGHT_CONDITION_RESPONSE_TIME
GO

CREATE PROCEDURE AVG_TA_LIGHT_CONDITION_RESPONSE_TIME
AS BEGIN
select LIGHT_CONDITION, 
		Avg(Cast(datediff(HOUR,FIRST_OCCURRENCE_DATE,REPORTED_DATE) as int)) Average_ResponseTime_Hours 
from dbo.Traffic_Accidents 
where LIGHT_CONDITION <> '  ' and FIRST_OCCURRENCE_DATE is not null and REPORTED_DATE is not null 
group by LIGHT_CONDITION 
order by Avg(Cast(datediff(HOUR,FIRST_OCCURRENCE_DATE,REPORTED_DATE) as int)) desc
END;
GO

EXEC AVG_TA_LIGHT_CONDITION_RESPONSE_TIME;

/*
Inference:
It is obvious that the accidents tha happen during the day time has the least average response time of 3 hours and the 'DARK-UNLIGHTED' has in an average of 8 hours for 
response time.
*/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Correlation Analysis

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
I believe that there is a strong correlation between the two datasets.
*/

-- Example:
/*
The following query will join the two datasets based on the Incident/Case Opened Date and the partial match of Neighborhoods 
and provide the sum of incidents happened on that particular date and the corresponding neighborhood.
*/
DROP PROCEDURE IF EXISTS CORRELATION_ANALYSIS_1
GO

CREATE PROCEDURE CORRELATION_ANALYSIS_1
AS BEGIN
with cte as (
select CASE_DATE, Neighborhood,count(*) Incidents  from dbo.Service_Requests where Neighborhood is not null group by CASE_DATE, Neighborhood
),
cte2 as (
select INCIDENT_DATE, NEIGHBORHOOD_ID,count(*) Incidents  from dbo.Traffic_Accidents where NEIGHBORHOOD_ID is not null group by INCIDENT_DATE, NEIGHBORHOOD_ID
)
select * from cte join cte2 on cte.CASE_DATE = cte2.INCIDENT_DATE and (cte.Neighborhood LIKE '%'+cte2.NEIGHBORHOOD_ID+'%' or cte2.NEIGHBORHOOD_ID LIKE '%'+cte.Neighborhood+'%') order by cte.CASE_DATE
END;
GO

EXEC CORRELATION_ANALYSIS_1

-- There will be duplicate entries from both the tables due to the partial match between the Neighborhoos. 
-- For Example: 'North Capitol Hill' from Service Requests would match with both 'Capitol Hills' and 'North Capitol Hills' from Traffic Acidents.
-- It is better to be over prepared than to miss out on key insights.

/*
Further stremlining the above query would provide us with various insights that would help up us how the Service Requests and Traffic Accidents 
are related to one another. I believe some of the service requests are related to the Traffic Accidents. This claim is supported by modifying the 
above query a little bit.
*/
DROP PROCEDURE IF EXISTS CORRELATION_ANALYSIS_1A
GO

CREATE PROCEDURE CORRELATION_ANALYSIS_1A
AS BEGIN
with cte as (
select CASE_DATE, Neighborhood,CaseSource,count(*) SR_Incidents  from dbo.Service_Requests where Neighborhood is not null group by CASE_DATE, Neighborhood,CaseSource
),
cte2 as (
select INCIDENT_DATE, NEIGHBORHOOD_ID,count(*) TA_Incidents  from dbo.Traffic_Accidents where NEIGHBORHOOD_ID is not null group by INCIDENT_DATE, NEIGHBORHOOD_ID
)
select CaseSource, count(*) REQUESTS_ACCIDENTS from (
select * from cte join cte2 on cte.CASE_DATE = cte2.INCIDENT_DATE and (cte.Neighborhood LIKE '%'+cte2.NEIGHBORHOOD_ID+'%' or cte2.NEIGHBORHOOD_ID LIKE '%'+cte.Neighborhood+'%') --order by cte.CASE_DATE
) a group by a.CaseSource
END;
GO

EXEC CORRELATION_ANALYSIS_1A;

/*
As we can see, more than 90% if those Service Requests are made from a 'Phone'. (Our immediate reaction after witnessing an accident is to call for help,
not email for help.)
*/

--exec Top10SR
--exec Top10TA

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Extras

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
Aggressive Driving is a strong driver for Incidents and subsequent Fatalities & Serious Injuries.
*/
select b.Human_Factor, count(x.INCIDENT_ID) Incidents, sum(x.FATALITIES) Fatalities, sum(x.SERIOUSLY_INJURED) Seriously_Injured
from dbo.Traffic_Accidents x join 
	(select distinct Human_factor from
	(select distinct TU1_DRIVER_HUMANCONTRIBFACTOR Human_Factor
		from dbo.Traffic_Accidents 
		where TU1_DRIVER_HUMANCONTRIBFACTOR is not null and TU1_DRIVER_HUMANCONTRIBFACTOR <> '  '
	union all
	select distinct TU2_DRIVER_HUMANCONTRIBFACTOR Human_Factor
		from dbo.Traffic_Accidents 
		where TU2_DRIVER_HUMANCONTRIBFACTOR is not null and TU2_DRIVER_HUMANCONTRIBFACTOR <> '  '
	) a
) b on x.TU1_DRIVER_HUMANCONTRIBFACTOR = b.Human_Factor or x.TU2_DRIVER_HUMANCONTRIBFACTOR = b.Human_Factor
group by b.Human_Factor order by count(x.INCIDENT_ID) desc

/*
Monthwise various incidents
*/
select month(FIRST_OCCURRENCE_DATE) Months, 
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - POLICE' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Police', 
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Accident',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - HIT & RUN' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Hit-n-Run',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - FATAL' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Fatal',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - SBI' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'SBI',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - DUI/DUID' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'DUI/DUID'
from dbo.Traffic_Accidents
where month(FIRST_OCCURRENCE_DATE) is not null
group by month(FIRST_OCCURRENCE_DATE) 
order by month(FIRST_OCCURRENCE_DATE)

/*
Vaious incidents across the Neighborhoods
*/
select NEIGHBORHOOD_ID, 
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - POLICE' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Police', 
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Accident',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - HIT & RUN' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Hit-n-Run',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - FATAL' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'Fatal',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - SBI' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'SBI',
		count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - DUI/DUID' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) as 'DUI/DUID'
from dbo.Traffic_Accidents
where NEIGHBORHOOD_ID is not null
group by NEIGHBORHOOD_ID 
order by count(Case when TOP_TRAFFIC_ACCIDENT_OFFENSE='TRAF - ACCIDENT - HIT & RUN' then TOP_TRAFFIC_ACCIDENT_OFFENSE end) desc

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*

Future Developments

*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*

1.  More data preprocessing is required, like the case summary is very disorganized.
2. The data consists of verying data length limit than that was mentioned on the meta data file. In the future, I would automate the process of analysising the 
max length of each and every column and compare it with the current table's structure and make necessary changes.
3. Add more flexibilty to the Python datapipeline from where the data is read till how its processed. Like hadling the Upper case and lower case issues.
4. With much better understaniding of the data requiremnts, I would be able to design much more effective Clustered, Non-Clustered and Filtered Indexes. 
And even use Indexed Views for non-frequently updated data for a robust read queries.
5. For Future developoment, we can try checking the light & road conditions against the Neighbourhood or the Offense type to better understand the cause of the surge in response time.
6. Use additional data to udestand the nature of each and every case much better. For Example: Crime data cane be used to better understand why so many cases arise from a 
particular neighborhood.
7. We can also use weather data to understan dthe seriousness/legitimacy of the call. Like if the call was related to the weather condition.
*/


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*

I would like to thank the team for their prompt response whenver I needed guidance or assistance.

Thank you once again.

*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
