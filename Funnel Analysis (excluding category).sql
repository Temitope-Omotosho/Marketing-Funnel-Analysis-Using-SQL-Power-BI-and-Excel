--the result from this query was copied to excel to create a country split funnel chart.
WITH unique_event AS (							
--CTE to remove duplicates based on event_name							
  SELECT  country,						
          event_name,
          ROW_NUMBER() OVER (PARTITION BY user_pseudo_id,event_name ORDER BY event_timestamp) as row_num							
  FROM `turing_data_analytics.raw_events`													
),							
--CTE to change the format of the date and also to exclude row number from the result set							
raw_events AS (							
  SELECT country,							
         event_name
  FROM unique_event							
  WHERE row_num = 1
),							

--CTE to check the top countries based on number of events
top_3_countries AS (
  SELECT country, COUNT(*) no_of_events
  FROM raw_events
  GROUP BY country
  ORDER BY COUNT(*) DESC
  LIMIT 3
),

--CTE to select the key stages in the funnel by the top 3 countries which is USA, India & Canada
key_funnels AS (
  SELECT country, event_name, COUNT(*) as number_of_events
  FROM raw_events
  WHERE country IN ('United States','India','Canada') 
  AND event_name IN ('page_view','view_item','add_to_cart','add_shipping_info','add_payment_info','purchase') 
  GROUP BY country, event_name
  ORDER BY country,COUNT(*) DESC
),

usa_events AS (
  SELECT ROW_NUMBER() OVER(ORDER BY number_of_events DESC) as event_order,
        event_name,
        number_of_events as USA_events
  FROM key_funnels
  WHERE country = 'United States'
),

india_events AS (
  SELECT ROW_NUMBER() OVER(ORDER BY number_of_events DESC) as event_order,
        event_name,
        number_of_events as India_events
  FROM key_funnels
  WHERE country = 'India'
),

canada_events AS (
  SELECT ROW_NUMBER() OVER(ORDER BY number_of_events DESC) as event_order,
        event_name,
        number_of_events as Canada_events
  FROM key_funnels
  WHERE country = 'Canada'
)

SELECT usa.event_order,
       usa.event_name,
       usa.USA_events,
       ind.India_events,
       can.Canada_events
FROM usa_events as usa
INNER JOIN india_events as ind
ON usa.event_order = ind.event_order
INNER JOIN canada_events as can
ON usa.event_order = can.event_order;
