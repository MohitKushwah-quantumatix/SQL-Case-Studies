
  --1. How many pizzas were ordered?
select count(pizza_id) as number_of_pizza_ordered from customer_orders;

--2. How many unique customer orders were made?
select count( distinct customer_id) as unique_customers from customer_orders;

--3. How many successful orders were delivered by each rider?
select count(order_id) as Order_count, rider_id from rider_orders
where cancellation is null
group by rider_id;


--4. How many of each type of pizza was delivered?
select count(c.pizza_id) as total_count, p.pizza_name from customer_orders c 
inner join pizza_names p on c.pizza_id = p.pizza_id
inner join rider_orders r
on r.order_id = c.order_id
where r.cancellation is null or r.cancellation = ''
group by c.pizza_id,p.pizza_name;

--5. How many 'Paneer Tikka' and 'Veggie Delight' pizzas were ordered by each customer?
select c.customer_id, p.pizza_name ,count(c.pizza_id) as order_quantity 
from customer_orders c inner join pizza_names p
on c.pizza_id = p.pizza_id
group by c.customer_id, c.pizza_id, p.pizza_name;

--6. What was the maximum number of pizzas delivered in a single order?
select r.order_id, count(c.pizza_id) as max_num_of_pizza_per_order
from customer_orders c inner join rider_orders r
on c.order_id = r.order_id
where r.cancellation is null or r.cancellation = ''
group by r.order_id;

--7. For each customer, how many delivered pizzas had at least 1 change (extras or exclusions) and how many had no changes?
select customer_id, exclusions, extras,
case
	when (c.extras is not null) then 'Changed'
	when (c.exclusions = '') or (c.extras = '') then 'No Change'
		else 'No Change'
	end as change_or_not
from customer_orders c inner join rider_orders r
on c.order_id = r.order_id	
--where r.cancellation is not null or r.cancellation = ''
order by customer_id

--8. How many pizzas were delivered that had both exclusions and extras?
select c.pizza_id, c.order_id, count(c.pizza_id) as count_having_both_exclusion_and_extras
from customer_orders c inner join rider_orders r
on c.order_id = r.order_id
where (c.exclusions is not null and c.exclusions != '') and (c.extras is not null and c.extras != '')
group by c.pizza_id, c.order_id, r.cancellation
having r.cancellation is null or r.cancellation = ''

--9. What was the total volume of pizzas ordered for each hour of the day?
select format(order_time, 'HH') as time_in_hours,
count(pizza_id) as volume_of_pizza_ordered
from customer_orders 
group by format(order_time, 'HH')
order by format(order_time, 'HH') asc;


--10. What was the volume of orders for each day of the week?
select datepart(WEEKDAY, order_time) as day_number, count(order_id) as order_count
from customer_orders
group by datepart(WEEKDAY, order_time)
order by datepart(WEEKDAY, order_time) asc;

--11. How many riders signed up for each 1-week period starting from 2023-01-01?
with cte as (
select datediff(week, '2023-01-01' ,registration_date) + 1 AS week_number, count(rider_id) as rider_count
 from riders
 --where registration_date >= '2023-01-01'
 group by datediff(week, '2023-01-01' , registration_date) + 1
 )

 select week_number, rider_count from cte 
 where week_number = 1

 --12. What was the average time in minutes it took for each rider to arrive at Pizza Delivery HQ to pick up the order?
 select r.rider_id, avg(DATEDIFF(MINUTE,c.order_time, r.pickup_time)) as avg_time
 from rider_orders r inner join customer_orders c
 on c.order_id = r.order_id
 group by rider_id

 --13. Is there any relationship between the number of pizzas in an order and how long it takes to prepare?
 select c.order_id, count(pizza_id) as count_per_order, DATEDIFF(MINUTE,c.order_time, r.pickup_time) as prepare_time
 from rider_orders r inner join customer_orders c
 on c.order_id = r.order_id
 group by c.order_id, c.order_time, r.pickup_time

 -- 1 pizza takes around 10 min to prepare

 --14. What was the average distance traveled for each customer?
