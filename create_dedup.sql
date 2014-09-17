CREATE TABLE IF NOT EXISTS my_tables.anh_disgov_interactions_dedup
AS (
SELECT 
  *
FROM
  my_tables.anh_disgov_interactions
WHERE
  event_Id IN (SELECT unique_event_id FROM my_tables.anh_unique_event_id)
);

ALTER TABLE
  my_tables.anh_disgov_interactions_dedup
ADD PRIMARY KEY (event_Id),
ADD INDEX (source_actor_id),
ADD INDEX (target_actor_id),
ADD INDEX (eventtype_id),
ADD INDEX (event_date);
