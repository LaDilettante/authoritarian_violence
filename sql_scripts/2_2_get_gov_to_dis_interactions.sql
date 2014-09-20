DROP TABLE IF EXISTS my_tables.anh_gov_to_dis;
CREATE TABLE IF NOT EXISTS my_tables.anh_gov_to_dis AS (
SELECT e.*
  , g.sector_id AS source_sector_id
  , g.name AS source_sector_name
  , d.sector_id AS target_sector_id
  , d.name AS target_sector_name
FROM event_data.simple_events AS e
  # government does something to the dissident
  JOIN my_tables.anh_dissidentList AS d
	ON e.target_actor_id = d.actor_id
  JOIN my_tables.anh_governmentList AS g
	ON e.source_actor_id = g.actor_id
WHERE e.event_date BETWEEN d.start_date AND d.end_date
  AND e.event_date BETWEEN g.start_date AND g.end_date
);
  
