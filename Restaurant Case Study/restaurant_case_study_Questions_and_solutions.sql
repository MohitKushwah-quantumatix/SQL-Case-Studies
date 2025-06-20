-- 1. Total amount spent by each customer
select distinct customer_id, 
sum(price) over(partition by customer_id) as total_spent_by_customer
from Sales inner join menu
on sales.product_id = menu.product_id;


-- 2. Number of distinct visit days per customer
select customer_id,
count(distinct order_date) as Num_of_distinct_visit
from sales
group by customer_id;
/*select customer_id,
count( order_date) as Num_of_visit
from sales
group by customer_id;*/

-- 3. First item purchased by each customer
with item_purchased as (
select distinct product_name, customer_id, order_date,
row_number() over(PARTITION BY customer_id ORDER BY order_date) as ranked
from sales inner join menu
on menu.product_id = sales.product_id
 )
 select product_name, customer_id, order_date from item_purchased
 where ranked = 1
 order by customer_id;



-- 4. Most purchased item and count
select top 1 m.product_name, count(m.product_id) as count
from sales as s inner join menu as m
on m.product_id = s.product_id
group by m.product_name
order by count desc;


-- 5. Most popular item per customer

with popular_item as (
select   product_name, s.customer_id ,count(m.product_id) as p_count,
rank() over(PARTITION BY customer_id ORDER BY count(s.product_id)desc) as ranked
from sales s inner join menu m
on m.product_id = s.product_id
group by product_name, customer_id
)
 select product_name, pp.customer_id, pp.p_count from popular_item as pp
 where ranked = 1;


-- 6. First item after becoming a member
with after_member as (
select product_name, s.customer_id, s.product_id, s.order_date,
ROW_NUMBER() over(partition by s.customer_id order by s.order_date asc) as number
from sales s inner join menu m
on m.product_id = s.product_id
inner join members x
on s.customer_id = x.customer_id
where s.order_date >= x.join_date
group by product_name, s.customer_id, s.product_id, s.order_date
)
select pp.product_name, pp.product_id, pp.customer_id, pp.order_date from after_member as pp
where number = 1;


-- 7. Last item before becoming a member
with after_member as (
select product_name, s.customer_id, s.product_id, s.order_date,
ROW_NUMBER() over(partition by s.customer_id order by s.order_date desc) as number
from sales s inner join menu m
on m.product_id = s.product_id
inner join members x
on s.customer_id = x.customer_id
where s.order_date < x.join_date
group by product_name, s.customer_id, s.product_id, s.order_date
)
select pp.product_name, pp.product_id, pp.customer_id, pp.order_date from after_member as pp
where number = 1;


-- 8. Items and amount before becoming a member
with after_member as (
select product_name, s.customer_id, s.product_id, s.order_date, m.price
--ROW_NUMBER() over(partition by s.customer_id order by s.order_date desc) as number
from sales s inner join menu m
on m.product_id = s.product_id
inner join members x
on s.customer_id = x.customer_id
where s.order_date < x.join_date
group by product_name, s.customer_id, s.product_id, s.order_date, m.price
)
select pp.product_name, pp.product_id, pp.customer_id, pp.order_date, pp.price from after_member as pp
--where number = 1;



-- 9. Loyalty points: 2x for biryani, 1x for others
select s.customer_id, m.product_name,    --, s.order_date
case m.product_name
when 'biryani' then '2X'
else '1X' end as Loyalty_Points
from sales s inner join menu m
on m.product_id = s.product_id

-- 10. Points during first 7 days after joining
select s.customer_id, m.product_name, s.order_date, x.join_date,
case m.product_name
when 'biryani' then '2X'
else '1X' end as Loyalty_Points
from sales s inner join menu m
on m.product_id = s.product_id
inner join members x
on s.customer_id = x.customer_id
where  s.order_date between x.join_date and dateadd(DAY, 7, x.join_date) 
group by s.customer_id, m.product_name, s.order_date, x.join_date;


-- 11. Total spent on biryani
select m.product_name, count(s.product_id) as p_count, m.price,
sum(m.price) as total_spent
from sales s inner join menu m
on m.product_id = s.product_id
where m.product_name = 'biryani'
group by m.price, m.product_name;

-- 12. Customer with most dosai orders
with most_dosai as (
select s.customer_id, m.product_name, count(s.product_id) as per_product_count
--rank() over(partition by s.customer_id order by count(s.product_id) desc) as max_dosai
from sales s inner join menu m
on m.product_id = s.product_id
where m.product_name = 'dosai'
group by  s.customer_id, m.product_name
--order by s.customer_id
)

select  pp.customer_id, pp.product_name, pp.per_product_count from most_dosai as pp
where per_product_count = (select max(per_product_count) from most_dosai);

--another method

with most_dosai as (
select s.customer_id, m.product_name, count(s.product_id) as per_product_count,
rank() over(order by count(s.product_id) desc) as max_dosai
from sales s inner join menu m
on m.product_id = s.product_id
where m.product_name = 'dosai'
group by  s.customer_id, m.product_name
--order by s.customer_id
)

select  pp.customer_id, pp.product_name, pp.per_product_count from most_dosai as pp
where pp.max_dosai = 1;

-- 13. Average spend per visit

-- 14. Day with most orders in Jan 2025
with most_orders as (
select s.order_date, count(s.product_id) as order_count,  
rank() over( order by count(s.product_id) desc) as ranking
from sales s inner join menu m
on m.product_id = s.product_id  
where year(s.order_date) = 2025 and month(s.order_date) = 1
group by s.order_date
)

select pp.order_date, order_count from most_orders as pp
where ranking = 1 ;


-- 15. Customer who spent the least
with cte as (
select s.customer_id, count(m.product_id) as total_orders, sum(m.price) as total
from sales s inner join menu m
on m.product_id = s.product_id 
group by s.customer_id
)
select pp.customer_id, total from cte as pp
where total = (select min(total) from cte);


-- 16. Date with most money spent
with cte as (
select s.order_date, count(m.product_id) as total_orders, sum(m.price) as total
from sales s inner join menu m
on m.product_id = s.product_id 
group by s.order_date
)

select pp.order_date, total from cte as pp
where total = (select max(total) from cte);

-- 17. Customers with multiple orders on same day

select s.customer_id, s.order_date,count(s.product_id) as order_count
from sales s
group by s.customer_id,s.order_date
having count(s.product_id) > 1;

-- 18. Visits after membership
select s.customer_id, x.join_date, s.order_date,
count(s.product_id)over(partition by s.customer_id) as total_visit
from sales s inner join members x
on s.customer_id = x.customer_id
where s.order_date > x.join_date;


-- 19. Items never ordered
with cte as (
select s.customer_id, s.product_id, m.product_name,
count(s.product_id)over(partition by s.customer_id) as total_count
from sales s inner join menu m
on s.product_id = m.product_id
)

select pp.customer_id, total_count from cte as pp
where total_count = (select count(*) from cte where total_count < 0 );

-- 20. Customers who ordered but never joined
