# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("WDI", "psData", "foreign", "countrycode", "RMySQL", "sem", "plyr", "dplyr", "plm")
f_install_and_load(packs) ; rm(packs)

# ---- Weak instrument test (Gandhi data) ----
d_gandhi_raw <- read.csv("./data/private/Pol_Inst_Dictatorship_Data.csv")
d_gandhi <- d_gandhi_raw %>% 
  filter(Year >= 1991) %>%
  mutate(Institutions.binary = ifelse(Institutions==2, 1, 0)) %>%
  mutate(iso3c = countrycode(Country.name, origin="country.name", destination="iso3c", warn=T)) %>%
  mutate(year = Year) %>%
  select(-Capital.stock.growth, -Labor.force.growth, -Education.growth)


m_ftest <- lm(Institutions ~ Other.democracies, data=d_gandhi)
summary(m_ftest)
m_ftestbinary <- lm(Institutions.binary ~ Other.democracies, data=d_gandhi)
summary(m_ftestbinary) # F statistic = 30, > 10 --> OK

# ---- Weak instrument test (Polity data) ----
# d_dd <- read.dta("./data/public//ddrevisited_data_v1.dta") # Only cover upto 2008

# Calculate other democracies percentage
d_polity_raw <- PolityGet(vars="polity2")
d_polity <- d_polity_raw %>% mutate(polity2_binary = ifelse(polity2 > 0, 1, 0))
d_other_dem <- ddply(d_polity, .(year), summarize, Other.democracies = mean(polity2_binary, na.rm=T))

d_dpi_raw <- DpiGet(vars=c("liec"))
d_dpi <- d_dpi_raw  %>%
  mutate(liec = ifelse(liec==-999.0, NA, liec)) %>%
  mutate(liec7 = ifelse(liec >= 7, 1, 0))

d_iv_test <- merge(d_dpi, d_other_dem, by=c("year"), all=T)
# Run test
summary(lm(liec7 ~ Other.democracies, data=d_iv_test))
summary(lm(liec7 ~ Other.democracies, data=filter(d_iv_test, year >= 1991)))
with(d_iv_test, cor(liec7, Other.democracies, use="complete.obs"))
with(filter(d_iv_test, year >= 1991), cor(liec7, Other.democracies, use="complete.obs"))

# ----- Instrumental variable regression ----
# Download violence data
load("./data/private/credentials.RData") # Load credentials
db.my_tables = dbConnect(MySQL(), dbname='my_tables', host=credentials[["host"]],
                         user=credentials[["username"]], password=credentials[["password"]])
qr_disgov = dbSendQuery(db.my_tables, "SELECT * FROM anh_dis_and_gov_aggregate_country")
d_disgov_raw = fetch(qr_disgov, n=-1)
d_disgov <- d_disgov_raw %>%
  select(iso3c = country_ISOA3Code, year,
         country = country_name,
         goldstein_avg, goldstein_sum, goldstein_pos_count, goldstein_neg_count)

d_instrument <- merge(d_gandhi, d_disgov, by=c("iso3c", "year"))

m_sum <- tsls(goldstein_sum ~ Institutions.binary + Military.dictator + Civilian.dictator + 
                       Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land,
                     ~ Other.democracies + Military.dictator + Civilian.dictator + 
                       Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land,
                     data=d_instrument)
summary(m_sum)

m_neg_count <- tsls(goldstein_neg_count ~ Institutions.binary + Military.dictator + Civilian.dictator + 
                      Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land,
                    ~ Other.democracies + Military.dictator + Civilian.dictator + 
                      Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land,
                    data=d_instrument)
summary(m_neg_count)

m_pos_count <- tsls(goldstein_pos_count ~ Institutions.binary + Military.dictator + Civilian.dictator + 
                      Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land,
                    ~ Other.democracies + Military.dictator + Civilian.dictator + 
                      Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land,
                    data=d_instrument)
summary(m_pos_count)

# Use panel data package

dp_instrument <- plm.data(d_instrument, index=c("Country", "year"))
summary(plm(goldstein_neg_count ~ Institutions.binary + Military.dictator + Civilian.dictator + Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land |
              Other.democracies + Military.dictator + Civilian.dictator + Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land, 
              data=dp_instrument, model = "random"))


d_instrument[which(duplicated(d_instrument[,c("Country", "year")])), c("Country", "year")]

d_instrument_pruned <- d_instrument[!abs(scale(d_instrument$goldstein_sum)) > 2,]
summary(plm(goldstein_pos_count ~ Institutions.binary + Military.dictator + Civilian.dictator + Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land |
              Other.democracies + Military.dictator + Civilian.dictator + Military.spending + Inherited.parties + Resources + Ethnic.polarization + Land, 
            data=d_instrument_pruned, index=c("Country", "year"), model = "random"))