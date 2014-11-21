rm(list=ls())

library(scales)
library(dplyr)
library(xtable)
load("./data/private/multilevel_mcmc_result.RData")

varnames <- c("g.liec", "G[1]", "G[2]", "G[3]", "G[4]", "G[5]", "G[6]", "G[7]", "G[8]")
printnames <- c("legislature", "log(GDP percap)", "log(GDP)", "resource (%GDP)", "military exp (%GDP)",
                "regime duration", "military regime", "personal regime", "party regime")

tmp <- lapply(1:length(varnames), function(i) {
  c(quantile(reg.fit$BUGSoutput$sims.matrix[,varnames[i]], c(.5, .025, .975)),
    mean(reg.fit$BUGSoutput$sims.matrix[, varnames[i]] > 0))
})

mcmc_result <- data.frame(matrix(unlist(tmp), nrow=9, byrow=T)) %>%
  mutate(`95% interval` = paste(X2, X3)) %>%
  mutate(`Pr(param < 0)` = ifelse(X4 > 0.5, NA, 1 - X4)) %>%
  mutate(`Pr(param > 0)` = ifelse(X4 > 0.5, X4, NA)) %>%
  select(mean = X1, `2.5% quantile`=X2, `97.5% quantile`=X3, `Pr(param > 0)`, `Pr(param < 0)`)
rownames(mcmc_result) <- printnames

mcmc_result_tab <- xtable(mcmc_result)
digits(mcmc_result_tab) <- 2
print(mcmc_result_tab)

plot(density(reg.fit$BUGSoutput$sims.matrix[,"sigma.a"]))
