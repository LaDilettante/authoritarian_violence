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
  group_by(year, source_actor_name, country) %>%
  summarize(sum_event = sum(goldstein)) %>%
  mutate(log_sum_event = log(sum_event + min(sum_event) + 1))