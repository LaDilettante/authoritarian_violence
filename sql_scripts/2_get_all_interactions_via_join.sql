# ---- dis_to_gov ----
DROP TABLE IF EXISTS my_tables.anh_dis_to_gov;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_to_gov AS (
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
WHERE e.event_date BETWEEN IFNULL(d.start_date,"1900-01-01") 
                       AND IFNULL(d.end_date,now())
  AND e.event_date BETWEEN IFNULL(g.start_date,"1900-01-01") 
                       AND IFNULL(g.end_date,now())
GROUP BY e.event_id, e.location_id, e.event_date, e.source_actor_id, e.target_actor_id
);
ALTER TABLE my_tables.anh_dis_to_gov
ADD PRIMARY KEY (event_id),
ADD INDEX (event_date),
ADD INDEX (goldstein),
ADD INDEX (source_actor_id),
ADD INDEX (source_country_id),
ADD INDEX (target_country_id);

# ---- gov_to_dis ----
DROP TABLE IF EXISTS my_tables.anh_gov_to_dis;
CREATE TABLE IF NOT EXISTS my_tables.anh_gov_to_dis AS (
SELECT e.*
  , g.sector_id AS source_sector_id
  , g.name AS source_sector_name
  , d.sector_id AS target_sector_id
  , d.name AS target_sector_name
FROM event_data.simple_events AS e
  # government does something to the dissident
  JOIN my_tables.anh_governmentList AS g
	ON e.source_actor_id = g.actor_id
  JOIN my_tables.anh_dissidentList AS d
	ON e.target_actor_id = d.actor_id
WHERE e.event_date BETWEEN IFNULL(d.start_date,"1900-01-01") 
                       AND IFNULL(d.end_date,now())
  AND e.event_date BETWEEN IFNULL(g.start_date,"1900-01-01") 
                       AND IFNULL(g.end_date,now())
GROUP BY e.event_id, e.location_id, e.event_date, e.source_actor_id, e.target_actor_id
);
ALTER TABLE my_tables.anh_gov_to_dis
ADD PRIMARY KEY (event_id),
ADD INDEX (event_date),
ADD INDEX (goldstein),
ADD INDEX (source_country_id),
ADD INDEX (target_actor_id),
ADD INDEX (target_country_id);
  
DROP TABLE IF EXISTS my_tables.anh_dis_to_dis;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_to_dis AS (
SELECT e.*
  , d1.sector_id AS source_sector_id
  , d1.name AS source_sector_name
  , d2.sector_id AS target_sector_id
  , d2.name AS target_sector_name
FROM event_data.simple_events AS e
  # dissident 1 does something to dissident 2
  JOIN my_tables.anh_dissidentList AS d1
	ON e.source_actor_id = d1.actor_id
  JOIN my_tables.anh_dissidentList AS d2
	ON e.target_actor_id = d2.actor_id
WHERE e.event_date BETWEEN IFNULL(d1.start_date,"1900-01-01") 
                       AND IFNULL(d1.end_date,now())
  AND e.event_date BETWEEN IFNULL(d2.start_date,"1900-01-01") 
                       AND IFNULL(d2.end_date,now())
GROUP BY e.event_id, e.location_id, e.event_date, e.source_actor_id, e.target_actor_id
);

DROP TABLE IF EXISTS my_tables.anh_gov_to_gov;
CREATE TABLE IF NOT EXISTS my_tables.anh_gov_to_gov AS (
SELECT e.*
  , g1.sector_id AS source_sector_id
  , g1.name AS source_sector_name
  , g2.sector_id AS target_sector_id
  , g2.name AS target_sector_name
FROM event_data.simple_events AS e
  # government 1 does something to government 2
  JOIN my_tables.anh_governmentList AS g1
	ON e.source_actor_id = g1.actor_id
  JOIN my_tables.anh_governmentList AS g2
	ON e.target_actor_id = g2.actor_id
WHERE e.event_date BETWEEN IFNULL(g1.start_date,"1900-01-01") 
                       AND IFNULL(g1.end_date,now())
  AND e.event_date BETWEEN IFNULL(g2.start_date,"1900-01-01") 
                       AND IFNULL(g2.end_date,now())
GROUP BY e.event_id, e.location_id, e.event_date, e.source_actor_id, e.target_actor_id
);
