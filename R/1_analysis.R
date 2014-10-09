# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("lme4", "arm", "nlme", "dplyr", "ggplot2")
f_install_and_load(packs)
# Load data
load('./data/data_final.RData')

# Rescale data
vars <- c("liec", "legis_multi", "gdp", "gdppc", "milexp", 
          "gwf_military", "gwf_personal", "gwf_party", "gwf_monarchy")

d_disgov_scaled <- modifyList(d_disgov_merged_full, 
  lapply(d_disgov_merged_full[,vars], f_center_and_scale))
d_disgovsect_scaled <- modifyList(d_disgovsect_merged_full,
  lapply(d_disgovsect_merged_full[,vars], f_center_and_scale))

fm_unrestricted <- formula("goldstein_avg ~ 1 + legis_multi + gdp + gdppc +
                            (1 | country) + (1 | year) + (1 | source_actor_id)")
fm_restricted <- formula("goldstein_avg ~ 1 + gdp + gdppc +
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


fm_sect_unrestricted <- formula("goldstein_avg ~ 1 + gdp + gdppc + milexp + legis_multi +
                            gwf_military + gwf_personal + gwf_party + gwf_monarchy +
                            (1 | country) + (1 | year) + (1 + legis_multi | source_sector_name)")
fm_sect_restricted <- formula("goldstein_avg ~ 1 + gdp + gdppc + milexp +
                            gwf_military + gwf_personal + gwf_party + gwf_monarchy +
                            (1 | country) + (1 | year) + (1 | source_sector_name)")

#compute a model where the effect of status is estimated
# REML = F since we want to compare the likelihood
m_sect_unrestricted = lmer(data=d_disgovsect_scaled, formula = fm_sect_unrestricted, REML = F)
#compute a model where the effect of status is estimated
m_sect_restricted = lmer(data=d_disgovsect_scaled, formula = fm_sect_restricted, REML = F)
anova(m_sect_unrestricted, m_sect_restricted)

summary(m_sect_unrestricted)
coef(m_sect_unrestricted)

tmp <- ranef(m_sect_unrestricted, condVar=TRUE)
est <- tmp$source_sector_name[, 2, drop=FALSE]
se <- attr(tmp$source_sector_name, "postVar")[2 , 2, ]

# Plot confidence interval
res <- data.frame(cbind(est, est + qnorm(0.975) * se, est - qnorm(0.975) * se))
res$varname <- row.names(res)
ggplot(data=res, aes(x=varname)) + 
  geom_pointrange(aes(y=legis_multi, ymax=legis_multi.1, ymin=legis_multi.2)) +
  geom_hline(aes(yintercept=0), col="red") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
