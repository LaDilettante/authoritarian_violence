# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("WDI", "psData", "foreign", "RMySQL", "data.table", "plyr", "dplyr", "countrycode", "foreign")
f_install_and_load(packs)

# ---- Load event data ----
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

  

# ---- Load DPI data (liec electoral rule) ----
d_dpi_raw <- DpiGet(vars=c("liec"))
d_dpi <- d_dpi_raw %>% 
  mutate(iso3c = countrycode(iso2c, origin="iso2c", destination="iso3c", warn=T)) %>%
  mutate(liec = ifelse(liec==-999.0, NA, liec)) %>%
  mutate(legis_multi = ifelse(liec >=5, 1, 0)) %>%
  group_by(iso3c, year) %>%
  mutate(liec = mean(liec)) %>%
  filter(row_number() == 1) %>%
  select(iso3c, year, country, liec, legis_multi)

# ---- Load WDI data ----
# GDP constant 2005 dollar, GDP per cap constant 2011 dollars, mil exp %GDP, 
WDI_INDICATORS <- c("NY.GDP.MKTP.KD", "NY.GDP.PCAP.PP.KD", "MS.MIL.XPND.GD.ZS")
d_wdi_raw <- WDI(country="all", indicator=WDI_INDICATORS,
             start=1991, end=2008, extra=TRUE)
d_wdi <- d_wdi_raw %>%
  mutate(milexp = MS.MIL.XPND.GD.ZS * NY.GDP.MKTP.KD) %>%
  select(iso3c, year, country, gdp=NY.GDP.MKTP.KD, gdppc=NY.GDP.PCAP.PP.KD,
         milexp, region) %>%
  arrange(iso3c, year)

# ---- Load Geddes autocracy type data ----
# emil, royal, otherwise civilian
d_geddes_raw <- read.table("./data/public/GWF Autocratic Regimes 1.2/GWF_AllPoliticalRegimes.txt", 
                           header=TRUE, sep="\t")
d_geddes <- d_geddes_raw %>%
  mutate(iso3c = countrycode(cowcode, "cown", "iso3c")) %>%
  select(iso3c, year, country=gwf_country, 
         gwf_military, gwf_personal, gwf_party, gwf_monarchy)

# ---- Find democratic transition (based on Cheibub DD) ----
d_dd <- read.dta("./data/public/ddrevisited_data_v1.dta") # variable names and labels?

f_find_transition_point <- function(df) {
  wanted_rows <- data.table:::uniqlist(df[ , "democracy", drop=FALSE])[-1] # -1 to get rid of the first row
  
  df_transition <- data.frame(df[wanted_rows, ],
                              democracy_previous=df[wanted_rows - 1, "democracy"])
  df_democratic_transition <- df_transition[df_transition$democracy==1, ]
  return(df_democratic_transition)
}
# Find countries from 1991 to 2014 where transition happened
d_democratic_transition <- ddply(d_dd[d_dd$year > 1990 , ], c("wdicode"), f_find_transition_point)
d_democratic_transition <- d_democratic_transition %>%
  mutate(iso3c = countrycode(cowcode, "cown", "iso3c")) %>%
  select(iso3c, cowcode, ctryname, year, democracy, democracy_previous)

d_tmp <- ddply(d_democratic_transition, c("iso3c", "year"),
               function(df) data.frame(wanted_years = (df$year - 10):df$year))
d_tmp2 <- merge(d_tmp, d_dpi, by.x=c("iso3c", "wanted_years"), by.y=c("iso3c", "year"))
d_tmp3 <- ddply(d_tmp2, c("iso3c", "year"), summarize, mean_liec = mean(liec), mean_legis = mean(legis_multi))
  
# ---- Merge data ----

d_disgov_merged_full <- Reduce(function(...) merge(..., match=c("iso3c", "year"), all.x=T, sort=T),
                   list(d_disgov, d_dpi, d_wdi, d_geddes))
d_disgovsect_merged_full <-  Reduce(function(...) merge(..., match=c("iso3c", "year"), all.x=T, sort=T),
                                    list(d_disgovsect, d_dpi, d_wdi, d_geddes))

# ---- Save cleaned data ----
save(d_disgov_merged_full, d_disgovsect_merged_full, d_democratic_transition, file='./data/private/data_final.RData')
