CREATE DATABASE ZOMATO;
USE ZOMATO;

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);

CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


#Questions 
#1. What is the total amount each customer spent on Zomato?

select a.userid as customer_id, sum(b.price) as amount_paid
from sales as a
left join product as b
on a.product_id = b.product_id
group by a.userid
order by a.userid;

#2. How many days has each customer visited Zomato?

select userid as customer_id, count(created_date) as number_of_visits
from sales
group by userid
order by userid;

#3. What was the first product purchased by each customer?

select a.userid as customer_id, a.created_date as date_of_first_purchase, b.product_name as product_purchased
from sales as a
left join product as b
on a.product_id = b.product_id
where (userid, created_date) in
( select userid, min(created_date)
from sales
group by userid )
order by a.userid;

#4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select b.product_name as most_purchased_product, count(*) as number_of_times_ordered
from sales as a
left join product as b
on a.product_id = b.product_id
group by b.product_name
order by number_of_times_ordered desc
limit  1;

select userid as user_id, count(product_id) as no_of_orders
from sales
where product_id =
(select product_id
from sales
group by product_id
order by count(product_id) desc
limit 1)
group by userid
order by userid;

#5. Which item the most popular for each customer?

WITH RankedSales AS (
    SELECT 
        userid, 
        product_id, 
        COUNT(product_id) AS product_count,
        ROW_NUMBER() OVER (PARTITION BY userid ORDER BY COUNT(product_id) DESC) AS sales_rank
    FROM 
        sales
    GROUP BY 
        userid, 
        product_id
)
SELECT 
    userid, 
    product_id, 
    product_count
FROM 
    RankedSales
WHERE 
    sales_rank = 1;

#6.Which item was first purchased after becoming a Gold member ?

WITH GoldMemberSales AS (
select 
a.userid,
a.created_date,
a.product_id,
b.gold_signup_date,
ROW_NUMBER() OVER (PARTITION BY a.userid order by a.created_date) AS sales_rank
from sales as a
join goldusers_signup as b
on a.userid = b.userid and a.created_date >= b.gold_signup_date)
SELECT 
    userid, 
    product_id, 
    created_date,
    gold_signup_date
FROM 
    GoldMemberSales
WHERE 
    sales_rank = 1;

#7.Which item was purchased just before customer became a member?

with GoldMemberSales as (
select 
a.userid, a.created_date,a.product_id,b.gold_signup_date,
row_number() over (partition by a.userid order by a.created_date desc) as sales_rank
from sales as a
join goldusers_signup as b
on a.userid = b.userid and created_date<=gold_signup_date )
SELECT 
    userid, 
    product_id, 
    created_date,
    gold_signup_date
FROM 
    GoldMemberSales
WHERE 
    sales_rank = 1;

#8.What is the total orders and amount spent for each member before they became a member?

select e.userid, count(e.created_date) as orders_made,sum(e.price) as total_purchase
from 
(select c.*,d.price
from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date
from sales as a
join goldusers_signup as b
on a.userid = b.userid and a.created_date<=b.gold_signup_date
order by a.userid) as c
join product as d
on c.product_id=d.product_id
order by a.userid) as e
group by e.userid
order by e.userid;

#9.If buying each product generates points for eg Rs5 for 2 points and each product has different points for eg. for p1 and p3 Rs5=1 Zomato point, for p2 Rs10=5 Zomato points
# Calculate (i) points collected by each customer and (ii) for which product most points have been given till now

select f.userid, round(sum(points_collected)* 2.5,2) as total_cashback_earned from
(select e.*, round(amt/points,2) as points_collected from
(select d.*,
case when product_id=1 then 5
	when product_id=2 then 2
    when product_id=3 then 5 else 0 end as points
    from
(select c.userid, c.product_id, sum(c.price) as amt
from 
(select a.userid, a.product_id, b.price
from sales as a
join product as b
on a.product_id=b.product_id
order by a.userid, a.product_id) as c
group by c.userid, c.product_id
order by c.userid, c.product_id) as d) as e) as f
group by f.userid;

select f.product_id, round(sum(points_collected),2) as total_points_earned from
(select e.*, round(amt/points,2) as points_collected from
(select d.*,
case when product_id=1 then 5
	when product_id=2 then 2
    when product_id=3 then 5 else 0 end as points
    from
(select c.userid, c.product_id, sum(c.price) as amt
from 
(select a.userid, a.product_id, b.price
from sales as a
join product as b
on a.product_id=b.product_id
order by a.userid, a.product_id) as c
group by c.userid, c.product_id
order by c.userid, c.product_id) as d) as e) as f
group by f.product_id
order by total_points_earned desc
limit 1;

#10.In the first one year after a customer joins the Gold program, irrespective of what they purchase, they earn 5 Zomato points for every Rs10 spent (i)Who earned more 
#(ii)What was their points earnings in the first year ?

select e.userid, round(e.amount_paid/2,2) as points_earned from
(select c.userid, d.price as amount_paid from
(select a.userid, a.created_date,a.product_id,b.gold_signup_date
from sales as a
join goldusers_signup as b
on a.userid=b.userid and created_date >=gold_signup_date and created_date<= DATE_ADD(gold_signup_date,INTERVAL 1 YEAR)
order by a.userid, a.created_date,a.product_id) as c
join product as d
on c.product_id = d.product_id
order by c.userid) as e
order by points_earned desc
limit 1; 

#11.Rank all the transactions of the customers

select userid, created_date,rank() over (partition by userid order by created_date) as Ranking
from sales;

#12. Rank all the transactions for each member whenever they are a Gold member, for every non Gold member transaction mark as NA


select c.userid, c.created_date as date_of_transaction,
case when c.gold_signup_date is null then "NA" else
rank() over (partition by c.userid order by c.created_date desc) end as Ranking
from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date
from sales as a
left join goldusers_signup as b
on a.userid=b.userid and created_date>=b.gold_signup_date
order by a.userid) as c;