# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("WDI", "countrycode", "MatchIt", "Amelia", "plyr", "dplyr")
f_install_and_load(packs) ; rm(packs)

# ---- Load data ----
d_gandhi_raw <- read.csv("./data/private/Pol_Inst_Dictatorship_Data.csv")
d_gandhi <- d_gandhi_raw %>% 
  filter(Year >= 1991) %>%
  mutate(Institutions.binary = ifelse(Institutions==2, 1, 0)) %>%
  mutate(iso3c = countrycode(Country.name, origin="country.name", destination="iso3c", warn=T)) %>%
  mutate(year = Year) %>%
  select(-Capital.stock.growth, -Labor.force.growth, -Education.growth)

fm_gandhi <- formula("Institutions.binary ~ Military.dictator + Civilian.dictator + Inherited.parties + Ethnic.polarization +
                             Purges + Other.democracies + Leadership.changes + Resources")
tmp <- select(d_gandhi, Country.name, Year, Institutions.binary, Military.dictator, Civilian.dictator, Inherited.parties, Ethnic.polarization,
        Purges, Other.democracies, Leadership.changes, Resources)
d_tmp <- na.omit(tmp)


# Let's try matching without imputation
matched_gandhi <- matchit(fm_gandhi, data=na.omit(tmp), method="nearest")
summary(matched_gandhi)
# plot(matched_gandhi)

d_matched <- match.data(matched_gandhi)
matched.data.original <- d_tmp[row.names(d_tmp)%in%row.names(match.data(matched_gandhi)),]

matched.data.original <- matched.data.original %>%
  mutate(iso3c = countrycode(Country.name, origin="country.name", destination="iso3c", warn=T)) %>%
  mutate(year = Year)

# imp_gandhi <- amelia(d_gandhi, m= 5, cs="Country.name", ts="Year", parallel="snow", ncpus=4)

# imp_gandhi has 5 imputed dataset

# Load violence data
load('./data/private/data_final.RData')
d_violence_count <- d_disgov_merged_full %>%
  group_by(iso3c, year) %>%
  summarize(sum_neg_count = sum(goldstein_neg_count))

d_violence_matched <- merge(matched.data.original, d_violence_count, by=c("iso3c", "year"))

# GDP constant 2005 dollar, GDP per cap constant 2011 dollars, mil exp %GDP, 
WDI_INDICATORS <- c("NY.GDP.MKTP.KD", "NY.GDP.PCAP.PP.KD", "MS.MIL.XPND.GD.ZS")
d_wdi_raw <- WDI(country="all", indicator=WDI_INDICATORS,
                 start=1991, end=2008, extra=TRUE)
d_wdi <- d_wdi_raw %>%
  mutate(milexp = MS.MIL.XPND.GD.ZS * NY.GDP.MKTP.KD) %>%
  select(iso3c, year, country, gdp=NY.GDP.MKTP.KD, gdppc=NY.GDP.PCAP.PP.KD,
         milexp, region) %>%
  arrange(iso3c, year)

# Merge
d_violence_matched_full <- merge(d_violence_matched, d_wdi, by=c("iso3c", "year"))

fm_violence_matched <- formula("sum_neg_count ~ Institutions.binary + Military.dictator + Civilian.dictator + Ethnic.polarization +
                               Resources + log(gdp) + gdppc + milexp")
m_violence_matched <- lm(fm_violence_matched, data = d_violence_matched_full)
summary(m_violence_matched)

# Other democracies as IV?
with(d_gandhi_raw, cor(Other.democracies, Institutions, use="complete.obs"))

summary(lm(Institutions ~ Other.democracies, data=d_gandhi_raw))


d_tmp <- merge(d_violence_count, d_gandhi, by=c("iso3c", "year"))
# do regressions for partial F-tests
# first-stage:
fs = lm(sum_neg_count ~ Institutions + Other.democracies, data = d_tmp)
# null first-stage (i.e. exclude IVs):
fn = lm(sum_neg_count ~ Institutions, data = d_tmp)
# simple F-test
waldtest(fs, fn)$F[2]
# F-test robust to heteroskedasticity
waldtest(fs, fn, vcov = vcovHC(fs, type="HC0"))$F[2]
