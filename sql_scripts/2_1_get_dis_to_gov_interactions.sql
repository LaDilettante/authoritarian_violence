CREATE TABLE my_tables.anh_dis_to_gov AS (
SELECT e.*
  , d.sector_id AS source_sector_id
  , d.name AS source_sector_name
  , g.sector_id AS target_sector_id
  , g.name AS target_sector_name
FROM event_data.simple_events AS e
  # dissident do something to government
  JOIN my_tables.anh_dissidentList AS d
	ON e.source_actor_id = d.actor_id
  JOIN my_tables.anh_governmentList AS g
	ON e.target_actor_id = g.actor_id
WHERE e.event_date BETWEEN d.start_date AND d.end_date
  AND e.event_date BETWEEN g.start_date AND g.end_date
);
