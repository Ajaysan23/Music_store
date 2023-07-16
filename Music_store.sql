/* using database */
use musicstore;


/*  Who is the senior most employee based on job title? */

SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1;


/*  Which countries have the most Invoices? */

SELECT COUNT(*) AS c, billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;


/*  What are top 3 values of total invoice? */

SELECT total 
FROM invoice
ORDER BY total DESC;


/*  Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT billing_city,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;


/*  Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total_spending DESC
LIMIT 1;


/*  Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


/* Method 2 */

SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, genre.name AS Name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoiceline ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;


/*  Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */


SELECT ar.artist_id, ar.name,COUNT(ar.artist_id) AS number_of_songs
FROM artist ar
JOIN album2 al ON ar.artist_id = al.artist_id
JOIN track tr ON al.album_id =tr.album_id
JOIN genre g  ON g.genre_id = tr.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY ar.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;



/*  Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;


/* Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as (
select ar.artist_id as artist_id,ar.name as artist_name ,sum(il.unit_price * il.quantity) as total_sales from
artist ar join album2 al on ar.artist_id=al.artist_id
join track tr on al.album_id=tr.album_id
join invoice_line il on tr.track_id=il.track_id
group by 1
order by 3 desc
limit 1
)

select c.customer_id,c.first_name,c.last_name,c.email ,bsa.artist_name,sum(il.unit_price * il.quantity) as amount_spent
from customer c join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track tr on tr.track_id = il.track_id
join album2 al on al.album_id = tr.album_id
join best_selling_artist bsa on bsa.artist_id=al.artist_id
group by 1,2,3,4,5
order by 6 desc;

/* We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */
with popular_genre as(
select count(il.quantity) as purchase_per_genre,c.country,g.genre_id,g.name,
row_number() over(partition by c.country order by count(il.quantity) desc) as rownum
from customer c join invoice i on c.customer_id=i.customer_id
join invoice_line il on i.invoice_id=il.invoice_id
join track tr on tr.track_id=il.track_id
join genre g on g.genre_id=tr.genre_id
group by 2,3,4
order by 2 asc,1 desc
)
select * from popular_genre where rownum<=1;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */
with customer_with_country as(
select c.customer_id,c.first_name,c.last_name,c.email,i.billing_country ,sum(total) as total_spent,
row_number() over(partition by billing_country order by sum(total) desc) as row_num
from customer c join invoice i
on c.customer_id=i.invoice_id
group by 1,2,3,4
order by 5 asc,6 desc
) 
select * from customer_with_country where row_num <=1;
