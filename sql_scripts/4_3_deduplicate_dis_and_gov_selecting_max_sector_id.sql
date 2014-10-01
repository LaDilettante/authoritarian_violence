DROP TABLE IF EXISTS my_tables.anh_dis_and_gov_dedup_final;
CREATE TABLE IF NOT EXISTS my_tables.anh_dis_and_gov_dedup_final AS (
SELECT l.* 
FROM my_tables.anh_dis_and_gov_dedup l
INNER JOIN (
  SELECT 
    event_id, max(source_sector_id) as m_source_sector_id, max(target_sector_id) as m_target_actor_id 
  FROM my_tables.anh_dis_and_gov_dedup
  GROUP BY event_id
) r
  ON l.source_sector_id = r.m_source_sector_id 
 AND l.target_sector_id = r.m_target_actor_id
 AND l.event_id = r.event_id
);
