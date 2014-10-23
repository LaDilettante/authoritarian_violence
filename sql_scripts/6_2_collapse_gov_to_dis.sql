DROP TABLE IF EXISTS my_tables.anh_gov_to_dis_aggregate_actor;
CREATE TABLE IF NOT EXISTS my_tables.anh_gov_to_dis_aggregate_actor AS (
SELECT i.*
  , aTargetInfo.name AS target_actor_name
  , sTargetInfo.name AS target_sector_name
  , cSourceInfo.Name AS source_country_name
  , cSourceInfo.ISOA3Code AS source_country_ISOA3Code
  , cSourceInfo.COWCode AS source_country_COWCode
  , cSourcedd.wdicode AS source_country_wdicode
  , cSourcedd.dpicode AS source_country_dpicode
  , cSourcedd.democracy AS source_country_democracy
FROM
(SELECT target_actor_id
  , target_sector_id
  , source_country_id
  , YEAR(event_date) as year
  , AVG(goldstein) as goldstein_avg
  , SUM(goldstein) as goldstein_sum
  , SUM(CASE
          WHEN goldstein >= 0 THEN 1
          WHEN goldstein <  0 THEN 0
        END) as goldstein_pos_count
  , SUM(CASE
          WHEN goldstein <  0 THEN 1
          WHEN goldstein >= 0 THEN 0
        END) as goldstein_neg_count
FROM
  my_tables.anh_gov_to_dis
WHERE source_country_id = target_country_id # Dis and gov same country
GROUP BY YEAR(event_date), source_country_id, target_actor_id) i
JOIN event_data.dict_sectors sTargetInfo
  ON i.target_sector_id = sTargetInfo.sector_id
JOIN event_data.countries AS cSourceInfo
  ON i.source_country_id = cSourceInfo.id
JOIN event_data.dict_actors AS aTargetInfo
  ON i.target_actor_id = aTargetInfo.actor_id
JOIN my_tables.anh_dd_revisited AS cSourcedd
  ON cSourceInfo.COWCode = cSourcedd.cowcode AND
     i.year = YEAR(cSourcedd.year)
);

DROP TABLE IF EXISTS my_tables.anh_gov_to_dis_aggregate_sector;
CREATE TABLE IF NOT EXISTS my_tables.anh_gov_to_dis_aggregate_sector AS (
SELECT i.*
  , sTargetInfo.name AS target_sector_name
  , cSourceInfo.Name AS source_country_name
  , cSourceInfo.ISOA3Code AS source_country_ISOA3Code
  , cSourceInfo.COWCode AS source_country_COWCode
  , cSourcedd.wdicode AS source_country_wdicode
  , cSourcedd.dpicode AS source_country_dpicode
  , cSourcedd.democracy AS source_country_democracy
FROM
(SELECT target_sector_id
  , source_country_id
  , YEAR(event_date) as year
  , AVG(goldstein) as goldstein_avg
  , SUM(goldstein) as goldstein_sum
  , SUM(CASE
          WHEN goldstein >= 0 THEN 1
          WHEN goldstein <  0 THEN 0
        END) as goldstein_pos_count
  , SUM(CASE
          WHEN goldstein <  0 THEN 1
          WHEN goldstein >= 0 THEN 0
        END) as goldstein_neg_count
FROM
  my_tables.anh_gov_to_dis
WHERE source_country_id = target_country_id # Dis and gov same country
GROUP BY YEAR(event_date), source_country_id, target_sector_id) i
JOIN event_data.dict_sectors sTargetInfo
  ON i.target_sector_id = sTargetInfo.sector_id
JOIN event_data.countries AS cSourceInfo
  ON i.source_country_id = cSourceInfo.id
JOIN my_tables.anh_dd_revisited AS cSourcedd
  ON cSourceInfo.COWCode = cSourcedd.cowcode AND
     i.year = YEAR(cSourcedd.year)
);

DROP TABLE IF EXISTS my_tables.anh_gov_to_dis_aggregate_country;
CREATE TABLE IF NOT EXISTS my_tables.anh_gov_to_dis_aggregate_country AS (
SELECT i.*
  , cSourceInfo.Name AS source_country_name
  , cSourceInfo.ISOA3Code AS source_country_ISOA3Code
  , cSourceInfo.COWCode AS source_country_COWCode
  , cSourcedd.wdicode AS source_country_wdicode
  , cSourcedd.dpicode AS source_country_dpicode
  , cSourcedd.democracy AS source_country_democracy
FROM
(SELECT source_country_id
  , YEAR(event_date) as year
  , AVG(goldstein) as goldstein_avg
  , SUM(goldstein) as goldstein_sum
  , SUM(CASE
          WHEN goldstein >= 0 THEN 1
          WHEN goldstein <  0 THEN 0
        END) as goldstein_pos_count
  , SUM(CASE
          WHEN goldstein <  0 THEN 1
          WHEN goldstein >= 0 THEN 0
        END) as goldstein_neg_count
FROM
  my_tables.anh_gov_to_dis
WHERE source_country_id = target_country_id # Dis and gov same country
GROUP BY YEAR(event_date), source_country_id) i
JOIN event_data.countries AS cSourceInfo
  ON i.source_country_id = cSourceInfo.id
JOIN my_tables.anh_dd_revisited AS cSourcedd
  ON cSourceInfo.COWCode = cSourcedd.cowcode AND
     i.year = YEAR(cSourcedd.year)
);