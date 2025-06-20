
--1. Which movies from each genre are considered the most critically acclaimed based on their ratings?
with cte as (
select m.movie_id, m.title, m.genre, r.score,
rank() over(partition by m.genre order by r.score desc) as ranking
from Movies m inner join Reviews r
on m.movie_id = r.movie_id
)
select movie_id, title ,genre, score from cte 
where ranking = 1;


--2. Can you find the top 3 movies with the highest audience appreciation, regardless of genre?
select top 3 m.movie_id, m.title, m.rating
from Movies m
order by m.rating desc;     

--other method 
with cte as (
select m.movie_id, m.title, m.rating,
rank() over(order by m.rating desc) as ranked
from Movies m
)
select movie_id, title, rating, ranked from cte
where ranked < 4;


--3. Within each release year, which movies performed the best in terms of domestic revenue?
with cte as (
select m.movie_id, m.title, m.release_year , b.domestic_gross,
rank() over(partition by m.release_year order by b.domestic_gross desc) as ranking
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id
)

select movie_id, title, release_year, domestic_gross, ranking from cte
where ranking = 1
order by domestic_gross desc;

--4. Are there any movies within the same genre that have an equal standing when it comes to international box office collections?
select 
    m.genre,
    b.international_gross
from movies m
join boxoffice b on m.movie_id = b.movie_id
group by m.genre, b.international_gross
having count(*) > 1;



--5. What are the best-rated movies in each genre according to critics?
with cte as (
select  m.movie_id, m.title, m.genre ,r.score,
rank() over(partition by m.genre order by r.score) as ranked
from Movies m  inner join Reviews r
on m.movie_id = r.movie_id
)

select movie_id, title, genre ,score, ranked from cte
where ranked = 1;

--6. How can we divide the movies into four equal groups based on their domestic earnings?
--select max(domestic_gross) from BoxOffice;

--19,00,00,000

select m.movie_id, m.title, b.domestic_gross,
case 
	when b.domestic_gross <= 190000000 then 'Group A'
	when b.domestic_gross > 190000000 and b.domestic_gross <= 380000000 then 'Group B'
	when b.domestic_gross > 380000000 and b.domestic_gross <= 570000000 then 'Group C'
	when b.domestic_gross > 570000000 and b.domestic_gross <= 760000000 then 'Group D'    --else group D if we dont want to set limit
	end as Groups
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id

--other method using NTILE()

select m.movie_id, m.title, b.domestic_gross,
ntile(4) over(order by b.domestic_gross desc) as category
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id

--7. Can we group movies into three distinct categories according to their international revenue?
--select max(international_gross) from BoxOffice;
--680,000,000
select m.movie_id, m.title, b.international_gross,
case 
	when b.international_gross <= 680000000 then 'Group A'
	when b.international_gross > 680000000 and b.international_gross <= 1360000000 then 'Group B'
	else 'Group C'
	end as Groups
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id

--other method 
--680,000,000
select m.movie_id, m.title, b.international_gross,
ntile(3) over(order by b.international_gross desc) as category
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id

--8. How would you classify movies based on how they rank in terms of audience rating?
select  m.movie_id, m.title, m.genre ,r.score,
dense_rank() over(order by r.score desc) as ranked
from Movies m  inner join Reviews r
on m.movie_id = r.movie_id 

--other method 
select  m.movie_id, m.title, m.genre ,r.score
from Movies m  inner join Reviews r
on m.movie_id = r.movie_id 
order by r.score desc

--9. If we split the actors based on the number of movies they've acted in, how many groups would we have if we only had two categories?
-- categorie (single, Multiple)
with cte as (
select a.actor_id, a.name, count(m.movie_id) as movie_count,
case
	when count(m.movie_id) = 1 then 'Single Movie'
	when count(m.movie_id) > 1 then 'Multiple Movies'
	end as Category
from Actors a inner join MovieActors ma
on a.actor_id = ma.actor_id
inner join Movies m
on m.movie_id = ma.movie_id
group by a.actor_id, a.name
)
select actor_id, name, movie_count, Category from cte



--another method using NTILE()
select a.actor_id, a.name, count(m.movie_id) as movie_count,
ntile(2) over(order by a.actor_id) as groups
from Actors a inner join MovieActors ma
on a.actor_id = ma.actor_id
inner join Movies m
on m.movie_id = ma.movie_id
group by a.actor_id, a.name

--10. Can we divide the movies into ten segments based on their total box office performance?

--No we cannot 
select m.movie_id, m.title, b.domestic_gross, b.international_gross, (b.domestic_gross + b.international_gross) as box_office,
ntile(10) over(order by (b.domestic_gross + b.international_gross) desc) as categories
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id


