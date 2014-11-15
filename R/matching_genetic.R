# ---- Plan ----
# We match on country level characteristics, get the id of the treated and untreated
# Then go back to actor level dataset with those id
# --------------

# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("gridExtra", "Matching", "plyr", "dplyr", "ggplot2")
f_install_and_load(packs) ; rm(packs)

# ---- Some constant ----
c_treatmentvar <- "liec6"
c_pretreat_length <- 1
c_posttreat_length <- 3
c_panel_length <- c_pretreat_length + c_posttreat_length
c_trainratio <- 0.5

# Load data
load('./data/private/countrylevel.RData')

# Select only authoritarian regimes
d_long <- d_countrylevel %>%
  filter(gwf_autocracy == 1) %>%
  select(country, year, goldstein_avg, resource.pc, lgdppc, lgdp, milexp.pc, 
         land, population, gwf_military, gwf_party, gwf_monarchy, gwf_duration, ethnic.polarization, 
         match(c_treatmentvar, names(d_countrylevel)))

# ---- Select universe of match-able cases ----

d_wide <- ddply(d_long, .(country), f_turn_country_into_panel, 
                t=c_panel_length, idvar="country", timevar="year")

# controlRows are the ones with treatment = 0 during all panel
controlRows <- apply(d_wide[, paste0(c_treatmentvar, ".", 0:c_posttreat_length)], 1, 
                 function(x) all(is.na(x))!=T & mean(x==rep(0, c_panel_length), na.rm=T)==1)
# treatRows are the ones with treatment = 0 during pretreat, treatment = 1 during posttreat
treatRows <- apply(d_wide[, paste0(c_treatmentvar, ".", 0:c_posttreat_length)], 1, 
                     function(x) { 
                       all(is.na(x))!=T & 
                         mean(x==c(rep(0, c_pretreat_length), rep(1, c_posttreat_length)), na.rm=T)==1
                       })
d_control_panel <- d_wide[controlRows, ]
d_treat_panel <- d_wide[treatRows, ]

# ---- Create the data frame to be matched, which is the first year in the panel ----
d_control_and_pretreat <- rbind.data.frame(d_control_panel, d_treat_panel)
# regex: not start with "liec", followed by any character one or more time, end with 0
firstyear_vars_idx <- grep("^(?!liec).+0$", names(d_control_and_pretreat), perl=T)
treatment_var_idx <- grep(paste0(c_treatmentvar, ".", c_pretreat_length), names(d_control_and_pretreat))

d_to_be_matched <- d_control_and_pretreat %>%
  select(start.year, country, firstyear_vars_idx, treatment_var_idx)
d_to_be_matched <- na.omit(d_to_be_matched)

Tr <- d_to_be_matched[ , grep(paste0(c_treatmentvar, ".", c_pretreat_length), names(d_to_be_matched))]
X <- select(d_to_be_matched, -start.year, -country, -liec6.1)
BalanceMatrix <- X %>%
  mutate(goldstein_avg.0.sq = goldstein_avg.0^2,
         gwf_duration.0.sq = gwf_duration.0^2,
         resource.ethnic = resource.pc.0 * ethnic.polarization.0)

# ---- Do the matching ----
gen1 <- GenMatch(Tr=Tr, X=X, BalanceMatrix=BalanceMatrix, pop.size=10000)
mgen1 <- Match(Tr=Tr, X=X, Weight.matrix=gen1)

balance_vars <- paste(c(names(BalanceMatrix)[1], paste("+", names(BalanceMatrix)[-1])), collapse=" ")
fm_gen1 <- as.formula(paste(paste0(c_treatmentvar, ".", c_pretreat_length), "~", balance_vars))
MatchBalance(fm_gen1, data=cbind.data.frame(liec6.1=Tr, BalanceMatrix), match.out=mgen1, nboots=1000)

par(mfrow=c(1, 2))
with(d_to_be_matched, 
     qqplot(goldstein_avg.0[mgen1$index.control], goldstein_avg.0[mgen1$index.treated]))
abline(coef=c(0, 1), col=2)
with(d_to_be_matched,
     qqplot(goldstein_avg.0[d_to_be_matched$liec6.1==0], goldstein_avg.0[d_to_be_matched$liec6.1==1]))
abline(coef=c(0, 1), col=2)
par(mfrow=c(1, 1))

# List of the match
d_matched_pairs <- cbind.data.frame(d_to_be_matched[mgen1$index.treated, c("country", "start.year")], 
                              d_to_be_matched[mgen1$index.control, c("country", "start.year")])
# FORGOT CANT match with itself!

# ---- Extract the matched sample ready for analysis ----
nrow(d_to_be_matched)

d_matched_firstyear <- rbind.data.frame(d_to_be_matched[mgen1$index.treated, c("country", "start.year")], 
                                        d_to_be_matched[mgen1$index.control, c("country", "start.year")])

f_expand <- function(row, num_expand=c_panel_length) {
  data.frame(country=rep(row$country, num_expand),
             year=row$start.year + 0:(num_expand-1))
}
d_matched_allyears <- adply(d_matched_firstyear, 1, f_expand, num_expand=c_panel_length, .inform=T)
d_matched_panel <- merge(d_matched_panel, d_long, by=c("country", "year"))

# ---- Save the matched data ----
save(d_matched_panel, d_matched_pairs, file="./data/private/matched_panel.RData")