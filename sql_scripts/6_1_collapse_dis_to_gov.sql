DROP TABLE IF EXISTS my_tables.anh_dis_to_gov_count;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_to_gov_count AS (
SELECT i.*
  , aSourceInfo.name AS source_actor_name
  , sSourceInfo.name AS source_sector_name
  , cTargetInfo.Name AS target_country_name
  , cTargetInfo.ISOA3Code AS target_country_ISOA3Code
  , cTargetInfo.COWCode AS target_country_COWCode
  , cTargetdd.wdicode AS target_country_wdicode
  , cTargetdd.dpicode AS target_country_dpicode
  , cTargetdd.democracy AS target_country_democracy
FROM
(SELECT source_actor_id
  , source_sector_id
  , target_country_id
  , YEAR(event_date) as year
  , AVG(goldstein) as goldstein_avg
FROM
  my_tables.anh_dis_to_gov
WHERE source_country_id = target_country_id # Dis and gov same country
GROUP BY YEAR(event_date), target_country_id, source_actor_id) i
JOIN event_data.dict_sectors sSourceInfo
  ON i.source_sector_id = sSourceInfo.sector_id
JOIN event_data.countries AS cTargetInfo
  ON i.target_country_id = cTargetInfo.id
JOIN event_data.dict_actors AS aSourceInfo
  ON i.source_actor_id = aSourceInfo.actor_id
JOIN my_tables.anh_dd_revisited AS cTargetdd
  ON cTargetInfo.COWCode = cTargetdd.cowcode AND
     i.year = YEAR(cTargetdd.year)
);

DROP TABLE IF EXISTS my_tables.anh_dis_to_gov_count_sector;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_to_gov_count_sector AS (
SELECT i.*
  , cTargetInfo.Name AS target_country_name
  , cTargetInfo.ISOA3Code AS target_country_ISOA3Code
  , cTargetInfo.COWCode AS target_country_COWCode
  , cTargetdd.wdicode AS target_country_wdicode
  , cTargetdd.dpicode AS target_country_dpicode
  , cTargetdd.democracy AS target_country_democracy
FROM
(SELECT source_sector_name
  , source_sector_id
  , target_country_id
  , YEAR(event_date) as year
  , AVG(goldstein) as goldstein_avg
FROM
  my_tables.anh_dis_to_gov
WHERE source_country_id = target_country_id # Dis and gov same country
GROUP BY YEAR(event_date), target_country_id, source_sector_name) i
JOIN event_data.countries AS cTargetInfo
  ON i.target_country_id = cTargetInfo.id
JOIN my_tables.anh_dd_revisited AS cTargetdd
  ON cTargetInfo.COWCode = cTargetdd.cowcode AND
     i.year = YEAR(cTargetdd.year)
);
