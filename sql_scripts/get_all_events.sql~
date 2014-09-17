# ---- Exploratory ----
SELECT * FROM dict_sector_types;
# We find that sector_type_id 1 = religious, 2 = governmental, 
# 3 = dissidents, 4 = business, 5 = other

# ---- Get list of actor_id for dissidents and governments ----

# Now use that to get the actor_id of dissidents (sector_type_id = 3)
CREATE TABLE IF NOT EXISTS my_tables.anh_dissidentList 
AS (
SELECT sector_id
  , name
  , description
  , sector_type_id
  , actor_id
FROM dict_sectors 
  JOIN dict_sector_actor_mappings 
  USING(sector_id)
WHERE sector_type_id = 3);
# Do the same thing and get the actor_id of government actor (sector_type_id = 2)
CREATE TABLE IF NOT EXISTS my_tables.anh_governmentList 
AS (
SELECT sector_id
  , name
  , description
  , sector_type_id
  , actor_id
FROM dict_sectors 
  JOIN dict_sector_actor_mappings 
  USING(sector_id)
WHERE sector_type_id = 2);

# This took me 16000 secs
CREATE TABLE IF NOT EXISTS my_tables.anh_disgov_interactions
AS (
SELECT 
  *
FROM 
  events
WHERE
  -- the dissident does something to the government
  (source_actor_id IN (SELECT actor_id FROM my_tables.anh_dissidentList)
    AND target_actor_id IN (SELECT actor_id FROM my_tables.anh_governmentList))
  OR
  -- the government does something to the dissident
  (source_actor_id IN (SELECT actor_id FROM my_tables.anh_governmentList)
    AND target_actor_id IN (SELECT actor_id FROM my_tables.anh_dissidentList)));
ALTER TABLE my_tables.anh_disgov_interactions 
  ADD PRIMARY KEY (event_ID);
ALTER TABLE my_tables.anh_disgov_interactions
  ADD INDEX (source_actor_id),
  ADD INDEX (target_actor_id);

# Attempt to deduplicate by grouping together event with same actors, 
# same location, same date
CREATE TABLE IF NOT EXISTS my_tables.anh_unique_event_id
AS (
SELECT 
  MIN(event_Id) AS unique_event_id -- note the typo of Id
FROM 
  my_tables.anh_disgov_interactions
GROUP BY source_actor_id
  , target_actor_id
  , location_id
  , event_date
);
ALTER TABLE my_tables.anh_unique_event_id ADD PRIMARY KEY (unique_event_id);