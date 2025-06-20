        --                    SET A
--1. How many distinct users are in the dataset?
select count(distinct user_id) as Dist_user from users;

--2. What is the average number of cookie IDs per user?
select user_id, count(cookie_id)
from users
group by user_id
order by user_id;
--OR
select cast(count(cookie_id) / count(distinct user_id)as float) from users;

--3. What is the number of unique site visits by all users per month?
select count(distinct visit_id) as count_of_unique_visit_IDs, month(event_time) as Month
from events
group by month(event_time)
order by  month(event_time);

--4. What is the count of each event type?
select event_type,count(event_type) as count_of_event_type
from events
group by event_type
order by event_type;

--5. What percentage of visits resulted in a purchase?
with total_visits as (
select count(distinct visit_id) as total_visit from events 
),

purchase as(
select count(distinct visit_id) as purchased_visit
from events
where event_type = 3 and page_id = 13
)

select (cast(purchased_visit as float)/cast(total_visit as float)) * 100 as percentage
from total_visits, purchase;


--6. What percentage of visits reached checkout but not purchase?
with checkout as (
select count(distinct visit_id) as checkout_count
from events 
where page_id = 12
),
confirmation as (
select count(distinct visit_id) as confirmation_count
from events 
where page_id = 13
),
total_visits as (
select count(distinct visit_id) as total_visit from events 
),
calc as (
select (checkout_count - confirmation_count) as minus from checkout, confirmation
)
select (cast(minus as float)/total_visit) * 100 from calc, total_visits;


--7. What are the top 3 most viewed pages?
select top 3 count(e.visit_id) as count, e.page_id, page_name 
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null 
group by e.page_id, page_name
order by count(e.visit_id) desc;

--8. What are the views and add-to-cart counts per product category?
select event_type,count(event_type) as count, product_category
from page_hierarchy join events
on page_hierarchy.page_id = events.page_id
where event_type in (1,2) and product_category is not null
group by event_type, product_category
order by event_type

-- other method
select product_category, event_type,
case
	when event_type = 1 then count(visit_id)
	when event_type = 2 then count(visit_id)
	end as count
from page_hierarchy join events
on page_hierarchy.page_id = events.page_id
where product_id is not null
group by product_category, event_type;


--9. What are the top 3 products by purchases?
with Only_purchasedvisits as (
select distinct visit_id
from events 
where event_type = 3
)
select top 3 count(distinct e.visit_id) as count, page_name 
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id in (select visit_id from Only_purchasedvisits)
group by page_name
order by count(e.visit_id) desc;

--							SET B

--10. Create a product-level funnel table with views, cart adds, abandoned carts, and purchases.
with views as (
select page_name, count(distinct visit_id) as visit_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null
group by page_name
),
--select * from views

cart_adds as (
select page_name, count(distinct visit_id) as cart_add_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null and event_type = 2
group by page_name
),

Only_purchasedvisits as (
select distinct visit_id
from events
where event_type = 3
),

abandoned_cart as (
select count(distinct e.visit_id) as abandoned_count, page_name 
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id not in (select visit_id from Only_purchasedvisits)
group by page_name
--order by count(e.visit_id) desc
),
--select * from abandoned_cart;
purchased as (
select count(distinct e.visit_id) as purchased_count, page_name 
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id in (select visit_id from Only_purchasedvisits)
group by page_name
--order by count(e.visit_id) desc
)

select v.page_name, visit_count, cart_add_count, abandoned_count, purchased_count
from views v join cart_adds
on v.page_name = cart_adds.page_name
join abandoned_cart
on abandoned_cart.page_name = cart_adds.page_name
join purchased
on purchased.page_name = abandoned_cart.page_name;



--11. Create a category-level funnel table with the same metrics as above.
with views as (
select product_category, e.page_id,count(distinct visit_id) as visit_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null
group by product_category, e.page_id
),
--select * from views

cart_adds as (
select product_category, e.page_id,count(distinct visit_id) as cart_add_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null and event_type = 2
group by product_category, e.page_id
),

Only_purchasedvisits as (
select distinct visit_id
from events
where event_type = 3
),

