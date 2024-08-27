-- 01.How many pizzas were ordered?
select count(order_time) order_count
,pizza_name 
from customer_orders 
join pizza_names using(pizza_id) 
group by 2;

select count(*) from customer_orders

-- 02.How many unique customer orders were made?
SELECT count(distinct customer_id) unique_orders 
FROM pizza_runner.customer_orders;



-- 03.How many successful orders were delivered by each runner?
select runner_id
,count(*) as Delivery_successfull 
from runner_orders 
where cancellation  NOT IN ("Restaurant cancellation","Customer cancellation") 
group by runner_id;


-- 04.How many of each type of pizza was delivered?
SELECT 
    pizza_id, COUNT(pizza_name) AS Pizza_type_delivered
FROM
    runner_orders
        JOIN
    customer_orders USING (order_id)
        JOIN
    pizza_names USING (pizza_id)
WHERE
    cancellation NOT IN ('restaurant cancellation' , 'customer cancellation')
GROUP BY pizza_id;


-- 05.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    pizza_name, customer_id, COUNT(*) AS pizza_count
FROM
    pizza_names
        JOIN
    customer_orders USING (pizza_id)
WHERE
    pizza_name IN ('meatlovers' , 'vegetarian')
GROUP BY customer_id , pizza_name;



-- 06.What was the maximum number of pizzas delivered in a single order?
SELECT 
    MAX(pizza_num) AS max_ordered
FROM
    (SELECT 
        order_id, COUNT(pizza_id) AS pizza_num
    FROM
        customer_orders
    JOIN runner_orders USING (order_id)
    JOIN pizza_names USING (pizza_id)
    WHERE
        cancellation NOT IN ('Restaurant cancellation' , 'customer cancellation')
    GROUP BY order_id) AS order_counts;

-- 07.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    customer_id,
    SUM(CASE
        WHEN exclusions IS NULL THEN 1
        ELSE 0
    END) AS pizza_with_no_changes,
    SUM(CASE
        WHEN exclusions IS NOT NULL THEN 1
        ELSE 0
    END) AS pizza_with_changes
FROM
    customer_orders
        JOIN
    runner_orders USING (order_id)
WHERE
    cancellation NOT IN ('restaurant cancellation' , 'Customer cancellation')
GROUP BY customer_id;



-- 08.How many pizzas were delivered that had both exclusions and extras?
SELECT 
    COUNT(pizza_id)
FROM
    customer_orders
WHERE
    exclusions IS NOT NULL
        AND exclusions != ''
        AND extras IS NOT NULL
        AND extras != '';


-- 09.What was the total volume of pizzas ordered for each hour of the day?
SELECT 
    COUNT(pizza_id), HOUR(order_time) order_hour
FROM
    customer_orders
GROUP BY (order_time)
ORDER BY order_hour;

-- 10.What was the volume of orders for each day of the week?
SELECT 
    DAYNAME((order_time)) AS week_day, COUNT(pizza_id) volume
FROM
    customer_orders
GROUP BY week_day
ORDER BY week_day;



-- 11.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    DATE_FORMAT(registration_date, '%u') + 1 AS week_starting,
    COUNT(runner_id) AS runners_signed_up
FROM
    runners
GROUP BY DATE_FORMAT(registration_date, '%u') + 1
ORDER BY week_starting;


-- 12.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT 
    ROUND(AVG(TIMESTAMPDIFF(MINUTE,
                order_time,
                pickup_time)),
            0) AS avg_time_to_pickup_inMinutes,
    runner_id
FROM
    runner_orders
        JOIN
    customer_orders USING (order_id)
GROUP BY runner_id;


-- 13.Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH pizza_prep_time AS (
    SELECT 
        order_id,
        TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS prep_time,
        COUNT(pizza_id) AS pizza_nums
    FROM 
        runner_orders 
    JOIN 
        customer_orders USING(order_id)
    GROUP BY 
        order_id
)
SELECT 
    AVG(prep_time) AS avg_prep_time,
    pizza_nums