--11. How would you determine the relative position of each movie based on its critic score?
select m.movie_id, m.title, r.score,
PERCENT_RANK() over(order by r.score desc) as percent_rank
from Movies m inner join Reviews r
on m.movie_id = r.movie_id

--12. If we look at the movies within a specific genre, how would you find their relative success in terms of domestic box office collection?
select m.movie_id, m.title, b.domestic_gross,
percent_rank() over( order by b.domestic_gross desc) as ranking
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id
where m.genre = 'sci-fi';

--13. Considering the movies from the same year, can you identify how well each one did in terms of overall revenue?

--can also done using where clause (specify year)
select m.movie_id, m.title, m.release_year,(b.domestic_gross + b.international_gross) as overall_revenue,
percent_rank() over(partition by m.release_year order by (b.domestic_gross + b.international_gross) desc) as ranking
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id


--14. How would you place actors on a timeline based on their birth years, showing how they compare to one another?
select a.actor_id, a.name, a.birth_year, 
percent_rank() over(order by a.birth_year) as ranking
from Actors a 

--15. What is the relative standing of each movie's rating within its genre?
select m.movie_id, m.title, m.rating,
PERCENT_RANK() over(partition by m.genre order by m.rating desc) as ranked
from Movies m 

--16. Can you determine how movies from the same genre compare to one another in terms of ratings?  add more movies for same genre
select m.movie_id, m.title, m.rating,
PERCENT_RANK() over(partition by m.genre order by m.rating desc) as ranked
from Movies m 

--17. How do the movies from each release year compare to one another when we look at international revenue?
select m.movie_id, m.title, m.release_year, b.international_gross,
percent_rank() over(partition by m.release_year order by b.international_gross desc) as ranked
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id

--18. Among all movies, how would you rate them based on the number of actors they feature?
select m.movie_id, m.title, count(a.actor_id) as actor_count,
dense_rank() over(order by count(a.actor_id) desc) as rating       --can use row_number()
from Movies m inner join MovieActors ma
on m.movie_id = ma.movie_id
inner join Actors a
on a.actor_id = ma.actor_id
group by  m.movie_id, m.title  

--19. Which critics tend to give higher ratings compared to others, and how do they rank?
select r.review_id, r.critic_name, r.score,
round(PERCENT_RANK() over (order by r.score desc), 2) as p_rank
from Reviews r

--20. How does each movie fare when comparing their total box office income to others?
select m.movie_id, m.title, sum(b.domestic_gross + b.international_gross) as total_box_office,
PERCENT_RANK() over(order by sum(b.domestic_gross + b.international_gross) desc ) as ranking
from Reviews r inner join Movies m
inner join BoxOffice b
on m.movie_id  = b.movie_id
on m.movie_id = r.movie_id
group by m.movie_id, m.title;

--21. What are the differences in the way movies are ranked when you consider audience ratings versus the number of awards won?


--22. Can you list the movies that consistently rank high both in domestic gross and in audience appreciation?
with cte as (select m.movie_id, m.title, b.domestic_gross,
rank() over(order by b.domestic_gross desc) as domestic_gross_rank
from Reviews r inner join BoxOffice b
on r.movie_id = b.movie_id
inner join Movies m
on m.movie_id = b.movie_id
),

cte2 as (
select m.movie_id, m.title, r.score,
rank() over(order by r.score) as audience_score
from Movies m inner join Reviews r
on m.movie_id = r.movie_id
)

select * from cte join cte2
on cte.movie_id = cte2.movie_id
--where cte.domestic_gross < 4 and cte2.audience_score < 4;

--23. What would the movie list look like if we grouped them by their performance within their release year?



--24. Can we find the top movies from each genre, while also displaying how they compare in terms of critical reception and revenue distribution?
with cte as (
select m.movie_id, m.title, m.genre, sum(b.domestic_gross + b.international_gross) as total_revenue,
rank() over(partition by m.genre order by sum(b.domestic_gross + b.international_gross) desc) as ranking
from Movies m inner join BoxOffice b
on m.movie_id = b.movie_id
group by m.movie_id, m.title, m.genre
)

select movie_id, title, genre, total_revenue from cte
where ranking =1;


--25. If you were to group actors based on the number of movies they've been in, how would you categorize them?
select a.actor_id, a.name, count(m.movie_id) as movie_count,
case
	when count(m.movie_id) = 1 then 'Single Movie'
	when count(m.movie_id) > 1 then 'Multiple Movies'
	end as Category
from Actors a inner join MovieActors ma
on a.actor_id = ma.actor_id
inner join Movies m
on m.movie_id = ma.movie_id
group by a.actor_id, a.name