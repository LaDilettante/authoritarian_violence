# Reference http://stackoverflow.com/questions/25895230/mysql-query-nested-where-condition
DROP TABLE IF EXISTS my_tables.anh_disgov_interactions;
CREATE TABLE IF NOT EXISTS my_tables.anh_disgov_interactions
AS (
SELECT *
FROM
  event_data.simple_events AS e
  WHERE EXISTS (
        SELECT * FROM my_tables.anh_dissidentList
        WHERE actor_id IN (e.source_actor_id, e.target_actor_id)
			  AND e.event_date BETWEEN start_date AND end_date)
    AND EXISTS (
        SELECT * FROM my_tables.anh_governmentList
        WHERE actor_id IN (e.source_actor_id, e.target_actor_id)
              AND e.event_date BETWEEN start_date AND end_date)
);

ALTER TABLE my_tables.anh_disgov_interactions 
  ADD PRIMARY KEY (event_ID);
ALTER TABLE my_tables.anh_disgov_interactions
  ADD INDEX (source_actor_id),
  ADD INDEX (target_actor_id);