FROM 
    pizza_prep_time
GROUP BY 
    pizza_nums;
  --   SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
  
  -- 14.What was the average distance travelled for each customer?
  SELECT 
    customer_id,
    CONCAT(ROUND(AVG(distance), 0), ' Km ') AS avg_distance_per_customer
FROM
    runner_orders
        JOIN
    customer_orders USING (order_id)
GROUP BY customer_id;



-- 15.What was the difference between the longest and shortest delivery times for all orders?

SELECT 
    MAX(Act_duration) - MIN(act_duration) AS difference_in_delivery_times
FROM
    (SELECT 
        CAST(SUBSTR(duration, 1, 2) AS UNSIGNED) AS Act_duration
    FROM
        runner_orders) AS timed_duration
WHERE
    act_duration > 0;
    
    
-- 16.What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
    ROUND(AVG(CAST(SUBSTR(distance, 1, 2) AS UNSIGNED) / CAST(SUBSTR(duration, 1, 2) AS UNSIGNED) / 60),
            2) AS Avg_Speed_in_Km_per_Hr,
    cancellation,
    runner_id
FROM
    runner_orders
WHERE
    cancellation NOT IN ('restaurant cancellation' , 'customer cancellation')
        AND CAST(SUBSTR(duration, 1, 2) AS UNSIGNED) > 0
GROUP BY runner_id
ORDER BY Avg_Speed_in_Km_per_Hr DESC;



-- 17.What is the successful delivery percentage for each runner?
with delivery_rate as 
(select runner_id,count(*) as total_deliveries,
sum(case
when cancellation not in ('restaurant cancellation' , 'customer cancellation')  or cancellation is null
then 1
else 0
end )as delivery_success from runner_orders group by runner_id)
select runner_id,total_deliveries,delivery_success,round((delivery_success/total_deliveries)*100,0) as success_rate from delivery_rate;


-- 18. What are the standard ingredients for each pizza?
-- select pizza_id,pizza_name,topping_name 
-- from pizza_names join pizza_recipes using(pizza_id)  join pizza_toppings using(topping_id) order by pizza_id;


-- 19.What was the most commonly added extra?
SELECT 
    pizza_id, COUNT(*) AS extras_added, pizza_name
FROM
    customer_orders
        JOIN
    pizza_names USING (pizza_id)
WHERE
    extras IS NOT NULL
        AND extras NOT IN ('')
        AND extras != 'null'
GROUP BY pizza_id , pizza_name
ORDER BY extras_added DESC
LIMIT 1;


-- 20.What was the most common exclusion?
SELECT 
    pizza_id, COUNT(*) AS exclusions_count, pizza_name
FROM
    customer_orders
        JOIN
    pizza_names USING (pizza_id)
WHERE
    exclusions <> 'null'
        AND exclusions <> ''
GROUP BY pizza_id , pizza_name
ORDER BY exclusions_count DESC
LIMIT 1;


-- 21.Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
select pizza_name,pizza_id, 
concat(
pizza_name,
case
when exclusions is not null and exclusions<>"" and exclusions <> 'null' then 
concat('-exclude',replace(exclusions,',',','))
else ''
end,
case 
when extras is not null and extras <> '' and extras <> 'null' then 
concat('-exclude',replace(extras,',',','))
else ''
end) as ordered_item
from customer_orders join pizza_names using(pizza_id);



-- 22.If a Meat Lovers pizza costs $12 and Vegetarian costs
-- $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
select 
pizza_name,concat(sum(cost),'$') as Revenue from (select pizza_name,concat(
case
when pizza_name='meatlovers' then 12
when pizza_name='vegetarian' then 10
else ''
end,'$') as cost
from pizza_names join customer_orders using(pizza_id)) as summation
group by pizza_name;



-- 23.What if there was an additional $1 charge for any pizza extras?
select pizza_id,pizza_name,
case
when extras<>'null' and extras<>'' and extras is not null then concat('extras ', '1 $' '. ')
else 0
end as additional_charge from pizza_names join customer_orders using(pizza_id);


















