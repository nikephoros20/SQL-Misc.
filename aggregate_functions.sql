--Number of orders in total
SELECT 
    COUNT(id) 
    FROM person_order

--Total revenue by all cafes
SELECT 
    SUM(menu.price) AS total_revenue
FROM 
    menu 
JOIN 
    person_order ON person_order.menu_id = menu.id

-- Average order price per day
WITH o_p AS (
    SELECT 
        person_order.id, 
        menu.price, 
        person_order.order_date 
    FROM 
        menu 
    JOIN 
        person_order ON menu.id = person_order.menu_id
    ORDER BY 
        person_order.id
)
SELECT 
    ROUND(AVG(price), 2) AS avg_price, order_date
FROM 
    o_p
GROUP BY 
    order_date
ORDER BY order_date;

--Maximum price of sold pizza
SELECT 
    menu.pizza_name, 
    menu.price
FROM 
    person_order 
LEFT JOIN 
    menu ON person_order.menu_id = menu.id
ORDER BY 2 DESC
LIMIT 1;

-- Revenue per day
WITH o_p AS (
    SELECT person_order.id, menu.price, person_order.order_date 
    FROM menu 
    JOIN person_order ON menu.id = person_order.menu_id
    ORDER BY person_order.id
)

SELECT 
    SUM(price) AS revenue, order_date
FROM 
    o_p
GROUP BY 
    order_date
ORDER BY order_date;

--Each pizza sold
SELECT
    m.id,
    m.pizza_name,
    COUNT(po.id) AS pizzas_sold
FROM
    menu m
LEFT JOIN
    person_order po ON po.menu_id = m.id
GROUP BY
    m.id, m.pizza_name
ORDER BY
    pizzas_sold DESC;

-- Total revenue per pizzeria
SELECT 
    pizzeria.name, 
    SUM(menu.price) as revenue 
FROM 
    menu 
JOIN 
    person_order ON menu.id = person_order.menu_id
JOIN 
    pizzeria ON pizzeria.id = menu.pizzeria_id
GROUP BY 
    pizzeria.name
ORDER BY 1 

-- The most expensive unsold pizza
SELECT 
    menu.pizza_name, 
    menu.id, menu.price
FROM 
    menu 
LEFT JOIN 
    person_order ON person_order.menu_id = menu.id
WHERE 
    person_order.menu_id IS NULL
ORDER BY 3 DESC
LIMIT 1

-- Average number of orders per person
WITH p_o AS (
    SELECT 
        person.name, 
        person.id, 
        COUNT(person_order.id) AS orders
    FROM 
        person 
    LEFT JOIN 
        person_order ON person.id = person_order.person_id
    GROUP BY person.name, person.id)
SELECT 
    ROUND(AVG(orders),2) 
FROM 
    p_o 

-- How many distinct customers has each pizzeria served?
SELECT MAX(person_id) FROM person_order

-- Which pizza has been ordered the most?
SELECT 
    menu.pizza_name, 
    menu_id, 
    COUNT(*) AS orders
FROM 
    person_order
LEFT JOIN 
    menu ON person_order.menu_id = menu.id
GROUP BY 
    pizza_name, menu_id 
ORDER BY orders DESC

-- Pizzerias with revenue above 4000
SELECT pizzeria.name, SUM(menu.price) as revenue 
FROM 
menu 
JOIN person_order 
ON menu.id = person_order.menu_id
JOIN pizzeria
ON pizzeria.id = menu.pizzeria_id
GROUP BY pizzeria.name
HAVING SUM(menu.price) > 4000
ORDER BY 1

-- Clients with more than 2 orders
SELECT person.name, COUNT(person_order.id) AS orders
FROM person 
JOIN person_order
ON person_order.person_id = person.id
GROUP BY person.name
HAVING COUNT(person_order.id) > 2
ORDER BY 2 DESC

-- Average revenue per order for each client
SELECT person.name, ROUND(AVG(menu.price),2)
FROM person 
JOIN person_order 
ON person.id = person_order.person_id
JOIN menu 
ON menu.id = person_order.menu_id
GROUP BY person.name
ORDER BY 1

-- How many orders are placed per day?
SELECT order_date, COUNT(id) 
FROM person_order
GROUP BY order_date
ORDER BY order_date

