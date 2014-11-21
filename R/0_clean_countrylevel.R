# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("WDI", "psData", "foreign", "countrycode", "RMySQL", "sem", "plyr", "dplyr")
f_install_and_load(packs) ; rm(packs)

# ---- Some constants ----
c_startyear <- 1991

# ---- Download data ----
# liec, other.democracies, gdp, gdppc, land, population, milexp, ethnic.fractionalization

# Polity IV data: other.democracies ( .. - 2012)
d_polity_raw <- PolityGet(vars="polity2")
d_polity <- d_polity_raw %>% 
  mutate(polity2_binary = ifelse(polity2 > 0, 1, 0),
         iso3c = countrycode(iso2c, origin="iso2c", destination="iso3c", warn=T)) %>%
  select(iso3c, year, polity2, polity2_binary) %>%
  filter(year >= c_startyear)

# DPI data: liec, liec7 (1975 - 2012)
d_dpi_raw <- DpiGet(vars=c("liec"))
d_dpi <- d_dpi_raw  %>%
  filter(!(iso2c=="KH" & liec==3)) %>% # For some reasons Cambodia has duplicates liec = 3 the whole time series...
  mutate(liec = ifelse(liec==-999.0, NA, liec)) %>%
  mutate(liec_cat = ifelse(liec <= 5, 0, ifelse(liec == 6, 1, ifelse(liec == 7, 2, NA)))) %>%
  mutate(liec5 = ifelse(liec >= 5, 1, 0)) %>%
  mutate(liec6 = ifelse(liec >= 6, 1, 0)) %>%
  mutate(liec7 = ifelse(liec >= 7, 1, 0)) %>%
  mutate(iso3c = countrycode(iso2c, origin="iso2c", destination="iso3c", warn=T)) %>%
  select(iso3c, year, liec, liec5, liec6, liec7) %>%
  filter(year >= c_startyear)
d_dpi <- unique(d_dpi)

# WDI data: gdp, gdppc, resourcerent.pc, milexp.pc, land, population
WDI_INDICATORS <- c("NY.GDP.MKTP.KD", "NY.GDP.PCAP.PP.KD", "MS.MIL.XPND.GD.ZS", "NY.GDP.TOTL.RT.ZS",
                    "AG.LND.TOTL.K2", "SP.POP.TOTL")
d_wdi_raw <- WDI(country="all", indicator=WDI_INDICATORS,
                 start=1975, end=2012, extra=TRUE)
d_wdi <- d_wdi_raw %>%
  mutate(milexp.pc = MS.MIL.XPND.GD.ZS) %>%
  select(iso3c, year,
         resource.pc=NY.GDP.TOTL.RT.ZS, land=AG.LND.TOTL.K2, population=SP.POP.TOTL,
         gdp=NY.GDP.MKTP.KD, gdppc=NY.GDP.PCAP.PP.KD,
         milexp.pc, region) %>%
  mutate(lgdppc = log(gdppc)) %>% select(-gdppc) %>%
  mutate(lgdp = log(gdp)) %>% select(-gdp) %>%
  arrange(iso3c, year) %>%
  filter(year >= c_startyear)

# Geddes data: authoritarian type (1946 - 2010)
d_geddes_raw <- read.table("./data/public/GWF_Autocratic_Regimes_1_2/GWF_AllPoliticalRegimes.txt", 
                           header=TRUE, sep="\t")
d_geddes <- d_geddes_raw %>%
  mutate(iso3c = countrycode(cowcode, "cown", "iso3c")) %>%
  mutate(gwf_autocracy = ifelse(is.na(gwf_nonautocracy), 1, 0)) %>%
  select(iso3c, year, 
         gwf_military, gwf_personal, gwf_party, gwf_monarchy, gwf_duration, gwf_autocracy) %>%
  filter(year >= c_startyear)
d_other_dem <- ddply(d_geddes, .(year), summarize, other.democracies = 1 - mean(gwf_autocracy))

# Gandhi data: fractionalization
d_gandhi_raw <- read.csv("./data/private/Pol_Inst_Dictatorship_Data.csv")
# Ethnic polarization is unique for each country
d_ethnic_raw <- ddply(d_gandhi_raw, .(Country.name), function(d) unique(d$Ethnic.polarization)) 
d_ethnic <- d_ethnic_raw %>% 
  mutate(iso3c = countrycode(Country.name, origin="country.name", destination="iso3c")) %>%
  select(iso3c, ethnic.polarization=V1)
d_ethnic <- na.omit(d_ethnic)

# Violence data: 1991 - 2014, but big spike of data in 2000, 2001. Before that few events
load("./data/private/credentials.RData") # Load credentials
db.my_tables = dbConnect(MySQL(), dbname='my_tables', host=credentials[["host"]],
                         user=credentials[["username"]], password=credentials[["password"]])
qr_disgov = dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_and_gov_aggregate_country")
d_disgov_raw = fetch(qr_disgov, n=-1)
d_disgov <- d_disgov_raw %>%
  select(iso3c = country_ISOA3Code, year,
         goldstein_avg, goldstein_sum, goldstein_pos_count, goldstein_neg_count)

# Pad the violence data to have all years
d_disgov_pad <- ddply(d_disgov, .(iso3c), f_pad_countryyear, 
                      idvar="iso3c", timevar="year", .inform=T)
d_disgov <- merge(d_disgov, d_disgov_pad, by=c("iso3c", "year"), all=T)

# ---- Merge data ----

d_merged <- Reduce(function(...) merge(..., by=c("iso3c", "year"), sort=T, all=T),
                   list(d_disgov, d_dpi, d_wdi, d_geddes, d_polity)) %>%
  arrange(iso3c, year) %>%
  mutate(country = countrycode(iso3c, origin="iso3c", destination="country.name", warn=T))
d_merged <- moveMe(d_merged, c("iso3c", "country", "year"), "first") # Re-order columns

d_merged <- merge(d_merged, d_other_dem, by=c("year"))
d_merged <- merge(d_merged, d_ethnic, by=c("iso3c"))

d_countrylevel <- d_merged[order(d_merged$iso3c, d_merged$year), ]

# ---- Save to disk ----
save(d_countrylevel, file="./data/private/countrylevel.RData")
