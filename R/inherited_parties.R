# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("plyr", "dplyr")
f_install_and_load(packs)

# ---- Load data ----

d_inherited <- read.csv("./data//private/Pol_Inst_Dictatorship_Data.csv")
tmp <- d_inherited %>%  
  select(Country.name, Year, Inherited.parties) %>%
  group_by(Country.name) %>%
  summarize(inherited.distinct = n_distinct(Inherited.parties))
