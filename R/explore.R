# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("lme4", "nlme", "plyr", "dplyr")
f_install_and_load(packs)
# Load data
load('./data/data_final.RData')

#---- Missingness ----

# Count
tmp <- d_merged %>%
  group_by(country, year) %>%
  summarize(count = n())
tmp2 <- d_merged_full %>%
  group_by(country, year) %>%
  summarize(count = n())

names(d_merged)

# Missing data for each country year
tmp <- ddply(d_merged_full, c("country", "year"), colwise(function(x) as.numeric(any(is.na(x)))))
# Missing data for each country
tmp2 <- ddply(tmp[ ,-2], c("country"), colwise(function(x) sum(x)))  

#---- Summary statistics ----

unique(d_merged$source_sector_name)

