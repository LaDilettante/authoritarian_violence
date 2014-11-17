# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("R2jags", "plyr", "dplyr", "countrycode")
f_install_and_load(packs)

# ---- Load data ----
load("./data/private/eventlevel.RData")

# ---- Format data to fit into rjags ----

d_eventlevel <- d_eventlevel %>%
  select(year, country, event_id, goldstein, liec, liec5, liec6, liec7,
         resource.pc, land, population, milexp.pc, region, lgdppc,
         lgdp, ethnic.polarization, 
         gwf_military, gwf_personal, gwf_party, gwf_monarchy, gwf_duration) %>%
  mutate(countryyear = paste0(country, year)) %>%
  arrange(country, year)
d_eventlevel <- na.omit(d_eventlevel)

# ---- Set up index link ----
d_countryyear <- unique(select(d_eventlevel,
                               countryyear, country, resource.pc, milexp.pc,
                               liec, liec5, liec6, liec7, gwf_duration))
d_country <- unique(select(d_eventlevel, 
                           country, ethnic.polarization, region))
d_event <- unique(select(d_eventlevel,
                         event_id, countryyear, goldstein))

N <- nrow(d_event)
J <- nrow(d_countryyear)
K <- nrow(d_country)

countryyear.idx <- rep(NA, N)
for (j in (1:J)) {
  countryyear.idx[d_event$countryyear == d_countryyear$countryyear[j]] <- j
}
country.idx <- rep(NA, J)
for (k in (1:K)) {
  country.idx[d_countryyear$country == d_country$country[k]] <- k
}

# ---- Set up data ----
goldstein <- d_event$goldstein
liec <- d_countryyear$liec6
milexp.pc <- d_countryyear$milexp.pc
resource.pc <- d_countryyear$resource.pc
duration <- d_countryyear$gwf_duration
ethnic <- d_country$ethnic.polarization

# Set up JAGS model
# JAGS needs a list of names that contain the data
reg.data = list("goldstein", "liec", "milexp.pc", "resource.pc", "duration","ethnic",
                "countryyear.idx", "country.idx",
                "N", "J", "K")

# JAGS also needs a list of names of parameters
reg.params = c("a", "sigma.goldstein", "phi.goldstein",
               "b", "g.liec", "g.mil", "g.res", "g.dur", "sigma.a", "phi.a",
               "d.ethnic", "sigma.b", "phi.b")

# Initial values of parameters are optional; JAGS can compute
# its own initial values, but sometimes they can be a little crazy
# reg.initial = list(list("beta0"=0, "beta1"=0, "phi"=1))

# The actual model and priors need to be contained in a function
reg.model <- function() {
  # Model structure
  for (i in 1:N){
    goldstein[i] ~ dnorm(a[countryyear.idx[i]], sigma.goldstein)
  }
  sigma.goldstein <- 1 / phi.goldstein
  phi.goldstein ~ dgamma(1, 1)
  
  for (j in 1:J) {
    a[j] ~ dnorm(b[country.idx[j]] + g.liec*liec[j] + g.mil*milexp.pc[j] + 
                   g.res*resource.pc[j] + g.dur*duration[j], sigma.a)
  }
  sigma.a <- 1 / phi.a
  phi.a ~ dgamma(1, 1)
  g.liec ~ dnorm(0, .0001)
  g.mil ~ dnorm(0, .0001)
  g.res ~ dnorm(0, .0001)
  g.dur ~ dnorm(0, .0001)
  
  for (k in 1:K) {
    b[k] ~ dnorm(d.ethnic*ethnic[k], sigma.b)
  }
  sigma.b <- 1 / phi.b
  phi.b ~ dgamma(1, 1)
  d.ethnic ~ dnorm(0, .0001)
}

# Actually running the MCMC step.  JAGS lets you control:
# 1) Number of iterations to run (n.iter)
# 2) Number of burn-in samples to discard (n.burnin)
# 3) Number of draws to skip between valid samples aka thinning (n.thin)
# 4) Number of chains to run (n.chains)
#     Some statisticians suggest rerunning MCMC from different starting 
#     values to help judge whether your MCMC has converged to the true
#     posterior.  Each separate run of MCMC is called a chain. 
#     For simple problems, not necessary.
reg.fit <- jags(data=reg.data, 
               parameters.to.save=reg.params,
               n.chains=1,
               n.thin=2,
               n.iter=11000, n.burnin=1000, 
               model.file=reg.model)

# Trace plots
# traceplot(reg.fit)
# plot(reg.fit)

# Better plots!
# Convert JAGS output to an MCMC object
reg.fit.mcmc = as.mcmc(reg.fit)
# summary(reg.fit.mcmc)
# plot(reg.fit.mcmc)
# densityplot(reg.fit.mcmc)

quantile(reg.fit$BUGSoutput$sims.matrix[,"g.liec"], c(.025, .05, .5, .95, .975))
#HPDinterval(reg.fit.mcmc[,"g.liec"])

