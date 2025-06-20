alter table weekly_sales add week_number int,
month_number int,
calendar_year int, 
age_band varchar(15), 
demographic varchar(15);

ALTER TABLE weekly_sales ALTER COLUMN segment VARCHAR(10);

alter table weekly_sales add week_date2 date

update weekly_sales
set week_date =  PARSE (week_date AS date USING 'en-GB') from weekly_sales

alter table weekly_sales drop column week_date


select * from clean_weekly_sales;

select week_date2, 
DATEPART(WEEK, week_date2) as week_number, 
month(week_date2) as months, 
year(week_date2) as years,
 case
	when segment='null' then 'Unknown'
	when right(segment,1) = '1' then 'Young Adult'
	when right (segment,1) = '2' then 'Middle Aged'
	else 'Retirees'
 end as age_band,

 case 
	 when segment='null' then 'Unknown'
	when left(segment,1) = 'C' then 'Couples'
	when left (segment,1) = 'F' then 'Families'
 end as demographic,

 round((cast(sales as float)/ transactions), 2) as avg_transaction, region, platform, sales, transactions, customer_type
into clean_weekly_sales
from weekly_sales;

select * from clean_weekly_sales order by week_number;

drop table clean_weekly_sales;


--1. What day of the week does each week_date fall on?
-- → Find out which weekday (e.g., Monday, Tuesday) each sales week starts on.
select distinct DATENAME(DW, week_date2) as Day_Name from clean_weekly_sales;

--2. What range of week numbers are missing from the dataset?
WITH missing_week AS (
    SELECT 1 AS starting
    UNION ALLA
    SELECT starting + 1
    FROM missing_week
    WHERE starting < 53
)
SELECT starting
FROM missing_week
where starting not in (select week_number from clean_weekly_sales);


--3. How many purchases were made in total for each year?
--→ Count the total number of transactions for every year in the dataset.
select years, count(transactions) as transaction_count
from clean_weekly_sales
group by years;
--4. How much was sold in each region every month?
--→ Show total sales by region, broken down by month.
select region, months, sum(transactions) as total_purchase
from clean_weekly_sales
group by region, months
order by region, MONTHs

--5. How many transactions happened on each platform?
--→ Count purchases separately for the online store and the physical store.
select platform, count(sales) as purchase_count
from clean_weekly_sales
group by platform;

--6. What share of total sales came from Offline vs Online each month?
--→ Compare the percentage of monthly sales from the physical store vs. the online store.
with individual as (
select PLATFORM,months, sum(cast(sales as bigint)) as individual
from clean_weekly_sales
group by months, PLATFORM
--order by months, PLATFORM
),

total as (
select months, platform, individual,
sum(cast(individual as bigint)) over (partition by months order by months) as total_month_sum 
from individual
group by months, PLATFORM, individual
)
--select * from total
select *, (cast(individual as float) / total_month_sum) * 100
from total;


--7. What percentage of total sales came from each demographic group each year?
--→ Break down annual sales by customer demographics (e.g., age or other groupings).
with cte as (
select years, demographic, sum(cast(sales as bigint)) as individual_sales
from clean_weekly_sales
group by years, demographic
--order by years, demographic
),

sums as (
select years, demographic, individual_sales,
sum(cast(individual_sales as bigint)) over (partition by years order by years) as total_sales
from cte
group by years, demographic, individual_sales
)
select *,
((cast(individual_sales as float) / total_sales) * 100) as percentage
from sums


--8. Which age groups and demographic categories had the highest sales in physical stores?
--→ Find out which age and demographic combinations contribute most to Offline-Store sales.
select top 1 age_band, demographic, 
sum(cast(sales as bigint)) as total_sales
from clean_weekly_sales
where platform = 'offline-store' and  age_band <> 'Unknown'
group by age_band, demographic, sales
order by total_sales desc


--9. Can we use the avg_transaction column to calculate average purchase size by year and platform? If not, how should we do it?
--→ Check if the avg_transaction column gives us correct yearly average sales per transaction for Offline vs Online. If it doesn't, figure out how to calculate it manually (e.g., by dividing total sales by total transactions).
with cte as (
select years, PLATFORM ,sum(cast(sales as bigint)) as individual_sales_sum, 
sum(transactions) as individial_transaction_sum
from clean_weekly_sales
group by years, PLATFORM 
--order by years, platform
)

select *, round(cast(individual_sales_sum as float) / individial_transaction_sum, 2) as new
from cte
order by years, platform

--Pre-Change vs Post-Change Analysis

