DROP TABLE IF EXISTS my_tables.anh_dis_and_gov;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_and_gov AS
  SELECT * FROM my_tables.anh_dis_to_gov
  UNION
  SELECT * FROM my_tables.anh_gov_to_dis;

ALTER TABLE my_tables.anh_dis_and_gov
  ADD INDEX (event_id),
  ADD INDEX (event_date),
  ADD INDEX (source_actor_id),
  ADD INDEX (target_actor_id),
  ADD INDEX (source_country_id),
  ADD INDEX (target_country_id),
  ADD INDEX (location_id),
  ADD INDEX (source_sector_id),
  ADD INDEX (target_actor_id);
