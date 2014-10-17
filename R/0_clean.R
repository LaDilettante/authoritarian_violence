# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("WDI", "psData", "foreign", "RMySQL", "dplyr", "countrycode", "foreign")
f_install_and_load(packs)

# ---- Set up data ----
# event data
load("./data/private/credentials.RData") # Load credentials
db.my_tables = dbConnect(MySQL(), dbname='my_tables', host=credentials[["host"]],
                         user=credentials[["username"]], password=credentials[["password"]])
qr_disgov = dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_to_gov_count
                                       WHERE target_country_democracy = 0")
d_disgov_raw = fetch(qr_disgov, n=-1)
d_disgov <- d_disgov_raw %>%
  select(iso3c = target_country_ISOA3Code, year, 
         country = target_country_name,
         source_actor_name, source_actor_id, source_sector_name, 
         goldstein_avg, goldstein_sum, goldstein_pos_count, goldstein_neg_count)

qr_disgovsect <- dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_to_gov_count_sector
                                           WHERE target_country_democracy = 0")
d_disgovsect_raw <- fetch(qr_disgovsect, n=-1)
d_disgovsect <- d_disgovsect_raw %>%
  select(iso3c = target_country_ISOA3Code, year, 
         country = target_country_name,
         source_sector_id, source_sector_name, 
         goldstein_avg, goldstein_sum, goldstein_pos_count, goldstein_neg_count)

  

# Collect other covariates
# liec electoral rule
d_dpi_raw <- DpiGet(vars=c("liec"))
d_dpi <- d_dpi_raw %>% 
  mutate(iso3c = countrycode(iso2c, origin="iso2c", destination="iso3c", warn=T)) %>%
  mutate(liec = ifelse(liec==-999.0, NA, liec)) %>%
  mutate(legis_multi = ifelse(liec >=5, 1, 0)) %>%
  group_by(iso3c, year) %>%
  mutate(liec = mean(liec)) %>%
  filter(row_number() == 1) %>%
  select(iso3c, year, country, liec, legis_multi)

# GDP constant 2005 dollar, GDP per cap constant 2011 dollars, mil exp %GDP, 
WDI_INDICATORS <- c("NY.GDP.MKTP.KD", "NY.GDP.PCAP.PP.KD", "MS.MIL.XPND.GD.ZS")
d_wdi_raw <- WDI(country="all", indicator=WDI_INDICATORS,
             start=1991, end=2008, extra=TRUE)
d_wdi <- d_wdi_raw %>%
  mutate(milexp = MS.MIL.XPND.GD.ZS * NY.GDP.MKTP.KD) %>%
  select(iso3c, year, country, gdp=NY.GDP.MKTP.KD, gdppc=NY.GDP.PCAP.PP.KD,
         milexp, region) %>%
  arrange(iso3c, year)

# emil, royal, otherwise civilian
d_geddes_raw <- read.table("./data/public/GWF Autocratic Regimes 1.2/GWF_AllPoliticalRegimes.txt", 
                           header=TRUE, sep="\t")
d_geddes <- d_geddes_raw %>%
  mutate(iso3c = countrycode(cowcode, "cown", "iso3c")) %>%
  select(iso3c, year, country=gwf_country, 
         gwf_military, gwf_personal, gwf_party, gwf_monarchy)
  
# ---- Merge data ----

d_disgov_merged_full <- Reduce(function(...) merge(..., match=c("iso3c", "year"), all.x=T, sort=T),
                   list(d_disgov, d_dpi, d_wdi, d_geddes))
d_disgovsect_merged_full <-  Reduce(function(...) merge(..., match=c("iso3c", "year"), all.x=T, sort=T),
                                    list(d_disgovsect, d_dpi, d_wdi, d_geddes))

save(d_disgov_merged_full, d_disgovsect_merged_full, file='./data/private/data_final.RData')
