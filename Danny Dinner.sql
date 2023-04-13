-- Table Creation Script

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

--Solutions for Case Study Questions  

--Q1. What is the total amount each customer spent at the restaurant?
--Method 1:

    select sum(me.price) as Total_amount_spent,s.Customer_id  from sales s 
   join  menu me on me.product_id=s.product_id
  group by s.customer_id

--Method 2:

  select customer_id, sum(price) as spent_amount from (select customer_id, price from sales s join
  menu m on s.product_id=m.product_id) x group by customer_id;
--------------------------------------------------- 

--Q2. How many days has each customer visited the restaurant?
select customer_id,count(distinct (order_date)) as visit_count from sales group by customer_id

--------------------------------------------------- 

--Q3. What was the first item from the menu purchased by each customer?

--Method1:
select s.customer_id,me.product_name,min(order_date) from sales s join
menu me on s.product_id=me.product_id
group by s.customer_id,me.product_name
having min(order_date)='2021-01-01'

--Method2:
  with t1 as
  (
select s.customer_id,me.product_name,s.order_date,dense_rank() over (partition by s.customer_id order by s.order_date)rnk from sales s join
menu me on s.product_id=me.product_id
)

select Product_name,customer_id from t1 where rnk=1
group by Product_name,customer_id

select distinct(Product_name),customer_id from t1 where rnk=1

--------------------------------------------------- 

--Q4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select TOP 1 (count(me.product_id)) as most_purchased,
product_name 
from sales s 
join menu me on s.product_id=me.product_id
group by me.product_id,me.product_name
order by most_purchased desc

--------------------------------------------------- 

--Q5. Which item was the most popular for each customer?

with t1 as
(
select count(me.product_id) as order_count,dense_rank()over(partition by customer_id order by count(me.product_id) desc) rnk,
product_name,customer_id
from sales s 
join menu me on s.product_id=me.product_id
group by me.product_id,me.product_name,customer_id
)
select customer_id,product_name,order_count from t1 where rnk=1

  select * from members
  select * from menu
  select * from sales

--------------------------------------------------- 

--Q6. Which item was purchased first by the customer after they became a member?

with customer_purchase_after_member as
  (
  select s.customer_id,me.product_name,s.order_date,m.join_date,
   dense_rank() over(partition by s.customer_id order by s.order_date)rnk from members m
   join sales s on s.customer_id=m.customer_id
   join menu me on me.product_id=s.product_id
   where s.order_date>=m.join_date
   )
   select * from customer_purchase_after_member where rnk=1
   
--------------------------------------------------- 
   
--Q7. Which item was purchased just before the customer became a member?

with purchased_just_before_member as
(
select s.customer_id,me.product_name,s.order_date,m.join_date,
   dense_rank() over(partition by s.customer_id order by s.order_date desc)rnk from members m
   join sales s on s.customer_id=m.customer_id
   join menu me on me.product_id=s.product_id
   where s.order_date<m.join_date
   )
   select * from purchased_just_before_member where rnk=1
   
 --------------------------------------------------- 

 --Q8. What is the total items and amount spent for each member before they became a member?

   select sum(me.price) as total_price,count(distinct s.product_id) as number_of_items,s.customer_id from members m
   join sales s on s.customer_id=m.customer_id
   join menu me on me.product_id=s.product_id
   where s.order_date<m.join_date
   group by s.customer_id
   
 --------------------------------------------------- 

  --Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer hav

   WITH price_points_cte AS
(
	SELECT *, 
		CASE WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10 END AS points
	FROM menu
)


select sales.customer_id,sum(points) as total_points from price_points_cte join sales 
on price_points_cte.product_id=sales.product_id
group by sales.customer_id

--------------------------------------------------- 

--Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
how many points do customer A and B have at the end of January?

WITH dates_cte AS 
(
	SELECT 
    *, 
    DATEADD(DAY, 6, join_date) AS valid_date, 
		EOMONTH('2021-01-31') AS last_date
	FROM members AS m
)

SELECT 
  d.customer_id, 
  s.order_date, 
  d.join_date, 
  d.valid_date, 
  d.last_date, 
  m.product_name, 
  m.price,
	SUM( 
    CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
		WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
		ELSE 10 * m.price END) AS points
FROM dates_cte AS d
JOIN sales AS s
	ON d.customer_id = s.customer_id
JOIN menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price

--------------------------------------------------- 
