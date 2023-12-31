-- Music store database analysis questions

-- 1. Who is the senior most employee based on job title?
SELECT CONCAT(first_name, " ", last_name) AS Name, title, levels
FROM employee
ORDER BY levels DESC
LIMIT 1;


-- 2. Which countries have the most invoices?
SELECT billing_country, COUNT(billing_country) AS No_of_invoices
FROM invoice
GROUP BY billing_country
ORDER BY No_of_invoices DESC, billing_country;


-- 3. What are top 3 values of total invoice?
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;


-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made
-- the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.

SELECT billing_city, ROUND(SUM(total), 2) AS Total_Sum
FROM invoice
GROUP BY billing_city
ORDER BY Total_Sum DESC
LIMIT 1;


-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query
-- that returns the person who has spent the most money.

SELECT c.customer_id, c.first_name, c.last_name, CONCAT(c.first_name, " ", c.last_name) AS Name_of_Customer, ROUND(SUM(i.total), 2) AS Total_money_spent
FROM customer c
INNER JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY  Total_money_spent DESC
LIMIT 1;


-- Intermediate --
-- 6. Write a query to return the email, first name & last name of all Rock music listeners. Return your list ordered
-- alphabetically by email starting with A.

SELECT DISTINCT(c.email), c.first_name, c.last_name
FROM customer c
     JOIN invoice i 
		ON c.customer_id = i.customer_id
	JOIN invoice_line iline 
		ON i.invoice_id = iline.invoice_id
WHERE track_id IN (SELECT track_id
				   FROM track2 t
                   JOIN genre g 
                   ON t.genre_id = g.genre_id
                   WHERE g.name LIKE '%RocK%')
ORDER BY c.email;

-- Method 2
SELECT DISTINCT(c.email), c.first_name, c.last_name, g.name
FROM customer c
JOIN invoice i 
	ON c.customer_id = i.customer_id
JOIN invoice_line iline 
	ON i.invoice_id = iline.invoice_id
JOIN track2 t
	ON iline.track_id = t.track_id
JOIN genre g 
	ON t.genre_id = g.genre_id
WHERE g.name LIKE '%RocK%'
ORDER BY c.email;


-- 7. Lets invite the artists who have written the most rock music in our dataset. Write a query that returns the artist name
-- and total track count of the top 10 rock bands.

SELECT art.artist_id, art.name, COUNT(art.artist_id) AS No_of_songs
FROM artist art
JOIN album2 alb
	ON art.artist_id = alb.artist_id
JOIN track2 t
	ON alb.album_id = t.album_id
JOIN genre g
	ON t.genre_id = g.genre_id
WHERE g.name LIKE "%Rock%"
GROUP BY art.artist_id
ORDER BY No_of_songs DESC
LIMIT 10;


-- 8. Return all the track names that have a song length longer than the average song length.
-- Return the name and milliseconds for each track. Order by the song length with the longest songs listed first.

SELECT name, milliseconds
FROM track2
WHERE milliseconds > (SELECT AVG(milliseconds)
					  FROM track2)
ORDER BY milliseconds DESC;


-- Advanced --
-- 9 Find how much amount spent by each customer on artists? Write a query to return customer name, artist name & total spent.

WITH best_selling_artist AS (
	SELECT art.artist_id AS Artist_ID,  art.name AS Artist_Name,
			SUM(iline.unit_price * iline.quantity) AS Total_Sales
    FROM invoice_line iline
    JOIN track2 t
		ON iline.track_id = t.track_id
	JOIN album2 alb
		ON t.album_id = alb.album_id
	JOIN artist art
		ON alb.artist_id = art.artist_id
GROUP BY Artist_ID
ORDER BY Total_Sales DESC
LIMIT 2
)

SELECT c.customer_id , c.first_name, c.last_name, bsa.Artist_Name, SUM(iline.unit_price * iline.quantity) AS total
FROM invoice inv
JOIN customer c
	ON c.customer_id = inv.customer_id
JOIN invoice_line iline
	ON inv.invoice_id = iline.invoice_id
JOIN track2 t
	ON iline.track_id = t.track_id
JOIN album2 alb
	ON t.album_id = alb.album_id
JOIN best_selling_artist bsa
	ON alb.artist_id = bsa.artist_id
GROUP BY c.customer_id, 4, 2
ORDER BY 5 DESC;


-- 10. We want to find out the most popular music Genre for each country. Weetermine the popular genre as the genre with the highest
-- amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of
-- purchases is shared return all Genres.

WITH popular_genre AS (
SELECT COUNT(iline.quantity) AS purchases, c.country, g.name, g.genre_id,
ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(iline.quantity) DESC) AS Popularity
FROM invoice_line iline
JOIN invoice inv
	ON inv.invoice_id = iline.invoice_id
JOIN customer c
	ON c.customer_id = inv.customer_id
JOIN track2 t
	ON iline.track_id = t.track_id
JOIN genre g
	ON t.genre_id = g.genre_id
GROUP BY 2, 3
ORDER BY 2 ASC, 1 DESC
)

SELECT *
FROM popular_genre
WHERE Popularity <= 1;


-- 11. Write a query that determines the customer that has spent the most on music for each country. Write a query
-- that returns the country along with the top customer and how much they spent. For countries where the top amount
-- spent is shared, provide all customers who spent this amount.

WITH customer_country AS (
	SELECT c.customer_id, c.first_name, c.last_name, c.country, SUM(i.total) AS total_spent,
		ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(i.total) DESC) AS RowNo
    FROM customer c
    JOIN invoice i
		ON c.customer_id = i.customer_id
	GROUP BY 1, 2
    ORDER BY 5 DESC, 4)
    
SELECT * FROM customer_country
WHERE RowNo = 1;