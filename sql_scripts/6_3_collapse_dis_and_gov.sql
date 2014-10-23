DROP TABLE IF EXISTS my_tables.anh_dis_and_gov_aggregate_country;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_and_gov_aggregate_country AS (
SELECT i.*
  , cInfo.Name AS country_name
  , cInfo.ISOA3Code AS country_ISOA3Code
  , cInfo.COWCode AS country_COWCode
  , cdd.wdicode AS country_wdicode
  , cdd.dpicode AS country_dpicode
  , cdd.democracy AS country_democracy
FROM
	(SELECT country_id
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
		((SELECT event_id # Select only country, year, goldstein from dis_to_gov. Target country is just country
		  , event_date
		  , goldstein
		  , target_country_id AS country_id
		FROM my_tables.anh_dis_to_gov
		WHERE target_country_id = source_country_id) 
		UNION # UNION with
		(SELECT event_id # Select only country, year, goldstein from gov_to_dis. source_country is just country
		  , event_date
		  , goldstein
		  , source_country_id AS country_id
		FROM my_tables.anh_gov_to_dis
		WHERE target_country_id = source_country_id)) AS dis_and_gov # Here, we only have event, year, country
	GROUP BY YEAR(event_date), country_id) AS i # Aggregate that by country and year
JOIN event_data.countries AS cInfo
  ON i.country_id = cInfo.id
JOIN my_tables.anh_dd_revisited AS cdd
  ON cInfo.COWCode = cdd.cowcode AND
     i.year = YEAR(cdd.year)
);
