# ---- Plan ----
# We match on country level characteristics, get the id of the treated and untreated
# Then go back to actor level dataset with those id
# --------------

# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("gridExtra", "arm", "plyr", "dplyr", "ggplot2")
f_install_and_load(packs) ; rm(packs)

# Load data
load('./data/private/countrylevel.RData')

# Select only authoritarian regimes
d_long <- d_countrylevel %>%
  filter(gwf_autocracy == 1) %>%
  select(country, year, goldstein_avg, resource.pc,
         lgdppc, lgdp, land, population, milexp.pc,
         gwf_military, gwf_party, gwf_monarchy, gwf_duration,
         ethnic.polarization)

# Pad data so that all country year are present
d_long_pad <- ddply(d_long, .(country), f_pad_countryyear)
d_long <- merge(d_long, d_long_pad, by=c("country", "year"), all=T)

# Transform d_long to d_wide of short panels
d_wide <- ddply(d_long, .(country),
             f_turn_country_into_panel, t=2, idvar="country", timevar="year", .inform=TRUE)
d_wide <- merge(d_wide, d_countrylevel[ , c("country", "year", "liec7")], 
                     by.x=c("country", "after.year"), by.y=c("country", "year"), all.x=T)
d_wide <- d_wide[ , as.logical(1 - grepl("(land|ethnic.polarization|gwf_duration).[1-4]", names(d_wide)))]
# d_wide <- select(d_wide, -goldstein_avg_growth.0)

# Select the pretreatment country years
d_legislature_transition <- f_find_transition_point(filter(d_countrylevel, gwf_autocracy==1), varname="liec7",
                                                    keep=c("country", "year"))
d_pretreatment <- merge(d_wide, d_legislature_transition, 
                        by.x=c("country", "after.year"), by.y=c("country", "year"), all.y=T)
d_tmp <- merge(d_long, d_legislature_transition, by=c("country", "year"))
# d_pretreatment too small?
# d_legislature_transition <- mutate(d_legislature_transition, year.before=year-1)
# tmp <- merge(d_countrylevel, d_legislature_transition, by.x=c("country", "year"), by.y=c("country", "year.before"), all.y=T)

# Select the control (never treated) country years
d_control <- ddply(d_wide, .(country), f_find_never_treated)

# ---- Model propensity (with cross validation) ----
d_control_and_pretreatment <- na.omit(rbind.data.frame(d_control, d_pretreatment))
d_wide <- na.omit(d_wide)

set.seed(100)
train <- sample(1:nrow(d_control_and_pretreatment), nrow(d_control_and_pretreatment) / 2)

m_pstrain <- glm(liec7 ~ .,
               data=select(d_control_and_pretreatment[train, ], -country, -start.year, -after.year), 
               family=binomial(link="logit"))
summary(m_pstrain)

# Calculate propensity score and check predictive fit
pscore_train <- predict(m_pstrain, newdata=d_control_and_pretreatment[-train, ], type="response")
predicted.liec7 <- ifelse(pscore_train >= 0.5, 1, 0)
table(predicted.liec7, real.liec7=d_control_and_pretreatment[-train, "liec7"])

# ---- Model propensity (whole sample) ----

m_psfit <- glm(liec7 ~ .,
                 data=select(d_control_and_pretreatment, -country, -start.year, -after.year), 
                 family=binomial(link="logit"))
summary(m_psfit)
pscore_fit <- predict(m_psfit, type="response")
predicted.liec7.fit <- ifelse(pscore_fit >= 0.5, 1, 0)
table(predicted.liec7.fit, real.liec7.fit=d_control_and_pretreatment[, "liec7"])


matches <- matching(z=m_psfit$y, score=pscore_fit, replace=TRUE)
d_wide_matched <- d_wide[matches$matched, ]
pscore_fit_matched <- pscore_fit[matches$matched]

# ---- Match with other countries ----

# pscore_fit 1102 score
# d_wide 1102 row

d_to_be_matched <- cbind.data.frame(d_wide[, c("country", "start.year", "liec7")], pscore_fit)

f_match_with_other_countries <- function(df, countryname, year) {
  df_countryyear <- filter(df, country == countryname, start.year == year)
  df_other <- filter(df, country != countryname)
  near_idx <- which(abs(df_countryyear$pscore - df_other$pscore) == min(abs(df_countryyear$pscore - df_other$pscore)))
  if (length(near_idx)==1) {
    nearest_idx <- near_idx
  } else {
    nearest_idx <- sample(near_idx, size=1, replace=F)
  }
  out <- data.frame(country.treat = df_countryyear$country, year.treat = df_countryyear$start.year,
                    country.match = df_other[nearest_idx, "country"], year.match = df_other[nearest_idx, "start.year"])
  return(out)
}

f_match_with_other_countries(d_to_be_matched, countryname="Albania", year=1994)

# Show the matches
matches$original <- 1:length(matches$matched)
tmp1 <- d_wide[matches$original, c("country", "start.year")]
tmp2 <- d_wide[matches$matched, c("country", "start.year")]
rownames(tmp1) <- NULL
rownames(tmp2) <- NULL
d_tmp <- cbind.data.frame(tmp1, tmp2)


# ---- Plot balance (pre and post matching) ----


d_plot_prematching <- cbind.data.frame(liec7=d_wide$liec7, pscore=pscore_fit)
p1 <- ggplot(data=d_plot_prematching, aes(x=pscore, fill=as.factor(liec7))) + 
  geom_histogram(alpha=0.2, position="identity")



d_plot_postmatching <- cbind.data.frame(liec7=d_wide_matched$liec7, pscore=pscore_fit_matched)
p2 <- ggplot(data=d_plot_postmatching, aes(x=pscore, fill=as.factor(liec7))) + 
  geom_histogram(alpha=0.2, position="identity")

grid.arrange(p1, p2)

# Retrieve the matched sample (with replacement)