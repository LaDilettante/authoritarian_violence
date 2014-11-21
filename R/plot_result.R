rm(list=ls())

library(scales)

load("./data/private/multilevel_mcmc_result.RData")

quantile(reg.fit$BUGSoutput$sims.matrix[,"g.liec"], c(.025, .05, .5, .95, .975))
mean(reg.fit$BUGSoutput$sims.matrix[,"g.liec"] > 0)

varnames <- c("g.liec")
printablenames <- c("legislature")
pdf("./fig/mcmc_legis.pdf", 7, 4)
par(mfrow=c(1, 2))
for (i in seq_along(varnames)) {
  plot(reg.fit$BUGSoutput$sims.matrix[, varnames[i]], type="l", 
       main=paste("Traceplot of", printablenames[i]), ylab="Estimate")
  plot(density(reg.fit$BUGSoutput$sims.matrix[, varnames[i]]),
       main=paste("Posterior of", printablenames[i]))
  abline(v=0, col="red")
}
par(mfrow=c(1, 1))
dev.off()

varnames <- c("G[1]", "G[2]", "G[3]", "G[4]")
printablenames <- c("log(GDP percap)", "log(GDP)", "resource (%GDP)", "military exp (%GDP)")
pdf("./fig/mcmc_diagnostic1.pdf", 8.5, 11)
par(mfrow=c(length(varnames), 2))
for (i in seq_along(varnames)) {
  plot(reg.fit$BUGSoutput$sims.matrix[, varnames[i]], type="l", 
       main=paste("Traceplot of", printablenames[i]), ylab="Estimate")
  plot(density(reg.fit$BUGSoutput$sims.matrix[, varnames[i]]),
       main=paste("Posterior distribution of", printablenames[i]))
  abline(v=0, col="red")
}
par(mfrow=c(1, 1))
dev.off()

varnames <- c("G[5]", "G[6]", "G[7]", "G[8]")
printablenames <- c("regime duration", "military regime", "personal regime", "party regime")
pdf("./fig/mcmc_diagnostic2.pdf", 8.5, 11)
par(mfrow=c(length(varnames), 2))
for (i in seq_along(varnames)) {
  plot(reg.fit$BUGSoutput$sims.matrix[, varnames[i]], type="l", 
       main=paste("Traceplot of", printablenames[i]), ylab="Estimate")
  plot(density(reg.fit$BUGSoutput$sims.matrix[, varnames[i]]),
       main=paste("Posterior distribution of", printablenames[i]))
  abline(v=0, col="red")
}
par(mfrow=c(1, 1))
dev.off()