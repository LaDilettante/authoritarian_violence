ALTER TABLE my_tables.anh_dis_to_gov
  ADD PRIMARY KEY (event_id);
ALTER TABLE my_tables.anh_dis_to_gov
  ADD INDEX (event_date),
  ADD INDEX (source_actor_id),
  ADD INDEX (target_actor_id),
  ADD INDEX (source_country_id),
  ADD INDEX (target_country_id),
  ADD INDEX (eventtype_id); 