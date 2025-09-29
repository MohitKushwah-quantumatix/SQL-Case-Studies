--Q1.

select category, count(category) as number_of_bikes
from bike
group by category
having count(category) > 2;

--Q2. 

select name, count(m.membership_type_id) as membership_count
from customer c left join membership m
on c.id = m.customer_id
group by name
order by count(m.membership_type_id) desc;

--Q3. 
with cte as (
select id, category, price_per_hour, 
case when category = 'electric' then price_per_hour * 0.10
when category = 'mountain bike' then price_per_hour * 0.20
else price_per_hour * 0.50
end as discount_hour_price ,

price_per_day,
case when category = 'electric' then price_per_day * 0.20
when category = 'mountain bike' then price_per_day * 0.50
else price_per_day * 0.50
end as discount_day_price 
from bike
)

select id, category, price_per_hour as old_price_per_hour, (price_per_hour - discount_hour_price) as new_price_per_hour,
price_per_day as old_price_per_day, (price_per_day - discount_day_price) as new_price_per_day
from cte


--Q4. 

select category, 
case when status = 'available' then count(status) end as available_bikes_count,
case when status = 'rented' then count(status) end as rented_bikes_count
from bike
group by category, status


--Q5. 

select year(start_timestamp) as year ,month(start_timestamp) as month , sum(total_paid) as revenue
from rental
group by month(start_timestamp),  year(start_timestamp)


--Q6. 

select year(start_date) as year, month(start_date) as month, t.name as membership_type_name, sum(total_paid) as total_revenue
from membership m join membership_type t
on m.membership_type_id = t.id
group by year(start_date),month(start_date),t.name
order by year(start_date), month(start_date), t.name


--Q7. 

select  t.name as membership_type_name, month(start_date) as month, sum(total_paid) as total_revenue
from membership m join membership_type t
on m.membership_type_id = t.id
group by month(start_date),t.name
order by t.name,month(start_date)


--Q8. 

select 
    rental_count_category,
    count(*) as customer_count
from (
    select 
        case 
            when count(*) > 10 then 'more than 10'
            when count(*) between 5 and 10 then 'between 5 and 10'
            when count(*) < 5 then 'fewer than 5'
        end as rental_count_category
    from rental
    group by customer_id
) segments
group by rental_count_category
order by 
    case rental_count_category
        when 'more than 10' then 1
        when 'between 5 and 10' then 2
        when 'fewer than 5' then 3
    end;
