# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("WDI", "psData", "foreign", "countrycode", "RMySQL", "sem", "plyr", "dplyr", "plm")
f_install_and_load(packs) ; rm(packs)

# ---- Download data ----
# liec, other.democracies, gdp, gdppc, land, population, milexp, ethnic.fractionalization

# Polity IV data: other.democracies ( .. - 2012)
d_polity_raw <- PolityGet(vars="polity2")
d_polity <- d_polity_raw %>% mutate(polity2_binary = ifelse(polity2 > 0, 1, 0))
d_other_dem <- ddply(d_polity, .(year), summarize, other.democracies = mean(polity2_binary, na.rm=T))

# DPI data: liec, liec7 (1975 - 2012)
d_dpi_raw <- DpiGet(vars=c("liec"))
d_dpi <- d_dpi_raw  %>%
  mutate(liec = ifelse(liec==-999.0, NA, liec)) %>%
  mutate(liec7 = ifelse(liec >= 7, 1, 0)) %>%
  mutate(iso3c = countrycode(iso2c, origin="iso2c", destination="iso3c", warn=T)) %>%
  select(-liec)
d_dpi <- unique(d_dpi)

# WDI data: gdp, gdppc, resourcerent.pc, milexp.pc, land, population
WDI_INDICATORS <- c("NY.GDP.MKTP.KD", "NY.GDP.PCAP.PP.KD", "MS.MIL.XPND.GD.ZS", "NY.GDP.TOTL.RT.ZS",
                    "AG.LND.TOTL.K2", "SP.POP.TOTL")
d_wdi_raw <- WDI(country="all", indicator=WDI_INDICATORS,
                 start=1975, end=2012, extra=TRUE)
d_wdi <- d_wdi_raw %>%
  mutate(milexp.pc = MS.MIL.XPND.GD.ZS) %>%
  select(iso3c, year, country,
         resource.pc=NY.GDP.TOTL.RT.ZS, land=AG.LND.TOTL.K2, population=SP.POP.TOTL,
         gdp=NY.GDP.MKTP.KD, gdppc=NY.GDP.PCAP.PP.KD,
         milexp.pc, region) %>%
  arrange(iso3c, year)

# Geddes data: authoritarian type (1946 - 2010)
d_geddes_raw <- read.table("./data/public/GWF Autocratic Regimes 1.2/GWF_AllPoliticalRegimes.txt", 
                           header=TRUE, sep="\t")
d_geddes <- d_geddes_raw %>%
  mutate(iso3c = countrycode(cowcode, "cown", "iso3c")) %>%
  select(iso3c, year, country=gwf_country, 
         gwf_military, gwf_personal, gwf_party, gwf_monarchy)

# Gandhi data: fractionalization
d_gandhi_raw <- read.csv("./data/private/Pol_Inst_Dictatorship_Data.csv")
# Ethnic polarization is unique for each country
d_ethnic_raw <- ddply(d_gandhi_raw, .(Country.name), function(d) unique(d$Ethnic.polarization)) 
d_ethnic <- d_ethnic_raw %>% 
  mutate(iso3c = countrycode(Country.name, origin="country.name", destination="iso3c")) %>%
  select(iso3c, country=Country.name, ethnic.polarization=V1)
d_ethnic <- na.omit(d_ethnic)

# Violence data: 1991 - 2014, but big spike of data in 2000, 2001. Before that few events
load("./data/private/credentials.RData") # Load credentials
db.my_tables = dbConnect(MySQL(), dbname='my_tables', host=credentials[["host"]],
                         user=credentials[["username"]], password=credentials[["password"]])
qr_disgov = dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_and_gov_aggregate_country")
d_disgov_raw = fetch(qr_disgov, n=-1)
d_disgov <- d_disgov_raw %>%
  select(iso3c = country_ISOA3Code, year,
         country = country_name,
         goldstein_avg, goldstein_sum, goldstein_pos_count, goldstein_neg_count)

# ---- Merge data ----
d_merged <- Reduce(function(...) merge(..., by=c("iso3c", "year"), sort=T),
                   list(d_disgov, d_dpi, d_wdi, d_geddes)) %>%
  mutate(country = country.x) %>%
  arrange(iso3c, country, year)
d_merged <- d_merged[ , setdiff(names(d_merged), c("country.x", "country.y"))] # Remove extra columns
d_merged <- moveMe(d_merged, c("iso3c", "country", "year"), "first") # Re-order columns

d_merged <- merge(d_merged, d_other_dem, by=c("year"))
d_merged <- merge(d_merged, d_ethnic, by=c("iso3c"))

# ---- Weak Instrument Test ----
m_ftest <- lm(liec ~ other.democracies, data=d_merged)
summary(m_ftest)
m_ftestbinary <- lm(liec7 ~ other.democracies, data=d_merged)
summary(m_ftestbinary)

# ---- Instrumental var regression ----
cor(d_merged[ , c( "ethnic.polarization", "resource.pc",
        "gwf_military", "gwf_personal", "gwf_party", "milexp.pc", "gdp", "gdppc",
        "land", "population")], use="complete.obs")

fm_CONTROL <- "ethnic.polarization + resource.pc +
        gwf_military + gwf_personal + gwf_party + milexp.pc +
        gdppc + land"

m_avg <- tsls(formula=formula(paste("goldstein_avg ~ liec7 +", fm_CONTROL)),
              instruments=formula(paste("~ other.democracies +", fm_CONTROL)),
              data=d_merged)
summary(m_avg)

summary(lm(formula(paste("goldstein_avg ~ liec7 +", fm_CONTROL)), data=d_merged))
summary(lm(formula(paste("goldstein_avg ~ other.democracies +", fm_CONTROL)), data=d_merged))



mp_avg_plain <- plm(formula(paste("goldstein_avg ~ liec7 +", fm_CONTROL)),
                    data=d_merged, index=c("iso3c", "year"), model = "within")
summary(mp_avg_plain)

mp_avg <- plm(formula(paste("goldstein_avg ~ liec7 +", fm_CONTROL, "| other.democracies +", fm_CONTROL)), 
              data=d_merged, index=c("iso3c", "year"), model = "random")
summary(mp_avg)