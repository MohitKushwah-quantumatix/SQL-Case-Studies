
--1. How many unique customers have ever signed up with Foodflix?
select count( distinct customer_id) as distinct_customers from subscriptions;

--another method
select distinct customer_id as distinct_customers from subscriptions order by customer_id;

--2. What is the monthly distribution of trial plan start dates in the dataset?
select datename(Month, start_date) as Month_name, count(s.customer_id) as customer_count
from subscriptions s inner join plans p                                                        -- cum_dist, running, rolling, percentile, quaterly, half-yearly
on p.plan_id = s.plan_id
where p.plan_id = 0
group by datename(Month, start_date);

--3. Which plan start dates occur after 2020?
select p.plan_id, p.plan_name, s.start_date
from subscriptions s left join plans p
on p.plan_id = s.plan_id 
where YEAR(s.start_date) > 2020
order by plan_id, plan_name;

--4. What is the total number and percentage of customers who have churned?
with cte as (
select count(s.customer_id) as total_customer_churn
from subscriptions s 
where s.plan_id = 4                                                   --active customer on the basis of plans
),

cte2 as (
select  count(distinct s.customer_id) as total_customer_id
from subscriptions s
)

select cte.total_customer_churn, ((cast(cte.total_customer_churn as float) / cast(cte2.total_customer_id as float)) * 100) as percentage_of_customer_churn from cte, cte2;


--active customer on the basis of plans
with cte as (
select p.plan_id, p.plan_name, count(s.customer_id) as total_customer_churn
from subscriptions s left join plans p
on p.plan_id = s.plan_id
where p.plan_id = 4
group by p.plan_id, p.plan_name
)







--5. How many customers churned immediately after their free trial?
with cte as (
	select s.customer_id, p.plan_name,
	lead(p.plan_name) over(partition by s.customer_id order by s.start_date) as next_plan
	from subscriptions as s join plans as p
	on s.plan_id = p.plan_id
	)
select count(customer_id) as churned_count from cte
where plan_name = 'trial' and next_plan = 'churn';

--6. What is the count and percentage of customers who transitioned to a paid plan after their initial trial?
with cte as (
	select s.customer_id, p.plan_name,
	lead(p.plan_name) over(partition by s.customer_id order by s.start_date) as next_plan
	from subscriptions as s left join plans as p 
	on s.plan_id = p.plan_id 
	),

	cte2 as (
	select count(distinct s.customer_id) as total_customers 
	from subscriptions s
	)

select count(cte.customer_id) as transitioned_count, 
((cast(count(cte.customer_id) as float) / cast(cte2.total_customers as float)) * 100) as transitioned_percetage from cte, cte2
where plan_name = 'trial' and next_plan in ('basic monthly' , 'pro monthly', 'pro annual')   ---can also use 'next_plan is not null'
group by cte2.total_customers;    -- avoid IN and use EXIST/NOT EXIST it is a best practice


--7. As of 2020-12-31, what is the count and percentage of customers in each of the 5 plan types?
WITH latest_plan AS (
    SELECT
        s.customer_id,
        s.plan_id,
        s.start_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.start_date DESC) AS rn
    FROM subscriptions s
    WHERE s.start_date <= '2020-12-31'
)

SELECT 
    p.plan_name,
    COUNT(lp.customer_id) AS customer_count,
    ROUND(100.0 * COUNT(lp.customer_id) / SUM(COUNT(lp.customer_id)) OVER (), 2) AS percentage
FROM latest_plan lp
JOIN plans p ON lp.plan_id = p.plan_id
WHERE lp.rn = 1
GROUP BY p.plan_name
ORDER BY customer_count DESC;



--8. How many customers upgraded to an annual plan during the year 2020?
with cte as (
	select s.customer_id, p.plan_name,
	lead(p.plan_name) over(partition by s.customer_id order by s.start_date) as next_plan
	from subscriptions as s join plans as p 
	on s.plan_id = p.plan_id 
	where year(s.start_date) <= '2020'
)

select count(customer_id) as customer_count, plan_name as current_plan, next_plan
from cte
where plan_name in ('trial', 'basic monthly', 'pro monthly') and next_plan = 'pro annual'
group by cte.plan_name, cte.next_plan;

--9. On average, how many days does it take for a customer to upgrade to an annual plan from their sign-up date?

with cte as (
select s.customer_id, s.start_date as starting_date
	from subscriptions as s join plans as p 
	on s.plan_id = p.plan_id 
	where p.plan_id = 0
),

cte2 as (
select s.customer_id, s.start_date as annual_sub_date
	from subscriptions as s join plans as p 
	on s.plan_id = p.plan_id 
	where p.plan_id = 3
)

select avg(datediff(day, cte.starting_date, cte2.annual_sub_date)) as avg_diff
from cte inner join cte2
on cte.customer_id = cte2.customer_id;



/*with cte as (
	select s.start_date as start_date, p.plan_name,
	lead(p.plan_name) over(partition by s.customer_id order by s.start_date) as next_plan
	from subscriptions as s join plans as p 
	on s.plan_id = p.plan_id 
),
cte2 as (
	select s.start_date as annual_date , p.plan_name
	from subscriptions as s join plans as p 
	on s.plan_id = p.plan_id 
	where p.plan_id = 3
)

select count(datediff(DAY, cte.start_date, cte2.annual_date)) as date_diff, cte.plan_name as current_plan, next_plan
from cte, cte2
where cte.plan_name in ('trial', 'basic monthly', 'pro monthly') and next_plan = 'pro annual'
group by cte.plan_name, cte.next_plan, cte.start_date, cte2.annual_date;
*/

