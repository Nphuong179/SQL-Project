-- Rank each country's athletes by number of medals they have earned, without skipping numbers in case of identical values
select 
	country,
	athlete,
    count(*) as medals,
    dense_rank() over(partition by country order by count(*) desc) as rank_n
from olympics
group by country, athlete
having count(*) > 1
order by country asc, medals desc;

-- Athlete who won more medals than at the previous Olympics
select
	year,
    athlete,
    current_medals,
    pre_medals
from(
	select 
		year,
		athlete,
		count(*) as current_medals,
		lag(count(*)) over(partition by athlete order by year asc) as pre_medals
	from olympics
	group by year, athlete) as sub_table
where current_medals > pre_medals;

-- Find the sport and nationality that women have won more medals than men for each year
with medals_gender_table as (
	select 
		country, year, sport,
		sum(case when gender = 'Men' then medals else 0 end) as medals_men,
		sum(case when gender = 'Women' then medals else 0 end) as medals_women
	from (
		select 
			year, 
            country, 
            sport, 
            gender, 
            count(*) as medals
		from olympics
		group by country, year, gender, sport) as medals_gender_subtable
		group by country, year, sport
        )
select 
	year, 
    country, 
    sport
from medals_gender_table
where medals_women > medals_men
order by year, country, sport;

-- Identify which sports each contry's athletes continue to win medal gold at Olympics
-- Adding row_number because there was a time the Olympics were held every 8 years rather than 4 years as usual 
with year_table as (
	select 
		year, 
        row_number() over() as row_n
    from (select distinct year from olympics order by year asc) as years),

medalGold_table as (
	select
		distinct country,
        sport,
        year,
        row_n
	from olympics
    left join year_table
    using(year)
    where medal = 'Gold'
    order by country, sport, year
),

country_sport_gold_momentum as(
	select 
		country, 
		sport, 
		year
	from(
		select 
			country, 
            sport, 
            year, row_n, 
            lag(row_n) over(partition by country, sport order by year) as pre_row_n
		from medalGold_table
		order by country, sport, year
		) as sub_table
	where row_n - pre_row_n = 1),

summary_country_sport_gold_momentum as(
    select 
		country, 
        sport, 
        count(*) as count_n
	from country_sport_gold_momentum
	group by country, sport
	order by country, sport
)

-- Identify which country can maintain the longest momentum in winning gold medal for each sport
select 
	s.sport, 
    country, 
    count_n
from summary_country_sport_gold_momentum s
join (
	select 
		sport, 
        max(count_n) as max_count
    from summary_country_sport_gold_momentum
    group by sport) as max_gold_medals
on s.sport = max_gold_medals.sport
and s.count_n = max_gold_medals.max_count 
order by sport