-- How many orders are placed per month?
SELECT date_trunc('month',order_date) AS interval, COUNT(*) 
FROM person_order
GROUP BY interval
ORDER BY interval

-- How many orders are placed per week?
SELECT date_trunc('week',order_date) AS interval, COUNT(*) 
FROM person_order
GROUP BY interval
ORDER BY interval

-- How much revenue is made on Sundays?
WITH revenue_per_day AS (
  SELECT 
    order_date, 
    SUM(menu.price) AS revenue
  FROM person_order 
  JOIN menu ON person_order.menu_id = menu.id
  GROUP BY order_date
)

SELECT 
  ROUND(AVG(revenue), 2) AS avg_sunday_revenue
FROM revenue_per_day
--WHERE TRIM(TO_CHAR(order_date, 'Day')) = 'Sunday';
WHERE TO_CHAR(order_date, 'Day') ILIKE 'Sunday%'

-- Average income per every week day
WITH revenue_per_day AS (
  SELECT 
    order_date, 
    SUM(menu.price) AS revenue
  FROM person_order 
  JOIN menu ON person_order.menu_id = menu.id
  GROUP BY order_date
)
SELECT TO_CHAR(order_date, 'Day'),
ROUND(AVG(revenue))
FROM revenue_per_day
GROUP BY TO_CHAR(order_date, 'Day')
ORDER BY
MIN(EXTRACT(DOW FROM order_date))

-- Average revenue per weekend day
WITH all_dates AS(
SELECT generate_series((SELECT MIN(order_date) FROM person_order), (SELECT MAX(order_date) FROM person_order), interval '1 day')::date
AS the_dates),

all_weekends AS(
  SELECT the_dates FROM all_dates 
  WHERE EXTRACT(DOW FROM the_dates) = 0
  OR  EXTRACT(DOW FROM the_dates) = 6
),

weekend_revenue AS (
  SELECT SUM(menu.price) FROM person_order
  LEFT JOIN menu 
  ON menu.id = person_order.menu_id
  WHERE EXTRACT(DOW FROM order_date) = 0 
  OR EXTRACT(DOW FROM order_date) = 6
)

SELECT 
ROUND(
  (SELECT * FROM weekend_revenue) * 1.0 / 
  (SELECT COUNT(*) FROM all_weekends),2) AS avg_revenue;

-- Who on average spends the most on weekends?
WITH all_dates AS(
SELECT generate_series((SELECT MIN(order_date) FROM person_order), (SELECT MAX(order_date) FROM person_order), interval '1 day')::date
AS the_dates),

weekends_num AS(
  SELECT COUNT(the_dates) FROM all_dates 
  WHERE EXTRACT(DOW FROM the_dates) = 0
  OR  EXTRACT(DOW FROM the_dates) = 6
),

all_rev AS(
    SELECT 
        person_order.person_id AS id, 
        SUM(menu.price) AS revenue
    FROM 
        person_order
    LEFT JOIN 
        menu 
    ON 
        person_order.menu_id = menu.id
    WHERE 
        EXTRACT(DOW FROM order_date) = 0
    OR  EXTRACT(DOW FROM order_date) = 6
    GROUP BY person_order.person_id)

SELECT 
    person.name, 
    all_rev.id, 
    ROUND((SELECT all_rev.revenue * 1.0)/(SELECT* FROM weekends_num),2) AS avg_revenue 
FROM 
    all_rev
LEFT JOIN 
    person
ON 
    all_rev.id = person.id
ORDER BY 3 DESC
LIMIT 1

-- Every person's average spendings in every pizzeria
SELECT 
    person.name, 
    pizzeria.name, 
    ROUND(AVG(menu.price),2) AS avg_spent 
FROM 
    person_order 
LEFT JOIN 
    menu
ON 
    person_order.menu_id = menu.id
LEFT JOIN
    person
ON
    person.id = person_order.person_id
LEFT JOIN
    pizzeria
ON
    pizzeria.id = menu.pizzeria_id
GROUP BY 
    person.name, 
    pizzeria.name
ORDER BY 1 

--The most popular pizzas
SELECT 
    m.pizza_name, 
    COUNT(po.id)
FROM 
    person_order AS po
LEFT JOIN  
    menu AS m ON m.id = po.menu_id
GROUP BY
    m.pizza_name
ORDER BY 2 DESC
