-- The longest streak of gold medals for each country in each sport 
Create view LongestStreak As
With GoldMedals As (
	Select
		Distinct Year,
		Country,
		Sport
	From practice.dbo.olympics
	Where Medal = 'Gold'
),
	RankedMedals As (
	Select 
		Year,
		Country,
		Sport,
		ROW_NUMBER() over(partition by country, sport order by year) as RowNum
	From GoldMedals
),
	ConsecutiveYears As (
	Select 
		Year,
		Country,
		Sport,
		RowNum,
		Year - lag(year,1,Year) over(partition by country, sport order by year) as YearDiff
	From RankedMedals
),
	Streaks As (
	Select
		Year,
		Country,
		Sport,
		RowNum,
		YearDiff,
		Sum(Case When YearDiff = 4 Then 0 Else 1 End) Over(Partition by Country, Sport Order by Year) as StreakGroup 
	From ConsecutiveYears
),
	StreakLength As (
	Select
		Country,
		Sport,
		StreakGroup,
		count(*) as StreakLength
	From Streaks
	Group by Country, Sport, StreakGroup
)
Select
	Distinct s.Sport,
	StreakLength,
	Country
From StreakLength As s
Join (
Select
	Sport,
	MAX(StreakLength) As LongestLengthValue
From StreakLength
Group by Sport
) As LongestLength
on s.Sport = LongestLength.Sport
and s.StreakLength = LongestLength.LongestLengthValue;

-- Identify number of years every country had at least 3 attending sports that has gained gold medals
Create View NumberOfYear_AtLeastThreeSpots_WinGold As
With GoldMedals As (
	Select 
		distinct Country,
		Year,
		Sport
	From practice.dbo.olympics
	Where Medal = 'Gold'
	),
	NumberOfSportsGoldMedal As (
	Select 
		Country,
		Year,
		Count(*) As NumberOfSports
	From GoldMedals
	Group by Country, Year
	Having Count(*) > 2
	)
	Select 
		Country,
		Count(*) As NumberOfYears
	From NumberOfSportsGoldMedal
	Group by Country;
