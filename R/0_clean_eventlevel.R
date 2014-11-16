# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("WDI", "psData", "foreign", "RMySQL", "data.table", "plyr", "dplyr", "countrycode")
f_install_and_load(packs)

# ---- Some constants ----
c_startyear <- 1991

# ---- Load event data ----
load("./data/private/credentials.RData") # Load credentials
db.my_tables = dbConnect(MySQL(), dbname='my_tables', host=credentials[["host"]],
                         user=credentials[["username"]], password=credentials[["password"]])
qr_disgov = dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_and_gov_clean")
d_disgov_raw = fetch(qr_disgov, n=-1)

d_disgov <- d_disgov_raw %>%
  select(event_id, goldstein,
         iso3c = country_iso3c, year, country,
         dissident_actor_name, dissident_actor_id, 
         dissident_sector_name, dissident_sector_id)

# ---- Only select the matched country years ----
load("./data/private/matched_panel.RData")
d_matched_panel <- d_matched_panel %>%
  mutate(iso3c = countrycode(country, origin="country.name", destination="iso3c"), warn=T) %>%
  select(iso3c, year)

d_disgov_matched <- merge(d_disgov, d_matched_panel, by=c("iso3c", "year"))
# Some rows can't be matched, since we balanced on the first year, sometimes the subsequent 3 years are missing
# nrow(anti_join(d_matched_panel, d_disgov, by=c("iso3c", "year")))

# ---- Load macro data ----
source("./R/load_macro_data.R")

# ---- Merge data ----

d_merged <- Reduce(function(...) merge(..., by=c("iso3c", "year"), sort=T, all=T),
                   list(d_disgov_matched, d_dpi, d_wdi, d_geddes)) %>%
  arrange(iso3c, year)
d_merged <- moveMe(d_merged, c("iso3c", "country", "year"), "first") # Re-order columns

d_merged <- merge(d_merged, d_other_dem, by=c("year"))
d_merged <- merge(d_merged, d_ethnic, by=c("iso3c"))

d_eventlevel <- d_merged
# ---- Save to disk ----
save(d_eventlevel, file="./data/private/eventlevel.RData")
