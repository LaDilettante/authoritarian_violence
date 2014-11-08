# ---- Plan ----
# We match on country level characteristics, get the id of the treated and untreated
# Then go back to actor level dataset with those id
# --------------

# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("plyr", "dplyr", "ggplot2")
f_install_and_load(packs)

# Load data
load('./data/private/countrylevel.RData')

f_turn_country_into_panel <- function(df, t=5, idvar="country", timevar="year", drop=NULL) {
  n <- length(unique(df$year))
  # Create moving windows of length t. First window starts at 1, last window starts at n - t + 1
  idx <- lapply(1:(n-t+1), FUN=`+`, 0:(t-1))
  # Create a list of short panels
  short_panels <- lapply(idx, function(i) 
    data.frame(df[i, setdiff(names(df), "year")], year=0:4))
  # Name that list
  names(short_panels) <- df$year[1:(n-4)]
  # Convert each short panel in the list from long to wide
  widened_short_panels <- lapply(short_panels, reshape, 
                                 idvar=idvar, timevar=timevar, drop=drop, direction="wide")
  # rbind and returns those widened panels
  res <- do.call(rbind, args=widened_short_panels)
  res <- data.frame(start.year = rownames(res), res)
  return(res)
}

d_long <- select(d_countrylevel, country, year, goldstein_avg, resource.pc,
                               land, population, gdp, gdppc, milexp.pc, 
                               gwf_military, gwf_personal, gwf_party, gwf_monarchy,
                               ethnic.polarization)

d_wide <- ddply(d_long, .(country),
             f_turn_country_into_panel, t=5, idvar="country", timevar="year")
d_wide <- merge(d_wide, d_countrylevel[ , c("country", "year", "liec7")], 
                     by.x=c("country", "start.year"), by.y=c("country", "year"))
d_wide <- na.omit(d_wide)

# Model propensity
m_psfit <- glm(liec7 ~ ., data=select(d_wide, -country, -start.year), family=binomial(link="logit"))
summary(m_psfit)

# Calculate propensity score
pscore1 <- predict(m_psfit, type="link")
pscore2 <- predict(m_psfit, type="response")

# Check propensite score model fit
predicted.liec7 <- ifelse(pscore2 >= 0.5, 1, 0)
table(predicted.liec7, m_psfit$y)

# Retrieve the matched sample (without replacement)
matches <- f_matching(z=m_psfit$y, score=pscore1, replace=TRUE)
d_wide_matched <- d_wide[matches$matched, ]

# Show the matches
matches$original <- as.numeric(rownames(matches))
rownames(matches) <- NULL
matches <- filter(matches, matched != 0)

tmp1 <- d_wide[matches$original, c("country", "start.year")]
tmp2 <- d_wide[matches$matched, c("country", "start.year")]
rownames(tmp1) <- NULL
rownames(tmp2) <- NULL
tmp <- cbind.data.frame(tmp1, tmp2)

# Check balance
length(pscore1)

d_wide_score <- cbind.data.frame(d_wide, pscore1)

ggplot(data=d_wide_score, aes(x=pscore1)) +
  geom_histogram(data=subset(d_wide_score, liec7==0), fill="red", alpha=0.2) +
  geom_histogram(data=subset(d_wide_score, liec7==1), fill="blue", alpha=0.2)

d_wide_matched_score <- cbind.data.frame(d_wide_matched,
                                         pscore1=pscore1[matches$matched])
ggplot(data=d_wide_matched_score, aes(x=pscore1)) +
  geom_histogram(data=subset(d_wide_matched_score, liec7==0), fill="red", alpha=0.2) +
  geom_histogram(data=subset(d_wide_matched_score, liec7==1), fill="blue", alpha=0.2)
