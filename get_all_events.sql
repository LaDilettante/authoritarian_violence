# ---- Exploratory ----
SELECT * FROM dict_sector_types;
# We find that sector_type_id 1 = religious, 2 = governmental, 
# 3 = dissidents, 4 = business, 5 = other

# Get list of actors that have sector_type_id = 3 (i.e dissidents)
SHOW FIELDS FROM dict_sectors;
SELECT * FROM dict_sectors LIMIT 20;

# dict_sector_actor_mappings maps actor_id to sector_id and to sector_actor_id (which is?)
SHOW FIELDS FROM dict_sector_actor_mappings;
SELECT * FROM dict_sector_actor_mappings LIMIT 20;

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

# Add indices to the newly created table
ALTER TABLE my_tables.anh_disgov_interactions
ADD PRIMARY KEY (event_ID);


# Output the table to csv (DOES NOT HAVE AUTHORITY)
DESCRIBE my_tables.anh_disgov_interactions;
SELECT 
  *
INTO OUTFILE '/tmp/disgov_interaction.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

############################################################
#---- Get full info: join with country name, event type ----
############################################################

DESCRIBE my_tables.anh_disgov_interactions;
SELECT * FROM my_tables.anh_disgov_interactions LIMIT 20;
SELECT * FROM event_target_country_mappings LIMIT 20;
SELECT * FROM event_source_country_mappings LIMIT 20;
SELECT * FROM country_info LIMIT 20;
SELECT * FROM locations LIMIT 20;
SELECT * FROM eventtypes LIMIT 20; # What is the type of event, neg or pos, description

CREATE TABLE IF NOT EXISTS my_tables.anh_disgov_interactions_full
AS (
SELECT i.event_Id
  , i.source_actor_id
  , i.target_actor_id
  , i.story_id
  , i.text
  , i.event_date
  , i.location_id
  , cTarget.country_id AS target_country_id
  , cSource.country_id AS source_country_id
  , c.Name AS CountryName
  , c.lower_countryname
  , c.ISOA3Code
  , c.COWCode
  , c.Cocom_Id
  , c.Cocom_Region_Id
  , e.*
FROM my_tables.anh_disgov_interactions AS i
  JOIN event_target_country_mappings AS cTarget
	ON i.event_Id = cTarget.event_id
  JOIN event_source_country_mappings AS cSource
    ON i.event_Id = cSource.event_id
  JOIN countries AS c 
	ON (cTarget.country_id = c.id) OR
       (cSource.country_id = c.id)
  JOIN eventtypes AS e
	ON i.eventtype_id = e.eventtype_ID
);

# Add indexes to the newly created table
ALTER TABLE 
  my_tables.anh_disgov_interactions_full
ADD INDEX (event_Id),
ADD INDEX (source_actor_id),
ADD INDEX (target_actor_id);

#########################
#---- Deduplication  ----
#########################

# Attempt to deduplicate by grouping together event with same actors, 
# same location, same date
CREATE TABLE IF NOT EXISTS my_tables.anh_disgov_interactions_full_dedup
AS (
SELECT
  *
FROM
  my_tables.anh_disgov_interactions_full
WHERE
  event_Id IN  (SELECT 
				  MIN(event_Id) -- note the typo of Id
				FROM 
				  my_tables.anh_disgov_interactions_full
				GROUP BY source_actor_id
				  , target_actor_id
				  , location_id
				  , event_date)
);

SELECT *
FROM my_tables.anh_disgov_interactions_full_dedup;