abandoned_cart as (
select count(distinct e.visit_id) as abandoned_count, product_category , e.page_id
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id not in (select visit_id from Only_purchasedvisits)
group by product_category, e.page_id
--order by count(e.visit_id) desc
),
--select * from abandoned_cart;
purchased as (
select count(distinct e.visit_id) as purchased_count, product_category , e.page_id
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id in (select visit_id from Only_purchasedvisits)
group by product_category, e.page_id
--order by count(e.visit_id) desc
)
--select * from purchased

select v.page_id,v.product_category, visit_count, cart_add_count, abandoned_count, purchased_count
from views v join cart_adds
on v.page_id = cart_adds.page_id
join abandoned_cart
on abandoned_cart.page_id = cart_adds.page_id
join purchased
on purchased.page_id = abandoned_cart.page_id


--12. Which product had the most views, cart adds, and purchases?
with main_cte as (
select page_name, visit_id,event_name, product_category, e.page_id, e.event_type, product_id
from page_hierarchy join events e
on e.page_id = page_hierarchy.page_id
join event_identifier
on e.event_type = event_identifier.event_type
),
max_view as (
select top 1 a.page_name as most_view --, a.product_category, count(a.visit_id) as count_a
from main_cte a
where a.event_type = 1 and a.product_id is not null 
group by a.product_category, a.page_name
order by count(visit_id) desc
),
--select * from max_view
max_cart_adds as (
select top 1 b.page_name as most_cart_adds--,b.product_category, count(b.visit_id) as count_b
from main_cte b
where b.event_type = 2 and b.product_id is not null 
group by b.product_category,b.page_name
order by count(b.visit_id) desc
),
--select * from max_cart_adds,max_view;


Only_purchasedvisits as (
select distinct visit_id
from events
where event_type = 3
),

max_purchase as (
select top 1 c.page_name as most_purchased--,c.product_category, count(c.visit_id) as count_c
from main_cte c
where  c.event_type = 2 
and c.product_id is not null 
and c.visit_id in (select c.visit_id from Only_purchasedvisits)
group by c.product_category, c.page_name
order by count(c.visit_id) desc
)
select most_view, most_cart_adds, most_purchased from max_view, max_cart_adds,max_purchase;


--13. Which product was most likely to be abandoned?
with Only_purchasedvisits as (
select distinct visit_id
from events
where event_type = 3
)
select top 1 count(distinct e.visit_id) as count, page_name 
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id not in (select visit_id from Only_purchasedvisits)
group by page_name
order by count(e.visit_id) desc



--14. Which product had the highest view-to-purchase conversion rate?
with Only_purchasedvisits as (
select distinct visit_id
from events
where event_type = 3
),
cte as (
select count(distinct e.visit_id) as product_count, page_name 
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id in (select visit_id from Only_purchasedvisits)
group by page_name
--order by count(e.visit_id) desc
),
total as (
select page_name, count(distinct visit_id) as visit_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null
group by page_name
)

select top 1 t.page_name,(cast(product_count as float)/visit_count) * 100
from cte join total t
on cte.page_name = t.page_name
order by (cast(product_count as float)/visit_count) * 100 desc


--15. What is the average conversion rate from view to cart add?
with views as (
select product_category, e.page_id,count(distinct visit_id) as visit_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null
group by product_category, e.page_id
),
--select * from views

cart_adds as (
select product_category, e.page_id,count(distinct visit_id) as cart_add_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null and event_type = 2
group by product_category, e.page_id
)

select (cast(sum(cart_add_count) as float)/sum(visit_count)) * 100
from views join cart_adds
on views.product_category = cart_adds.product_category


--16. What is the average conversion rate from cart add to purchase?
with cart_adds as (
select product_category, e.page_id,count(distinct visit_id) as cart_add_count
from page_hierarchy p join events e
on p.page_id = e.page_id
where product_id is not null and event_type = 2
group by product_category, e.page_id
),
Only_purchasedvisits as (
select distinct visit_id
from events
where event_type = 3
),
purchased as (
select count(distinct e.visit_id) as purchased_count, product_category , e.page_id
from page_hierarchy p join events e
on p.page_id = e.page_id
where event_type = 2 
and p.product_id is not null
and e.visit_id in (select visit_id from Only_purchasedvisits)
group by product_category, e.page_id
--order by count(e.visit_id) desc
)

