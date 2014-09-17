select * from simple_events limit 10;

# source_actor_id in dissidentList within that time frame
DROP TABLE IF EXISTS my_tables.anh_disgov_interactions;
CREATE TABLE IF NOT EXISTS my_tables.anh_disgov_interactions
AS (
SELECT 
  *
FROM 
  simple_events
WHERE
  -- the dissident does something to the government
  (source_actor_id IN 
    (SELECT actor_id FROM my_tables.anh_dissidentList
	 WHERE
       simple_events.event_date BETWEEN my_tables.anh_dissidentList.start_date 
									AND my_tables.anh_dissidentList.end_date)
	AND target_actor_id IN 
    (SELECT actor_id FROM my_tables.anh_governmentList
     WHERE
	   simple_events.event_date BETWEEN my_tables.anh_governmentList.start_date
                                    AND my_tables.anh_governmentList.end_date)
  )
  OR
  -- the government does something to the dissident
  (source_actor_id IN 
    (SELECT actor_id FROM my_tables.anh_governmentList
     WHERE 
       simple_events.event_date BETWEEN my_tables.anh_governmentList.start_date
                                    AND my_tables.anh_governmentList.end_date)
    AND target_actor_id IN 
    (SELECT actor_id FROM my_tables.anh_dissidentList
     WHERE simple_events.event_date BETWEEN my_tables.anh_dissidentList.start_date 
									AND my_tables.anh_dissidentList.end_date)
  )
);
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
