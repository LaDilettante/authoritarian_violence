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

DROP TABLE IF EXISTS my_tables.anh_dis_and_gov_dedup;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_and_gov_dedup
AS (
SELECT 
  *
FROM
  my_tables.anh_dis_and_gov
WHERE
  event_id IN (SELECT unique_event_id FROM my_tables.anh_unique_event_id)
);

ALTER TABLE
  my_tables.anh_dis_and_gov_dedup
ADD PRIMARY KEY (event_id),
ADD INDEX (source_actor_id),
ADD INDEX (target_actor_id),
ADD INDEX (source_country_id),
ADD INDEX (target_country_id),
ADD INDEX (eventtype_id),
ADD INDEX (event_date);