--10. Can you break down the average days to upgrade to an annual plan into 30-day intervals?

WITH first_subscription AS (
    SELECT
        customer_id,
        MIN(start_date) AS first_sub_date
    FROM subscriptions
    GROUP BY customer_id
),

-- Step 2: Get each customer's first upgrade to the annual plan (plan_id = 3)
first_annual_upgrade AS (
    SELECT
        customer_id,
        MIN(start_date) AS annual_upgrade_date
    FROM subscriptions
    WHERE plan_id = 3
    GROUP BY customer_id
),

-- Step 3: Combine both to compute days to upgrade
upgrade_diff AS (
    SELECT
        fa.customer_id,
        DATEDIFF(DAY, fs.first_sub_date, fa.annual_upgrade_date) AS days_to_upgrade
    FROM first_subscription fs
    JOIN first_annual_upgrade fa ON fs.customer_id = fa.customer_id
)

-- Step 4: Group customers into 30-day buckets
SELECT
    CONCAT(
        FLOOR(days_to_upgrade / 30) * 30, 
        '-', 
        (FLOOR(days_to_upgrade / 30) + 1) * 30 - 1, 
        ' days'
    ) AS upgrade_interval,
    COUNT(*) AS customer_count,
    ROUND(AVG(CAST(days_to_upgrade AS FLOAT)), 1) AS avg_days_to_upgrade
FROM upgrade_diff
GROUP BY FLOOR(days_to_upgrade / 30)
ORDER BY FLOOR(days_to_upgrade / 30);



--11. How many customers downgraded from a Pro Monthly to a Basic Monthly plan in 2020?
with cte as (
	select s.customer_id, p.plan_name,
	lead(p.plan_name) over(partition by s.customer_id order by s.start_date) as next_plan
	from subscriptions as s join plans as p 
	on s.plan_id = p.plan_id 
	where year(s.start_date) <= 2020
)

select count(customer_id) as count_customer
from cte
where plan_name = 'pro monthly' and next_plan = 'basic monthly';








/*Challenge – Payments Table for Foodflix (2020)

The Foodflix team would like you to generate a payments table for the year 2020 that reflects actual payment activity. The logic should include:

* Monthly payments are charged on the same day of the month as the start date of the plan.
* Upgrades from Basic to Pro plans are charged immediately, with the upgrade cost reduced by the amount already paid in that month.
* Upgrades from Pro Monthly to Pro Annual are charged at the end of the current monthly billing cycle, and the new plan starts at the end of that cycle.
* Once a customer churns, no further payments are made.

Example output rows for the payments table could include:
("customer_id", "plan_id", "plan_name", "payment_date", "amount", "payment_order")
*/

create table payments(
payment_id int primary key,
customer_id int, 
plan_id int, 
plan_name varchar(50), 
payment_date date, 
amount float, 
payment_order int
);


WITH customer_details AS(
SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date AS payment_date,
LEAD(s.start_date,1,'2020-12-31') OVER(PARTITION BY s.customer_id ORDER BY s.customer_id) AS next_date, 
p.price AS amount
FROM subscriptions AS s
inner join plans AS p
ON s.plan_id = p.plan_id
WHERE s.plan_id != 0 AND s.start_date <= '2020-12-31'),
--select * from customer_details;
 
-- recusrsivly har payment ko genrate karwa rhe he
 
recursive_months AS (
SELECT customer_id, plan_id, plan_name,LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY plan_id,payment_date) AS next_id, payment_date, next_date,amount FROM customer_details
 
UNION ALL
 
SELECT customer_id, plan_id, plan_name,next_id, DATEADD(MONTH,1,payment_date) , next_date, amount FROM recursive_months
WHERE DATEADD(MONTH,1,payment_date) < next_date AND (plan_id != 3 and plan_id !=4)
),
 
---amount calculation kar rhe he
monthly_sub AS(
SELECT customer_id, plan_id,plan_name, next_id, MAX(payment_date) AS payment_date ,next_date, 
(amount/30)*DATEDIFF(DAY,MAX(payment_date),next_date) AS sub_amount 
FROM recursive_months
WHERE plan_id = 1 AND next_id in (2,3)
GROUP BY customer_id,plan_id, next_id, next_date, plan_name,amount
),
 
-- sab ke sath deff amount join kar rhe he--
final AS(
SELECT r.customer_id, r.plan_id, r.plan_name, r.payment_date, r.amount, ISNULL(m.sub_amount,0) AS sub_amount FROM recursive_months AS r
LEFT JOIN monthly_sub AS m
ON r.customer_id = m.customer_id and r.plan_id = m.next_id)
 
-- final query
SELECT customer_id, plan_id, plan_name, payment_date,
	CASE
		WHEN plan_id = 1 THEN amount
		WHEN plan_id = 2 and lag(plan_id) OVER(PARTITION BY customer_id ORDER BY customer_id,plan_id,payment_date) = 1 THEN amount-sub_amount
		WHEN plan_id = 2 THEN amount	 
		WHEN plan_id = 3 and lag(plan_id) OVER(PARTITION BY customer_id ORDER BY customer_id,plan_id,payment_date) = 1 THEN amount-sub_amount
		WHEN plan_id = 3 THEN amount
	END AS amount,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY customer_id) AS payment_order
	FROM final
	WHERE plan_id != 4
	ORDER BY customer_id,plan_id,payment_date;
