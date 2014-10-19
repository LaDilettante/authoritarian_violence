# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("plyr", "dplyr", "ggplot2")
f_install_and_load(packs) ; rm(packs)

# ---- Load data ----
load('./data/private/data_final.RData')

# I have a bunch of country years
# Get the country and years 10 year before that



merge(d_tmp, )