# ---- Exploratory ----
SELECT * FROM event_data.dict_sectors where name='Dissident'; # sector_id = 100
SELECT * FROM event_data.dict_sectors where name='Government'; # sector_id = 28
# We find that sector_type_id 1 = religious, 2 = governmental, 
# 3 = dissidents, 4 = business, 5 = other

# ---- Get list of actor_id for dissidents and governments ----

# Now use that to get the actor_id of dissidents (sector_type_id = 3)
# Note that an actor is classified as belonging to a sector conditional to start and end date
DROP TABLE IF EXISTS my_tables.anh_dissidentList;
CREATE TABLE IF NOT EXISTS my_tables.anh_dissidentList 
AS (
SELECT sector_id
  , name
  , description
  , sector_type_id
  , actor_id
  , start_date
  , end_date
FROM event_data.dict_sectors s
  JOIN event_data.dict_sector_mappings m
  USING(sector_id)
WHERE s.parent_sector_id = 100);

# Do the same thing and get the actor_id of government actor (sector_type_id = 2)
DROP TABLE IF EXISTS my_tables.anh_governmentList;
CREATE TABLE IF NOT EXISTS my_tables.anh_governmentList 
AS (
SELECT sector_id
  , name
  , description
  , sector_type_id
  , actor_id
  , start_date
  , end_date
FROM event_data.dict_sectors s
  JOIN event_data.dict_sector_mappings m
  USING(sector_id)
WHERE s.parent_sector_id = 28);

ALTER TABLE my_tables.anh_dissidentList
  ADD INDEX (actor_id),
  ADD INDEX (start_date),
  ADD INDEX (end_date),
  ADD INDEX (name);
ALTER TABLE my_tables.anh_governmentList
  ADD INDEX (actor_id),
  ADD INDEX (start_date),
  ADD INDEX (end_date),
  ADD INDEX (name);