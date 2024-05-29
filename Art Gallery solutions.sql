create database famous_painting;

SELECT * FROM artist;
SELECT * FROM canvas_size;
SELECT * FROM image_link;
SELECT * FROM museum;
SELECT * FROM museum_hours;
SELECT * FROM product_size;
SELECT * FROM subject;
SELECT * FROM work;


--  Identify the museums with invalid city information in the given dataset
SELECT DISTINCT  (city) FROM museum;

SELECT *  FROM museum
WHERE city NOT REGEXP '[^0-9]';


--  Fetch all the paintings which are not displayed on any museums
SELECT w.name AS painting_name, m.name AS museum_name 
FROM work AS w
LEFT JOIN museum AS m ON w.museum_id = m.museum_id
WHERE m.name IS NULL;

select count(*) from work where museum_id is null;


-- How many paintings have an asking price of more than their regular price? 
SELECT count(*) FROM product_size
WHERE regular_price < sale_price;


-- Identify the paintings whose asking price is less than 50% of its regular price
SELECT * FROM product_size
WHERE sale_price < (regular_price*0.5);


-- Which country has the 3rd highest no of paintings?
SELECT country, no_of_Paintings FROM (
SELECT m.country, COUNT(*) AS no_of_Paintings,
RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
FROM work w
JOIN museum m ON m.museum_id = w.museum_id
GROUP BY m.country) AS ranked_countries
WHERE rnk = 3;

/* Identify the artist and the museum where the most expensive and least expensive painting is placed. 
 Display the artist name, sale_price, painting name, museum name, museum city and canvas label */

WITH cte AS (
SELECT ps.*, 
RANK() OVER (ORDER BY ps.sale_price DESC) AS rnk,
RANK() OVER (ORDER BY ps.sale_price ASC) AS rnk_asc
FROM product_size ps)
SELECT w.name AS painting, cte.sale_price, a.full_name AS artist, m.name AS museum, m.city, cz.label AS canvas FROM cte
JOIN work w ON w.work_id = cte.work_id
JOIN museum m ON m.museum_id = w.museum_id
JOIN artist a ON a.artist_id = w.artist_id
JOIN canvas_size cz ON cz.size_id = CAST(cte.size_id AS UNSIGNED)
WHERE cte.rnk = 1 OR cte.rnk_asc = 1;



-- Which museum has the most no of most popular painting style?
WITH pop_style AS (
SELECT style, COUNT(*) AS style_count FROM work
GROUP BY style
ORDER BY COUNT(*) DESC
LIMIT 1),
cte AS (
SELECT w.museum_id,
m.name AS museum_name, w.style, COUNT(*) AS no_of_paintings FROM work w
JOIN museum m ON m.museum_id = w.museum_id
WHERE w.style = (SELECT style FROM pop_style)
GROUP BY w.museum_id, m.name, w.style)
SELECT museum_name, style, no_of_paintings FROM cte
ORDER BY no_of_paintings DESC
LIMIT 1;
    
-- Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

SELECT a.full_name AS artist, a.nationality, x.no_of_paintings FROM 
(SELECT a.artist_id, COUNT(*) AS no_of_paintings, 
RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk FROM work w
JOIN artist a ON a.artist_id = w.artist_id
GROUP BY a.artist_id) x
JOIN artist a ON a.artist_id = x.artist_id
WHERE x.rnk <= 5;


-- Fetch the top 10 most famous painting subject
SELECT s.subject, COUNT(*) AS no_of_paintings
FROM work w
JOIN subject s ON s.work_id = w.work_id
GROUP BY s.subject
ORDER BY COUNT(*) DESC
LIMIT 10;


-- Are there museuems without any paintings?
SELECT m.* 
FROM museum m
LEFT JOIN work w ON m.museum_id = w.museum_id
WHERE w.museum_id IS NULL;


--  How many museums are open every single day?
SELECT COUNT(*) FROM (
SELECT museum_id
FROM museum_hours
GROUP BY museum_id
HAVING COUNT(DISTINCT day) = 7
) AS open_every_day;


-- Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
SELECT a.full_name AS artist_name, a.nationality, COUNT(*) AS no_of_paintings
FROM work w
JOIN artist a ON a.artist_id = w.artist_id
JOIN subject s ON s.work_id = w.work_id
JOIN museum m ON m.museum_id = w.museum_id
WHERE s.subject = 'Portraits'AND m.country != 'USA'
GROUP BY a.artist_id, a.full_name, a.nationality
ORDER BY no_of_paintings DESC
LIMIT 2;


-- Which canva size costs the most?
SELECT cs.label AS canva, ps.sale_price
FROM product_size ps
JOIN canvas_size cs ON cs.size_id = ps.size_id
ORDER BY ps.sale_price DESC
LIMIT 1;

/* Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
If there are multiple value, seperate them with comma  */ 