select (cast(sum(purchased_count) as float) / sum(cart_add_count)) * 100
from purchased join cart_adds
on purchased.product_category = cart_adds.product_category;

--                       SET - C
/* Create a visit-level summary table with user_id, visit_id, 
visit start time, event counts, and campaign name.*/

create table campaign(campaign_id int, product_id int);
insert into campaign values(1, 1),
(1, 2),
(1, 3), 
(2, 4),
(2, 5),
(3, 6),
(3, 7),
(3, 8);
select * from campaign;

with cte_a as (
select visit_id, user_id , 
min(event_time) as start_time,
count(event_type) as event_count
from   events e
join users u
on e.cookie_id = u.cookie_id
group by visit_id, user_id
),
cte_b as (
select distinct visit_id, user_id, campaign_name
from events e
join users u
on e.cookie_id = u.cookie_id
join page_hierarchy p
on p.page_id = e.page_id
join campaign
on campaign.product_id = p.product_id
join campaign_identifier
on campaign_identifier.campaign_id = campaign.campaign_id
where event_time between campaign_identifier.start_date and end_date
)

select cte_a.user_id, cte_a.visit_id, event_count, campaign_name
from cte_a left join cte_b
on cte_a.user_id = cte_b.user_id and cte_a.visit_id=cte_b.visit_id
order by user_id,visit_id;


--18. (Optional) Add a column for comma-separated cart products sorted by order of addition.
with cte_a as (
select visit_id, user_id , 
min(event_time) as start_time,
count(event_type) as event_count, STRING_AGG( case when e.event_type = 2 then  p.page_name end ,' , ') as add_cards
from   events e
join users u
on e.cookie_id = u.cookie_id
join page_hierarchy p on p.page_id=e.page_id
group by visit_id, user_id
),
cte_b as (
select distinct visit_id, user_id, campaign_name
from events e
join users u
on e.cookie_id = u.cookie_id
join page_hierarchy p
on p.page_id = e.page_id
join campaign
on campaign.product_id = p.product_id
join campaign_identifier
on campaign_identifier.campaign_id = campaign.campaign_id
where event_time between campaign_identifier.start_date and end_date
)
select cte_a.user_id, cte_a.visit_id, event_count, campaign_name, add_cards
from cte_a left join cte_b
on cte_a.user_id = cte_b.user_id and cte_a.visit_id=cte_b.visit_id
order by user_id,visit_id

--          SET - D


--19. Identify users exposed to campaign impressions and compare metrics with those who were not.
with cte_a as (
select visit_id, user_id , 
min(event_time) as start_time,
count(event_type) as event_count, STRING_AGG( case when e.event_type = 2 then  p.page_name end ,' , ') as add_cards
from   events e
join users u
on e.cookie_id = u.cookie_id
join page_hierarchy p on p.page_id=e.page_id
group by visit_id, user_id
),
cte_b as (
select distinct visit_id, user_id, campaign_name
from events e
join users u
on e.cookie_id = u.cookie_id
join page_hierarchy p
on p.page_id = e.page_id
join campaign
on campaign.product_id = p.product_id
join campaign_identifier
on campaign_identifier.campaign_id = campaign.campaign_id
where event_time between campaign_identifier.start_date and end_date
),

comparison as (
select cte_a.user_id, cte_a.visit_id, event_count, campaign_name, add_cards
from cte_a left join cte_b
on cte_a.user_id = cte_b.user_id and cte_a.visit_id=cte_b.visit_id
--order by user_id,visit_id
), 
total_user as (
select count(visit_id) as total_count
from comparison
--where campaign_name is null  -- 3564, 2030, 1534
),

user_exposed as (
select count(visit_id) as user_exposed from comparison
where campaign_name is not null
),

user_not_exposed as (
select count(visit_id) as user_not_exposed from comparison
where campaign_name is null
)

select * from total_user, user_exposed, user_not_exposed