--1. What is the total sales for the 4 weeks pre and post 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with pre as (
select  years, sum(cast(sales as bigint)) as pre_sale
from clean_weekly_sales
where week_date2 between DATEADD(WEEK, -4, '2020-06-15') and '2020-06-15' and week_number != 25
group by years
),    --2,34,58,78,357     --2,91,59,03,705
post as (
select years, sum(cast(sales as bigint)) as post_sale
from clean_weekly_sales
where week_date2 between '2020-06-15'  and DATEADD(WEEK, 4, '2020-06-15') and week_number != 29
group by years
),
diff as (
select pre.years, pre_sale, post_sale , (post_sale - pre_sale) as actual_value_difference
from pre, post
group by pre.years, pre_sale, post_sale
)
--select * from diff
select *, ((cast(actual_value_difference as float)/ cast(post_sale as float)) * 100) as percentage_change
from diff;


--2. What is the total sales for the 12 weeks pre and post 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with pre as (
select  years, sum(cast(sales as bigint)) as pre_sale
from clean_weekly_sales
--where week_date2 between DATEADD(WEEK, -12, '2020-06-15') and '2020-06-15' and week_number != 25
where week_date2 between DATEADD(WEEK, -12, '2020-06-15') and DATEADD(WEEK, -1, '2020-06-15') 
group by years
--group by week_number
--order by week_number
),    --2,34,58,78,357     --2,91,59,03,705
post as (
select years, sum(cast(sales as bigint)) as post_sale
from clean_weekly_sales
where week_date2 between '2020-06-15'  and DATEADD(WEEK, 12, '2020-06-15')
group by years  
--order by week_number
),
diff as (
select pre.years, pre_sale, post_sale , (post_sale - pre_sale) as actual_value_difference
from pre, post
--from pre join post
--on pre.years = post.years
group by pre.years, pre_sale, post_sale
)
--select * from diff
select *, ((cast(actual_value_difference as float)/ cast(post_sale as float)) * 100) as percentage
from diff;


--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
with pre as (
select  years, sum(cast(sales as bigint)) as pre_sale
from clean_weekly_sales
--where week_date2 between DATEADD(WEEK, -12, '2020-06-15') and '2020-06-15' and week_number != 25
where week_date2 between DATEADD(WEEK, -12, '2020-06-15') and DATEADD(WEEK, -1, '2020-06-15') 
group by years
),   
post as (
select years, sum(cast(sales as bigint)) as post_sale
from clean_weekly_sales
where week_date2 between '2020-06-15'  and DATEADD(WEEK, 12, '2020-06-15')
group by years  
--order by week_number
),
diff as (
select pre.years, pre_sale, post_sale , (post_sale - pre_sale) as actual_value_difference
from pre, post
--from pre join post
--on pre.years = post.years
group by pre.years, pre_sale, post_sale
)
--select * from diff
select *, ((cast(actual_value_difference as float)/ cast(post_sale as float)) * 100) as percentage into #years_12_2020
from diff;


--2018

with pre as (
select  years, sum(cast(sales as bigint)) as pre_sale
from clean_weekly_sales
--where week_date2 between DATEADD(WEEK, -12, '2020-06-15') and '2020-06-15' and week_number != 25
where week_date2 between DATEADD(WEEK, -12, '2018-06-15') and DATEADD(WEEK, -1, '2018-06-15') 
group by years
--group by week_number
--order by week_number
),    --2,34,58,78,357     --2,91,59,03,705
post as (
select years, sum(cast(sales as bigint)) as post_sale
from clean_weekly_sales
where week_date2 between '2018-06-15'  and DATEADD(WEEK, 12, '2018-06-15')
group by years  
--order by week_number
),
diff as (
select pre.years, pre_sale, post_sale , (post_sale - pre_sale) as actual_value_difference
from pre, post
--from pre join post
--on pre.years = post.years
group by pre.years, pre_sale, post_sale
)
--select * from diff
select *, ((cast(actual_value_difference as float)/ cast(post_sale as float)) * 100) as percentage into #years_12_2018
from diff;

-- 2019


with pre as (
select  years, sum(cast(sales as bigint)) as pre_sale
from clean_weekly_sales
--where week_date2 between DATEADD(WEEK, -12, '2020-06-15') and '2020-06-15' and week_number != 25
where week_date2 between DATEADD(WEEK, -12, '2019-06-15') and DATEADD(WEEK, -1, '2019-06-15') 
group by years
--group by week_number
--order by week_number
),    --2,34,58,78,357     --2,91,59,03,705
post as (
select years, sum(cast(sales as bigint)) as post_sale
from clean_weekly_sales
where week_date2 between '2019-06-15'  and DATEADD(WEEK, 12, '2019-06-15')
group by years  
--order by week_number
),
diff as (
select pre.years, pre_sale, post_sale , (post_sale - pre_sale) as actual_value_difference
from pre, post
--from pre join post
--on pre.years = post.years
group by pre.years, pre_sale, post_sale
)
--select * from diff
select *, ((cast(actual_value_difference as float)/ cast(post_sale as float)) * 100) as percentage into #years_12_2019
from diff;

select * from #years_12_2018
union all
select * from #years_12_2019
union all
select * from #years_12_2020

