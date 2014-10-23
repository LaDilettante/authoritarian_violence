# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("plyr", "dplyr", "ggplot2")
f_install_and_load(packs) ; rm(packs)

# ---- Load data ----
load('./data/private/data_final.RData')

d_exp_before_trans_full <- d_exp_before_trans_full %>%
  filter(is.na(iso3c)==FALSE)

d_transition <- ddply(d_exp_before_trans_full, c("iso3c", "transition_year"), 
                      colwise(mean, .(liec, liec5, liec6, liec7,
                                      gwf_military, gwf_personal,
                                      gwf_party, gwf_monarchy), na.rm=TRUE))
d_transition2 <- merge(d_transition, d_exp_before_trans_full[ , c("iso3c", "year", "gdp", "gdppc", "milexp")],
                       by.x=c("iso3c", "transition_year"), by.y=c("iso3c", "year"))

d_violence <- ddply(d_disgov_merged_full, c("iso3c", "year"), summarize,
                    count = sum(goldstein_neg_count))

d_transition_violence <- merge(d_transition2, d_violence, 
                               by.x=c("iso3c", "transition_year"),
                               by.y=c("iso3c", "year"))

names(d_transition_violence)

m_transition <- lm(count ~ liec5 + log(gdp) + gdppc + milexp, data=d_transition_violence)
summary(m_transition)
