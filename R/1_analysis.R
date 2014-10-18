# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("lme4", "arm", "nlme", "plyr", "dplyr", "ggplot2")
f_install_and_load(packs)
# Load data
load('./data/private/data_final.RData')

# Rescale data
vars <- c("liec", "legis_multi", "gdp", "gdppc", "milexp", 
          "gwf_military", "gwf_personal", "gwf_party", "gwf_monarchy")
d_disgov_scaled <- modifyList(d_disgov_merged_full, 
  lapply(d_disgov_merged_full[,vars], f_center_and_scale))
d_disgovsect_scaled <- modifyList(d_disgovsect_merged_full,
  lapply(d_disgovsect_merged_full[,vars], f_center_and_scale))

# ---- Analysis ----

# Create list of formula
fm_controls <- "1 + gdp + gdppc + gwf_military + gwf_personal + gwf_party"
fm_iv <- c("liec", "legis_multi")
fm_dv <- c("goldstein_avg", "goldstein_sum", "goldstein_pos_count", "goldstein_neg_count")
fm_re <- "(1 | country) + (1 | year) + (1 + legis_multi | source_sector_name)"

res <- list()
for (iv in fm_iv) {
  res_lmer <- list()
  for (dv in fm_dv) {
    fm_unrestricted_list <- formula(paste(dv, "~", iv, "+", fm_controls, "+", fm_re))
    fm_restricted_list <- formula(paste(dv, "~", fm_controls, "+", fm_re))
    m_unrestricted <- lmer(fm_unrestricted_list, data=d_disgov_merged_full, REML=F)
    m_restricted <- lmer(fm_restricted_list, data=d_disgov_merged_full, REML=F)
    res_lmer[[dv]] <- anova(m_unrestricted, m_restricted)["Pr(>Chisq)"]
  }
  res[[iv]] <- res_lmer
}

# Loop through each formula

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
