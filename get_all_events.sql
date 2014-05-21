show fields from dict_actors;
select * from dict_actors LIMIT 20;
select * from dict_sector_actor_mappings LIMIT 20;


select * from dict_sector_types;
# We find that sector_type_id 1 = religious, 2 = governmental, 3 = dissidents, 4 = business, 5 = other

# Get list of actors that have sector_type_id = 3 (i.e dissidents)
# Don't have rights to create table though
select distinct sector_id, name, description, sector_type_id, actor_id
	from (dict_sectors join dict_sector_actor_mappings using(sector_id))
	where sector_type_id = 3 or sector_type_id = 2;

describe events;

# Attempt to deduplicate by grouping together event with same actors, same location, same date
select MIN(event_Id)
					 from events
					where events.source_actor_id in (select distinct actor_id
										from (dict_sectors join dict_sector_actor_mappings using(sector_id))
									   where sector_type_id = 3)
					  and events.target_actor_id in (select distinct actor_id
										from (dict_sectors join dict_sector_actor_mappings using(sector_id))
									   where sector_type_id = 2)
				group by source_actor_id, target_actor_id, location_id, event_date;

select * from events
where event_Id in (select MIN(event_Id)
					 from events
					where events.source_actor_id in (select distinct actor_id
										from (dict_sectors join dict_sector_actor_mappings using(sector_id))
									   where sector_type_id = 3)
					  and events.target_actor_id in (select distinct actor_id
										from (dict_sectors join dict_sector_actor_mappings using(sector_id))
									   where sector_type_id = 2)
				group by source_actor_id, target_actor_id, location_id, event_date);

# Get full info: join with country name, event type
select *
from (select * from (select * from (select distinct *
	 from events
	where events.source_actor_id in (select distinct actor_id
						from (dict_sectors join dict_sector_actor_mappings using(sector_id))
					   where sector_type_id = 3)
	  and events.target_actor_id in (select distinct actor_id
						from (dict_sectors join dict_sector_actor_mappings using(sector_id))
					   where sector_type_id = 2)
	) as event_dissident_gov
	 join event_target_country_mappings using(event_id)) as event_with_country_id
	 join countries
	 on event_with_country_id.country_id = countries.id) as event_with_country
	 join eventtypes
	 on event_with_country.eventtype_id = eventtypes.eventtype_ID
	LIMIT 200;

# Alternative way to get full info
select * from
(select distinct *
	 from events
	where events.source_actor_id in (select distinct actor_id
						from (dict_sectors join dict_sector_actor_mappings using(sector_id))
					   where sector_type_id = 3)
	  and events.target_actor_id in (select distinct actor_id
						from (dict_sectors join dict_sector_actor_mappings using(sector_id))
					   where sector_type_id = 2)) as event_dissident_gov
join event_target_country_mappings using(event_id)
join countries on event_target_country_mappings.country_id = countries.id
join eventtypes on event_dissident_gov.eventtype_id = eventtypes.eventtype_ID
LIMIT 200;