select replace(distance, 'km', '')
from rider_orders;
 
 with cte as (
 select c.customer_id, avg(cast(replace(r.distance, 'km', '') as float)) as new_distance
 from customer_orders c inner join rider_orders r 
 on c.order_id = r.order_id
 group by c.customer_id, r.distance
)
select customer_id, avg(new_distance) as avg_distance_travelled_in_KM from cte 
group by cte.customer_id;

--15. What was the difference between the longest and shortest delivery durations across all orders?
select max(cast(left(duration, 2) as int)) as max_duration,  min(cast(left(duration, 2) as int)) as min_duration,
max(cast(left(duration, 2) as int)) - min(cast(left(duration, 2) as int)) as difference
from rider_orders;

--16. What was the average speed (in km/h) for each rider per delivery? Do you notice any trends?
with cte as(
select rider_id, cast(replace(distance, 'km', '') as float) as new_distance,
round((cast(left(duration, 2) as float)/60), 2) as new_duration_in_hours
-- speed = dist / time
from rider_orders
),

/*select rider_id, sum(new_distance)/sum(new_duration_in_hours) as speed_in_km from cte
group by rider_id;*/

cte2 as (
select rider_id,new_distance, new_duration_in_hours,
round((new_distance / new_duration_in_hours), 2) as speed_in_km_per_hr
from cte
where new_distance is not null and new_duration_in_hours is not null
group by rider_id, new_distance, new_duration_in_hours
)

select  cte2.rider_id,avg(cte2.speed_in_km_per_hr) as avg_speed
from cte inner join cte2
on cte.rider_id = cte2.rider_id
group by cte2.rider_id;


--17. What is the successful delivery percentage for each rider?
with cte as (
select rider_id, count(rider_id) as successful_orders
from rider_orders
where cancellation is null or cancellation = ''
group by rider_id
),
cte2 as (
select rider_id, count(rider_id) as total_orders
from rider_orders
group by rider_id
)

select (cast(successful_orders as float) / cast(total_orders as float)) * 100
from cte2 inner join cte 
on cte2.rider_id = cte.rider_id

--18. What are the standard ingredients for each pizza?
with cte as (
select pizza_id, value as topping_id2
from pizza_recipes 
cross apply string_split(toppings, ',')
),

cte2 as (
select pizza_id, topping_id, topping_name
from cte inner join pizza_toppings
on cte.topping_id2 = pizza_toppings.topping_id
),
cte3 as (
select cte2.pizza_id, cte2.topping_id ,cte2.topping_name -- string_agg(cte2.topping_name, ',') as aggrigate
from cte inner join cte2
on cte.pizza_id = cte2.pizza_id
group by cte2.pizza_id, cte2.topping_id ,cte2.topping_name
)

select cte3.pizza_id, string_agg(cte3.topping_name, ',') as aggrigate
from cte3
group by pizza_id;

---------------------------FUNCTIONS FOR PRE-PROCESSING------------------------------------------
/*

string_agg() function
string_split()
try_cast()
cross apply()
CharIndex - for substring matching
PatIndex - for pattern matching
*/
------------------------------------------------------------------------------------------------------------------------


--19. What was the most commonly added extra (e.g., Mint Mayo, Corn)?
with cte as (
select c.order_id, c.extras, r.toppings 
from customer_orders c inner join pizza_recipes r
on c.pizza_id  = r.pizza_id
where c.extras is not null and c.extras != ' ' 
),
cte2 as (
select cte.order_id, value as extras
from cte 
cross apply string_split(cte.extras, ',') as splitted
)
select top 1 count(*) as extra_count, t.topping_name
from cte join cte2 on cte.order_id = cte2.order_id
inner join pizza_toppings t
on t.topping_id = trim(cte2.extras)
group by t.topping_name
order by extra_count desc;


