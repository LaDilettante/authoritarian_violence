# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("WDI", "psData", "foreign", "RMySQL", "data.table", "plyr", "dplyr", "countrycode")
f_install_and_load(packs)

# ---- Load event data ----
load("./data/private/credentials.RData") # Load credentials
db.my_tables = dbConnect(MySQL(), dbname='my_tables', host=credentials[["host"]],
                         user=credentials[["username"]], password=credentials[["password"]])
qr_disgov = dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_and_gov_clean")
d_disgov_raw = fetch(qr_disgov, n=-1)

d_disgov <- d_disgov_raw %>%
  select(iso3c = target_country_ISOA3Code, year,
         country = target_country_name,
         source_actor_name, source_actor_id, source_sector_name, 
         goldstein_avg, goldstein_sum, goldstein_pos_count, goldstein_neg_count)