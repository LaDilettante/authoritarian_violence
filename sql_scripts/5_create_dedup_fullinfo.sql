DROP TABLE IF EXISTS my_tables.anh_dis_and_gov_dedup_fullinfo;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_and_gov_dedup_fullinfo AS (
SELECT i.*
  , aTarget.name AS target_actor_name
  , aSource.name AS source_actor_name
  , cTargetInfo.Name AS target_country_name
  , cTargetInfo.ISOA3Code AS target_country_ISOA3Code
  , cTargetInfo.COWCode AS target_country_COWCode
  , cSourceInfo.Name AS source_country_name
  , cSourceInfo.ISOA3Code AS source_country_ISOA3Code
  , cSourceInfo.COWCode AS source_country_COWCoce
  , cTargetdd.wdicode AS target_country_wdicode
  , cTargetdd.dpicode AS target_country_dpicode
  , cTargetdd.democracy AS target_country_democracy
  , cSourcedd.wdicode AS source_country_wdicode
  , cSourcedd.dpicode AS source_country_dpicode
  , cSourcedd.democracy AS source_country_democracy
FROM my_tables.anh_dis_and_gov_dedup_final AS i
  JOIN event_data.countries AS cTargetInfo
    ON i.target_country_id = cTargetInfo.id
  JOIN event_data.countries AS cSourceInfo
    ON i.source_country_id = cSourceInfo.id
  JOIN my_tables.anh_dd_revisited AS cTargetdd
    ON cTargetInfo.COWCode = cTargetdd.cowcode AND
	   YEAR(i.event_date) = YEAR(cTargetdd.year)
  JOIN my_tables.anh_dd_revisited AS cSourcedd
    ON cSourceInfo.COWCode = cSourcedd.cowcode AND
       YEAR(i.event_date) = YEAR(cSourcedd.year)
  JOIN event_data.dict_actors AS aSource
	ON i.source_actor_id = aSource.actor_id
  JOIN event_data.dict_actors AS aTarget
	ON i.target_actor_id = aTarget.actor_id
);