--20. What was the most common exclusion (e.g., Cheese, Onions)?
with cte as (
select c.order_id, c.exclusions, r.toppings 
from customer_orders c inner join pizza_recipes r
on c.pizza_id  = r.pizza_id
where c.exclusions is not null and c.exclusions != ' ' 
),
cte2 as (
select cte.order_id, value as exclusions
from cte 
cross apply string_split(cte.exclusions, ',') as splitted
)
select  count(*) as exclusion_count, t.topping_name
from cte join cte2 on cte.order_id = cte2.order_id
inner join pizza_toppings t
on t.topping_id = trim(cte2.exclusions)
group by t.topping_name
order by exclusion_count desc;


--21. Generate an order item for each record in the `customer_orders` table in the format:
/*
    * Paneer Tikka
    * Paneer Tikka - Exclude Corn
    * Paneer Tikka - Extra Cheese
    * Veggie Delight - Exclude Onions, Cheese - Extra Corn, Mushrooms
*/

with cte as (
select row_number() over(order by c.order_id) as Row_Number,
c.order_id, c.pizza_id, c.exclusions, c.extras
from customer_orders c
),

cte2 as (
select cte.Row_Number ,  try_cast(value as int) as extras
from cte
cross apply string_split(extras, ',')
where extras<>''
),
--select * from cte2;

cte3 as (
select cte.Row_Number ,  try_cast(value as int) as exclusions
from cte
cross apply string_split(exclusions, ',')
where exclusions<>''
),
--select * from cte3;

cte4 as ( -- exclusion
select cte3.row_number, exclusions, topping_name
from cte3 inner join pizza_toppings
on cte3.exclusions = pizza_toppings.topping_id
)
select * from cte4;

,cte5 as (
select cte2.row_number, extras, topping_name
from cte2 inner join pizza_toppings
on cte2.extras = pizza_toppings.topping_id
)
--select * from cte5;

select cte.row_number, cte.pizza_id,
case 
	when cte5.extras is not null and cte5.extras != '' then cte5.topping_name
	when cte4.exclusions is not null and cte4.exclusions != '' then cte4.topping_name
end as final
from cte left join cte4
on cte.Row_Number = cte4.Row_Number
left join cte5
on cte.Row_Number = cte5.Row_Number;











--22. Generate an alphabetically ordered, comma-separated ingredient list for each pizza order, using "2x" for duplicates.

  --  * Example: "Paneer Tikka: 2xCheese, Corn, Mushrooms, Schezwan Sauce"


--23. What is the total quantity of each topping used in all successfully delivered pizzas, sorted by most used first?



--24. If a 'Paneer Tikka' pizza costs 300 and a 'Veggie Delight' costs 250 (no extra charges), how much revenue has Pizza Delivery India generated (excluding cancellations)?
with cte as(
select c.pizza_id, n.pizza_name,count(c.pizza_id) as count_of_pizza,
case
when c.pizza_id = 1 then count(c.pizza_id) * 300
when c.pizza_id = 2 then count(c.pizza_id) * 250
end as revenue
from customer_orders c inner join rider_orders r
on c.order_id = r.order_id
inner join pizza_names n
on n.pizza_id = c.pizza_id
group by c.pizza_id, pizza_name
)

select pizza_id, pizza_name, count_of_pizza, revenue,
sum(revenue) over() as total_revenue
from cte
group by pizza_id, pizza_name, count_of_pizza, revenue


--25. What if there’s an additional ₹20 charge for each extra topping?

--26. Cheese costs ₹20 extra — apply this specifically where Cheese is added as an extra.


--27. Design a new table for customer ratings of riders. Include:

CREATE TABLE rider_ratings (
      rating_id INT IDENTITY PRIMARY KEY,
      order_id INT,
      customer_id INT,
      rider_id INT,
      rating INT CHECK (rating BETWEEN 1 AND 5),
      comments NVARCHAR(255),
      rated_on DATETIME
    );



--30. If Paneer Tikka is ₹300, Veggie Delight ₹250, and each rider is paid ₹2.50/km, what is Pizza Delivery India's profit after paying riders?

