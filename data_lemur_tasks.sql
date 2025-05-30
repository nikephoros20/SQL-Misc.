-- Write a query to obtain the third transaction of every user.
WITH rs AS(
   SELECT
      user_id,
      spend,
      transaction_date,
      ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY transaction_date ASC) AS rank
      FROM transactions
      ORDER BY transaction_date ASC
      
)
SELECT user_id, spend, transaction_date FROM rs
WHERE rank = 3
-- Your manager is keen on understanding the pay distribution and asks you to determine the second highest salary among all employees.
SELECT 
   NTH_VALUE(salary, 2) OVER(ORDER BY salary DESC
   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS second_highest_salary
FROM employee
LIMIT 1
-- Write a query to obtain a breakdown of the time spent sending vs. opening snaps as a percentage of total time spent on these activities grouped by age group. Round the percentage to 2 decimal places in the output.
--  time spent sending / (Time spent sending + Time spent opening)
--  Time spent opening / (Time spent sending + Time spent opening)

WITH ot AS(
   SELECT
      user_id,
      SUM(time_spent) AS t
   FROM activities
   WHERE activity_type = 'open'
   GROUP BY user_id) ,
st AS(
   SELECT
      user_id,
      SUM(time_spent) AS t
   FROM activities
   WHERE activity_type = 'send'
   GROUP BY user_id)

SELECT
   age_breakdown.age_bucket,
   ROUND((st.t::decimal / (st.t + ot.t))  * 100.00, 2),
   ROUND((ot.t::decimal / (st.t + ot.t))  * 100.00, 2)


FROM
   ot JOIN st 
ON 
   ot.user_id = st.user_id
JOIN 
   age_breakdown
ON 
   age_breakdown.user_id = st.user_id

ORDER BY 1 ASC
-- Output the user ID, tweet date, and rolling averages rounded to 2 decimal places
SELECT 
   user_id,
   tweet_date,
   ROUND(AVG(tweet_count) OVER(PARTITION BY user_id ORDER BY tweet_date 
   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2)
FROM tweets
ORDER BY 1, 2 ASC
-- Write a query to identify the top two highest-grossing products within each category in the year 2022. The output should include the category, product, and total spend.
with ts AS (
SELECT 
   category,
   product,
   SUM(spend) AS total_spent,
   ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(spend) DESC) AS rank
FROM product_spend
WHERE transaction_date >= '01-01-2022' AND transaction_date < '01-01-2023'
GROUP BY product, category
ORDER BY 1,3 DESC)

SELECT 
   category,
   product,
   total_spent
FROM ts
WHERE rank = 1 OR rank = 2
ORDER BY 1 ASC, 3 DESC
-- You're tasked with identifying these high earners across all departments. Write a query to display the employee's name along with their department name and salary.
-- employee's name along with their department name and salary. In case of duplicates, sort the results of department name in ascending order, then by salary in descending order. If multiple employees have the same salary, then order them alphabetically.
-- department, name, salary
--1st table - employee
WITH rs AS(
SELECT 
   department_name AS department,
   name,
   salary,
   DENSE_RANK() OVER(PARTITION BY department_name ORDER BY salary DESC) AS rank
FROM employee LEFT JOIN department
ON employee.department_id = department.department_id)

SELECT
   department,
   name,
   salary
FROM rs
WHERE rank = 1 OR rank = 2 OR rank = 3
ORDER BY 1 ASC, 3 DESC, 2 ASC
-- A senior analyst is interested to know the activation rate of specified users in the emails table. Write a query to find the activation rate. Round the percentage to 2 decimal places.
--Confirmations divide by signups
-- emails = signups (one user - one row)
-- texts = emails and actions

SELECT 
   ROUND(COUNT(signup_action)::DECIMAL/COUNT(*),2)
FROM
   emails LEFT JOIN texts
ON 
   emails.email_id = texts.email_id
AND 
   texts.signup_action = 'Confirmed'
-- A Microsoft Azure Supercloud customer is defined as a customer who has purchased at least one product from every product category listed in the products table.
-- Write a query that identifies the customer IDs of these Supercloud customers.
WITH gen_inf AS (
   SELECT 
      customer_id, products.product_id, product_category
   FROM 
      products
   INNER JOIN customer_contracts ON customer_contracts.product_id = products.product_id
   ORDER BY 1
),
sec_step AS (
SELECT
   customer_id,
   COUNT(DISTINCT product_category) AS counted
FROM
   gen_inf
GROUP BY
   customer_id
HAVING
   COUNT(DISTINCT product_category) >= 3

)
SELECT customer_id FROM sec_step
-- Write a query to calculate the sum of odd-numbered and even-numbered measurements separately for a particular day and display the results in two different columns
-- divide odd and even
WITH emun AS(
SELECT 
   MOD(ROW_NUMBER() OVER(PARTITION BY    measurement_time::date
 ORDER BY measurement_id ASC),2) AS num,
   measurement_value AS val,
   measurement_time::date AS span
FROM measurements)

SELECT
DATE(span) AS measurement_date,
   SUM(CASE WHEN num = 1 THEN val ELSE 0 END) AS odd_sum,
   SUM(CASE WHEN num = 0 THEN val ELSE 0 END) AS even_sum
   FROM
   emun
GROUP BY(measurement_date)
ORDER BY 1
