# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("lme4", "nlme", "dplyr")
f_install_and_load(packs)
# Load data
load('./data/data_final.RData')

# Rescale data
vars <- c("goldstein_avg", "liec", "legis_multi", "gdp", "gdppc", "milexp", 
          "gwf_military", "gwf_personal", "gwf_party", "gwf_monarchy")

d_merged_full[,vars] <- apply(d_merged_full[,vars], 2, f_center_and_scale)

fm_unrestricted <- formula("goldstein_avg ~ 1 + legis_multi + gdp + gdppc +
                            gwf_military + gwf_personal + gwf_party + milexp +
                            (1 | country) + (1 | year) + (1 | source_actor_id)")
fm_restricted <- formula("goldstein_avg ~ 1 + gdp + gdppc +
                            gwf_military + gwf_personal + gwf_party + milexp +
                            (1 | country) + (1 | year) + (1 | source_actor_id)")

#compute a model where the effect of status is estimated
# REML = F since we want to compare the likelihood
unrestricted_fit = lmer(data=d_merged_full, formula = fm_unrestricted, REML = F)
#compute a model where the effect of status is estimated
restricted_fit = lmer(data=d_merged_full, formula = fm_restricted, REML = F)
anova(restricted_fit, unrestricted_fit)

summary(unrestricted_fit)

#compute the AIC-corrected log-base-2 likelihood ratio (a.k.a. "bits" of evidence)
#(AIC(restricted_fit)-AIC(unrestricted_fit))*log2(exp(1))


