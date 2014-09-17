rm(list=ls())
toLoad <- c("RMySQL", "dplyr")
lapply(toLoad, library, character.only=TRUE)

# mydb = dbConnect(MySQL(), user='aql3', password='password', dbname='database_name', host='152.3.32.10')
# Use that command to connect to "event_data" and "my_tables"
# db.event_data = dbConnect(MySQL(), user='aql3', password='password', dbname='event_data', host='152.3.32.10')
# db.my_tables = dbConnect(MySQL(), user='aql3', password='password', dbname='my_tables', host='152.3.32.10')
# 
# dbListTables(db.my_tables)
# 
# qr.dedup = dbSendQuery(db.my_tables, "SELECT * FROM anh_disgov_interactions_full_dedup")
# d.dedup = fetch(qr.dedup, n=-1)
# 
# write.csv(d.dedup, 
#   file="/home/anh/projects/authoritarian_violence/disgov_interactions_full_dedup.csv",
#   row.names=FALSE)

# db.event_data <- src_mysql(dbname="event_data", host="152.3.32.10", user="aql3", password=password)
# db.my_tables <- src_mysql(dbname="my_tables", host="152.3.32.10", user="aql3", password=password)
data <- tbl(db.my_tables, sql("SELECT * FROM anh_disgov_interactions_dedup_fullinfo"))
data_dictator <- filter(data, target_country_democracy==0 | source_country_democracy==0)
dim(data_dictator)

res <- collect(data_dictator)
filter(res, source_country_id == target_country_id)
sort(unique(res$source_country_name))

res_full <- collect(data)
