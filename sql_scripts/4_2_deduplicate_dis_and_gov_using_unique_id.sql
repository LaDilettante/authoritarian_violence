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
ADD INDEX (event_id),
ADD INDEX (source_actor_id),
ADD INDEX (target_actor_id),
ADD INDEX (source_sector_id),
ADD INDEX (target_sector_id),
ADD INDEX (source_country_id),
ADD INDEX (target_country_id),
ADD INDEX (eventtype_id),
ADD INDEX (event_date);
