
--A. High Level Sales Analysis

--1. What was the total quantity sold for all products?**
select d.product_id, count(s.qty) as total_quantity_sold, d.product_name
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.product_id, d.product_name;

--2. What is the total generated revenue for all products before discounts?**
select d.product_id, sum(s.qty * s.price) as total_revenue_before_discount, d.product_name
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.product_id, d.product_name;

--3. What was the total discount amount for all products?**
select d.product_id, sum(discount) as total_discount_amount, d.product_name
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.product_id, d.product_name;

--B. Transaction Analysis

--1. How many unique transactions were there?**
select count(distinct txn_id) as total_unique_count
from sales;

--2. What is the average unique products purchased in each transaction?**

--3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?**
select txn_id ,percent_rank()over(partition by txn_id order by (qty * price)) as ranking
from sales

--4. What is the average discount value per transaction?**
select txn_id, avg(discount) as avg_discount_per_transaction
from sales
group by txn_id;


--5. What is the percentage split of all transactions for members vs non-members?**
with cte as (
select count(txn_id) as total
from sales
),

member_cte as (
select count(txn_id) as member_count
from sales
where member = 1
)

select (member_count * 100) / cast(total as float) as member_percentage,
100 - (member_count * 100) / cast(total as float) as non_member_percentage
from cte, member_cte;

--6. What is the average revenue for member transactions and non-member transactions?**
with avg_mem_rev as (
select avg(qty * price) as avg_member_revenue
from sales
where member = 1
),

avg_non_mem_rev as (
select avg(qty * price) as avg_non_member_revenue
from sales
where member = 0
)

select avg_member_revenue, avg_non_member_revenue from avg_mem_rev, avg_non_mem_rev;

--C. Product Analysis

--1. What are the top 3 products by total revenue before discount?**
select top 3 d.product_id, sum(s.qty * s.price) as total_revenue_before_discount, d.product_name
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.product_id, d.product_name;

--2. What is the total quantity, revenue and discount for each segment?
select d.segment_name, count(s.qty) as total_quantity, sum(s.qty * s.price) as revenue, sum(discount) as total_discount
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.segment_name;

--3. What is the top selling product for each segment?**
with cte as (
select d.product_name,d.segment_name , count(s.qty) as product_quantity,
row_number() over(partition by d.segment_name order by count(s.qty)) as ranking
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.product_name, d.segment_name, s.qty   --3782
)

select * from cte 
where ranking = 1 
order by product_quantity desc

--4. What is the total quantity, revenue and discount for each category?**
select d.category_name, count(s.qty) as total_quantity, sum(s.qty * s.price) as revenue, sum(discount) as total_discount
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.category_name;

--5. What is the top selling product for each category?**
with cte as (
select d.product_name,d.category_name , count(s.qty) as product_quantity,
row_number() over(partition by d.category_name order by count(s.qty)) as ranking
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.product_name, d.category_name, s.qty   --3782
)

select * from cte 
where ranking = 1 
order by product_quantity desc;

--6. What is the percentage split of revenue by product for each segment?**
with cte as (
select d.segment_name, d.product_name, count(s.qty) as product_qty
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.segment_name, d.product_name
--order by segment_name
),

total as (
select 
*
,sum(product_qty) over(partition by segment_name) as total_sum
from cte
)

select *,round((product_qty * 100) / cast(total_sum as float), 2) as percentage_split from total;


--7. What is the percentage split of revenue by segment for each category?**
with cte as (
select d.category_name, d.segment_name, count(s.qty) as product_qty
from sales s left join product_details d
on s.prod_id = d.product_id
group by d.category_name, d.segment_name
--order by segment_name
),

total as (
select *, 
sum(product_qty) over(partition by category_name) as total_sum
from cte
)

select *,
round((product_qty * 100) / cast(total_sum as float), 2) as percentage_split from total;



--8. What is the percentage split of total revenue by category?**  --575333, 714120
with cte as (
select category_name, sum(qty * s.price) as Individual_revenue
from sales s left join product_details d
on s.prod_id = d.product_id
group by category_name
),

t as (
select *, sum(Individual_revenue)over() as total_revenue
from cte
)
select *, round((Individual_revenue * 100) / cast(total_revenue as float), 2) as percentage_split from t;


--9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)**
with cte as (
select prod_id ,product_name,count(txn_id) as penetration_txn_count
from sales s left join product_details d
on s.prod_id = d.product_id
where qty >= 1
group by product_name, prod_id
), 
total as (
select prod_id ,count(txn_id) as total_txn_count
from sales 
group by prod_id
)

select product_name,(penetration_txn_count / sum(total_txn_count)) as penetration
from cte join total
on cte.prod_id = total.prod_id
group by product_name, penetration_txn_count;




-------------------------


with cte as (
select product_name,count(txn_id) as penetration_txn_count
from sales s left join product_details d
on s.prod_id = d.product_id
where qty >= 1
group by product_name
),

t as (
select *, sum(penetration_txn_count)over() as total_txn
from cte
)

select *, round((penetration_txn_count * 100) / cast(total_txn as float), 2) as penetraion from t;


--10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?**
with cte as (
select distinct product_name, txn_id, qty
from sales s left join product_details d
on s.prod_id = d.product_id
where qty >= 1
--order by txn_id
)

/*select *, count(product_name)over(partition by txn_id, product_name ) 
from cte*/

select product_name, count(product_name)
from cte
group by product_name

