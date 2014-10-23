# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("WDI", "psData", "foreign", "countrycode", "MatchIt", "Amelia", "plyr", "dplyr")
f_install_and_load(packs) ; rm(packs)

# ---- Load data ----
d_gandhi_raw <- read.csv("./data/private/Pol_Inst_Dictatorship_Data.csv")
d_gandhi <- d_gandhi_raw %>% 
  filter(Year >= 1991) %>%
  mutate(Institutions.binary = ifelse(Institutions==2, 1, 0)) %>%
  mutate(iso3c = countrycode(Country.name, origin="country.name", destination="iso3c", warn=T)) %>%
  mutate(year = Year) %>%
  select(-Capital.stock.growth, -Labor.force.growth, -Education.growth)

# ---- Weak instrument test ----

m_ftest <- lm(Institutions ~ Other.democracies, data=d_gandhi)
summary(m_ftest)

m_ftestbinary <- lm(Institutions.binary ~ Other.democracies, data=d_gandhi)
summary(m_ftestbinary)

# ---- Construct my own data ----
d_dd <- read.dta("./data/public//ddrevisited_data_v1.dta") # Only cover upto 2008

# Calculate other democracies percentage
d_polity_raw <- PolityGet(vars="polity2")
d_polity <- d_polity_raw %>% mutate(polity2_binary = ifelse(polity2 > 0, 1, 0))
d_other_dem <- ddply(d_polity, .(year), summarize, Other.democracies = mean(polity2_binary, na.rm=T))

d_dpi_raw <- DpiGet(vars=c("liec"))
d_dpi <- d_dpi_raw  %>%
  mutate(liec = ifelse(liec==-999.0, NA, liec)) %>%
  mutate(liec7 = ifelse(liec >= 7, 1, 0))

d_iv_test <- merge(d_dpi, d_other_dem, by=c("year"), all=T)

summary(lm(liec7 ~ Other.democracies, data=d_iv_test))
summary(lm(liec7 ~ Other.democracies, data=filter(d_iv_test, year >= 1991)))
