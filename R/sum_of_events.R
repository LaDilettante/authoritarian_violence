# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("WDI", "psData", "foreign", "RMySQL", "dplyr", "countrycode", "foreign")
f_install_and_load(packs)

# ---- Set up data ----
# event data
load("./data/credentials.RData") # Load credentials
db.my_tables = dbConnect(MySQL(), dbname='my_tables', host=credentials[["host"]],
                         user=credentials[["username"]], password=credentials[["password"]])
qr_disgov = dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_to_gov
                        WHERE target_country_democracy=0")
d_disgov_raw = fetch(qr_disgov, n=-1)


d_disgov <- d_disgov_raw %>%
  select(iso3c = target_country_ISOA3Code, year, 
         country = target_country_name,
         source_actor_name, source_actor_id, goldstein_avg)