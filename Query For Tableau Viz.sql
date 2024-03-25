
-- Create union of 4 tables
DROP TABLE IF EXISTS #Temp_TotalB4udigOutput

Create Table #Temp_TotalB4udigOutput
(
Name nvarchar(255),
SiteName nvarchar(255),
Status nvarchar(255),
JO float,
Date datetime,
Location nvarchar(255)
)

Insert Into #Temp_TotalB4udigOutput
Select Ghes.Name, Ghes.SiteName, Ghes.Status, Ghes.JO, Ghes.Date, Ghes.Location
From b4udigData2023..New_B4udig_Ghesie as Ghes
Where Name Is Not Null

UNION ALL

Select Nik.Name, Nik.SiteName, Nik.Status, Nik.JO, Nik.Date, Nik.Location
From b4udigData2023..New_B4udig_Nikko as Nik
Where Name Is Not Null

UNION ALL

Select Rus.Name, Rus.SiteName, Rus.Status, Rus.JO, Rus.Date, Rus.Location
From b4udigData2023..New_B4udig_Russel as Rus
Where Name Is Not Null

UNION ALL

Select Dav.Name, Dav.SiteName, Dav.Status, Dav.JO, Dav.Date, Dav.Location
From b4udigData2023..New_B4udig_David as Dav
Where Name Is Not Null

ORDER BY Date


Select *
From #Temp_TotalB4udigOutput


-- Table 1 for tableau (Monthly B4udig Request)
Select Name as Team_Member, Count(JO) as B4udig_Request, Date
From #Temp_TotalB4udigOutput
Group By Name, Date

-- Table 2 for tableau (Completion Rate)

--Step 1: (Create Table for B4udig Request with complete plans)
DROP TABLE IF EXISTS #Temp_Completed
Create Table #Temp_Completed
(
Team_Member nvarchar(255),
Request_With_Complete_Plans int,
)

Insert into #Temp_Completed
select Name as Team_Member, Count(Status) as Request_With_Complete_Plans
FROM #Temp_TotalB4udigOutput
WHERE Status='Completed'
GROUP by Name

Select *
From #Temp_Completed

--Step 2: (Create Table for Total B4udig Request)
DROP TABLE IF EXISTS #Temp_Total_Output
Create Table #Temp_Total_Output
(
Team_Member nvarchar(255),
Total_B4udig_Request int
)

Insert Into #Temp_Total_Output
Select Name as Team_Member, COUNT(JO) as Total_B4udig_Request
From #Temp_TotalB4udigOutput
GROUP BY Name, DATEPART(Year, Date)

Select *
From #Temp_Total_Output

--Step 3: (Use CTE to join 2 tables and compute the completion rate per team member)
With CTE_CompletionRate as 
(
Select #Temp_Completed.Team_Member, Total_B4udig_Request, Request_With_Complete_Plans
From #Temp_Completed
JOIN #Temp_Total_Output on #Temp_Completed.Team_Member = #Temp_Total_Output.Team_Member
)

Select *, (CAST(Request_With_Complete_Plans AS DECIMAL) / CAST(Total_B4udig_Request AS DECIMAL))*100 as Completion_Rate
From CTE_CompletionRate
Group By Team_Member, Total_B4udig_Request, Request_With_Complete_Plans

-- Table 3 for tableau (Job Locations)

Select Location, Count(JO) as B4udigRequest_Per_Region
From #Temp_TotalB4udigOutput
Group By Location