# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("R2jags", "plyr", "dplyr", "countrycode")
f_install_and_load(packs)

# ---- Load data ----
load("./data/private/actorsectlevel.RData")

# Set up JAGS model
# JAGS needs a list of names that contain the data
reg.data = list("y", "countryyear", "T", "z")

# JAGS also needs a list of names of parameters
# need phi.y in addition to sigma.y?
reg.params = c("g0", "g1", "m0", "m1", 
               "sigma.y", "sigma.a", "sigma.T", "rho.aT")

# Initial values of parameters are optional; JAGS can compute
# its own initial values, but sometimes they can be a little crazy
# reg.initial = list(list("beta0"=0, "beta1"=0, "phi"=1))

# The actual model and priors need to be contained in a function
reg.model <- function() {
  #Model structure
  for (i in 1:N){
    y[i] ~ dnorm(a[countryyear[i]], sigma.y)
  }
  for (i in 1:J) {
    aT[j,] ~ dmnorm(aT.hat[j, ], Tau.aT[,])
    aT.hat[j, 1] <- g0 + g1 * T[j]
    aT.hat[j, 2] <- m0 + m1 * z[j] 
  }

  # Priors
  sigma.y <- 1 / phi.y
  phi.y   ~ dgamma(1,1)
  
  Tau.aT[ , ] <- inverse(Sigma.aT[ , ])
  sigma.a ~ dunif(0, 100)
  Sigma.aT[1, 1] <- pow(sigma.a, 2)
  sigma.T ~ dunif(0, 100)
  sigma.aT[2, 2] <- pow(sigma.T, 2)
  rho.aT ~ dunif(-1,1)
  Sigma.aT[1, 2] <- rho.aT * sigma.a * sigma.T
  Sigma.aT[2, 1] <- Sigma.at[1, 2]

  g0 ~ dnorm(0, .0001)
  g1 ~ dnorm(0, .0001)
  m0 ~ dnorm(0, .0001)
  m1 ~ dnorm(0, .0001)
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
reg.fit = jags(data=reg.data, 
               parameters.to.save=reg.params,
               inits=reg.initial,
               n.chains=1,
               n.thin=1,
               n.iter=11000, n.burnin=1000, 
               model.file=reg.model)
