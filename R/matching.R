# ---- Set up workspace ----
rm(list=ls())
source("./R/functions.R")
packs <- c("plyr")
f_install_and_load(packs) ; rm(packs)

# ---- Load data ----

load("./data/private/countrylevel.RData")