SELECT 
GROUP_CONCAT(DISTINCT country) AS countries_with_most_museums,
GROUP_CONCAT(DISTINCT city) AS cities_with_most_museums FROM 
( SELECT country, COUNT(*) AS count_museums FROM museum
GROUP BY country
ORDER BY count_museums DESC
LIMIT 1) AS top_countries
JOIN (
SELECT city, COUNT(*) AS count_museums FROM museum
GROUP BY city
ORDER BY count_museums DESC
LIMIT 1) AS top_cities;


-- Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
SELECT m.name AS museum, m.city, m.country, x.no_of_paintings FROM 
( SELECT m.museum_id, COUNT(*) AS no_of_paintings FROM work w
JOIN museum m ON m.museum_id = w.museum_id
GROUP BY m.museum_id
ORDER BY no_of_paintings DESC
LIMIT 5) x
JOIN museum m ON m.museum_id = x.museum_id;



-- Identify the artists whose paintings are displayed in multiple countries
SELECT artist, COUNT(DISTINCT country) AS no_of_countries FROM 
(SELECT a.full_name AS artist, m.country FROM work w
JOIN artist a ON a.artist_id = w.artist_id
JOIN museum m ON m.museum_id = w.museum_id
GROUP BY a.full_name, m.country
) AS artist_countries
GROUP BY artist
HAVING no_of_countries > 1
ORDER BY no_of_countries DESC;

-- Which are the 3 most popular and 3 least popular painting styles?
WITH cte AS (
SELECT style, COUNT(*) AS cnt, 
ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rnk,
COUNT(*) OVER() AS no_of_records
FROM work
WHERE style IS NOT NULL
GROUP BY style)
SELECT style,
CASE 
	WHEN rnk <= 3 THEN 'Most Popular'
	WHEN rnk > no_of_records - 3 THEN 'Least Popular'
	END AS remarks
FROM cte
WHERE rnk <= 3 OR rnk > no_of_records - 3;




-- Delete duplicate records from work, product_size, subject and image_link tables
DELETE w1 FROM work w1
JOIN (
SELECT MIN(id) AS id FROM work
GROUP BY work_id) w2 
ON w1.id = w2.id
WHERE w1.id NOT IN (
SELECT MIN(id) FROM work
GROUP BY work_id
);


DELETE ps1
FROM product_size ps1
JOIN (
SELECT MIN(id) AS id FROM product_size
GROUP BY work_id, size_id) ps2 
ON ps1.id = ps2.id
WHERE ps1.id NOT IN (
SELECT MIN(id)
FROM product_size
GROUP BY work_id, size_id
);

DELETE ps1 FROM product_size ps1
JOIN (
SELECT MIN(id) AS id FROM product_size
GROUP BY work_id, size_id) ps2 ON 
ps1.id = ps2.id 
WHERE ps1.id NOT IN (
SELECT MIN(id)
FROM product_size
GROUP BY work_id, size_id
);


DELETE img_l1 FROM image_link img_l1
JOIN (
SELECT MIN(id) AS id  FROM image_link
GROUP BY work_id) img_l2 
ON img_l1.id = img_l2.id
WHERE img_l1.id NOT IN (
SELECT MIN(id)
FROM image_link
GROUP BY work_id
);





-- Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
SELECT museum_name, state AS city, day, open, close, duration FROM 
( SELECT m.name AS museum_name, m.state, mh.day, mh.open, mh.close, 
TIMEDIFF(STR_TO_DATE(mh.close, '%l:%i %p'), STR_TO_DATE(mh.open, '%l:%i %p')) AS duration,
ROW_NUMBER() OVER (ORDER BY TIMEDIFF(STR_TO_DATE(mh.close, '%l:%i %p'), STR_TO_DATE(mh.open, '%l:%i %p')) DESC) AS rnk
FROM museum_hours mh
JOIN museum m ON m.museum_id = mh.museum_id) x
WHERE x.rnk = 1;



--  Museum_Hours table has 1 invalid entry. Identify it and remove it.
DELETE FROM museum_hours 
WHERE ctid NOT IN (SELECT min(ctid) FROM museum_hours
GROUP  BY museum_id, day );


-- Display the 3 least popular canva sizes
SELECT label, no_of_paintings FROM (
SELECT cs.size_id, cs.label, COUNT(*) AS no_of_paintings,
DENSE_RANK() OVER (ORDER BY COUNT(*) ASC) AS ranking FROM work w
JOIN product_size ps ON ps.work_id = w.work_id
JOIN canvas_size cs ON cs.size_id = ps.size_id
GROUP BY cs.size_id, cs.label) x
WHERE x.ranking <= 3;


-- Identify the museums which are open on both Sunday and Monday. Display museum name, city.
SELECT DISTINCT m.name AS museum_name, m.city, m.state, m.country
FROM museum_hours mh1
JOIN museum m ON m.museum_id = mh1.museum_id
JOIN museum_hours mh2 ON mh1.museum_id = mh2.museum_id
WHERE mh1.day = 'Sunday' AND mh2.day = 'Monday';


