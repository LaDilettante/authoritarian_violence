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

f_turn_country_into_panel <- function(df, t=5, idvar="country", timevar="year", drop=NULL) {
  n <- length(unique(df$year))
  if (n >= t) {
    # Create moving windows of length t. First window starts at 1, last window starts at n - t + 1
    idx <- lapply(1:(n-t+1), FUN=`+`, 0:(t-1))
    # Create a list of short panels
    short_panels <- lapply(idx, function(i) 
      data.frame(df[i, setdiff(names(df), "year")], year=0:(t-1)))
    # Add first difference to each short_panel
    # short_panels <- lapply(short_panels, function(df)
    #  mutate(df, goldstein_avg_growth=c(NA, diff(goldstein_avg) / goldstein_avg[-length(goldstein_avg)] * 100)))
    # Name that list
    names(short_panels) <- df$year[1:(n-4)]
    # Convert each short panel in the list from long to wide
    widened_short_panels <- lapply(short_panels, reshape, 
                                   idvar=idvar, timevar=timevar, drop=drop, direction="wide")
    # rbind and returns those widened panels
    res <- do.call(rbind, args=widened_short_panels)
    res <- data.frame(start.year = as.numeric(rownames(res)), 
                      end.year = as.numeric(rownames(res)) + t - 1, res)
    return(res)  
  }
}

BUT DO WE MATCH BEFORE TREATMENT OR WHAT?

d_long <- d_countrylevel %>%
  filter(polity2_binary == 0) %>%
  select(country, year, goldstein_avg, resource.pc,
         land, population, gdp, gdppc, milexp.pc, 
         gwf_military, gwf_personal, gwf_party, gwf_monarchy, gwf_duration,
         ethnic.polarization)
  
d_wide <- ddply(d_long, .(country),
             f_turn_country_into_panel, t=5, idvar="country", timevar="year")

f_turn_country_into_panel(filter(d_long, country=="Albania"), t=5, idvar="country", timevar="year")

d_wide <- merge(d_wide, d_countrylevel[ , c("country", "year", "liec7")], 
                     by.x=c("country", "end.year"), by.y=c("country", "year"))
d_wide <- d_wide[ , as.logical(1 - grepl("(land|ethnic.polarization).[1-4]", names(d_wide)))]
# d_wide <- select(d_wide, -goldstein_avg_growth.0)

# ---- Model propensity (with cross validation) ----
d_wide <- na.omit(d_wide)
set.seed(1023)
train <- sample(c(T, F), size=nrow(d_wide), replace=TRUE, prob=c(0.75, 0.25))

m_pstrain <- glm(liec7 ~ .,
               data=select(d_wide[train, ], -country, -start.year, -end.year), 
               family=binomial(link="logit"))
summary(m_pstrain)

# Calculate propensity score and check predictive fit
pscore_train <- predict(m_pstrain, newdata=d_wide[-train, ], type="response")
predicted.liec7 <- ifelse(pscore_train >= 0.5, 1, 0)
table(predicted.liec7, d_wide[-train, "liec7"])

# ---- Model propensity (whole sample) ----

m_psfit <- glm(liec7 ~ .,
                 data=select(d_wide, -country, -start.year, -end.year), 
                 family=binomial(link="logit"))
summary(m_psfit)
pscore_fit <- predict(m_psfit, type="link")

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