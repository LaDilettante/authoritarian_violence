DROP TABLE IF EXISTS my_tables.anh_unique_event_id;
CREATE TABLE IF NOT EXISTS my_tables.anh_unique_event_id
AS (
SELECT 
  MIN(event_id) AS unique_event_id
FROM 
  my_tables.anh_dis_and_gov
GROUP BY source_actor_id
  , target_actor_id
  , location_id
  , event_date
);

ALTER TABLE my_tables.anh_unique_event_id
ADD PRIMARY KEY (unique_event_id);
