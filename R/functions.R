# Install and load packages
f_install_and_load <- function(packs) {
  new.packs <- packs[!(packs %in% installed.packages()[ ,"Package"])]
  lapply(new.packs, install.packages, repos="http://cran.rstudio.com/", dependencies=TRUE)
  lapply(packs, library, character.only=TRUE)
}

# Center and scale a variable
f_center_and_scale <- function(vector, num.sd = 2) {
  # num.sd is how many sd to divide by
  (vector - mean(vector, na.rm=T)) / (num.sd * sd(vector, na.rm=T))
}

# Create an environment that contains the stata var labels
f_stata_to_env <- function(df) {
  lab_env <- new.env()
  for (i in seq_along(names(df))) {
    lab_env[[names(df)[i]]] <- attr(df, "var.labels")[i]  
  }
  return(lab_env)
}

f_stata_to_df <- function(df) {
  lab_df <- data.frame(var.name = names(d_tmp),
                       var.label = attr(d_tmp, "var.labels"))
  return(lab_df)
}

# Re-order columns
# http://stackoverflow.com/questions/18339370/reordering-columns-in-a-large-dataframe
moveMe <- function(data, tomove, where = "last", ba = NULL) {
  temp <- setdiff(names(data), tomove)
  x <- switch(
    where,
    first = data[c(tomove, temp)],
    last = data[c(temp, tomove)],
    before = {
      if (is.null(ba)) stop("must specify ba column")
      if (length(ba) > 1) stop("ba must be a single character string")
      data[append(temp, values = tomove, after = (match(ba, temp)-1))]
    },
    after = {
      if (is.null(ba)) stop("must specify ba column")
      if (length(ba) > 1) stop("ba must be a single character string")
      data[append(temp, values = tomove, after = (match(ba, temp)))]
    })
  x
}

# Check if all rows of a data frame are unique
f_is_unique <- function(df, vars=NULL) {
  if (!(is.null(vars))) {
    df <- df[, vars]
  }
  nrow(df) == nrow(unique(df))
}

# Matching function (from the arm package)
f_matching <- function (z, score, replace = FALSE) 
{
  if (replace) {
    nt <- sum(z)
    nc <- length(z) - nt
    cnts <- rep(0, nc)
    scorec <- score[z == 0]
    scoret <- score[z == 1]
    indc <- NULL
    nearest <- rep(NA, nt)
    ind.mt <- matrix(0, nc, nt)
    ind.t <- (1:(nt + nc))[z == 1]
    for (j in 1:nt) {
      near <- (1:nc)[abs(scoret[j] - scorec) == min(abs(scoret[j] - 
                                                          scorec))]
      if (length(near) == 1) {
        nearest[j] <- near
        indc <- c(indc, near)
      }
      else {
        nearest[j] <- near[sample(1:length(near), 1, 
                                  replace = F)]
        indc <- c(indc, nearest[j])
      }
      cnts[nearest[j]] <- cnts[nearest[j]] + 1
      ind.mt[nearest[j], cnts[nearest[j]]] <- ind.t[j]
    }
    ind.mt <- ind.mt[ind.mt[, 1] != 0, 1:max(cnts)]
    ind <- numeric(nt + sum(cnts))
    ind[1:nt] <- (1:(nt + nc))[z == 1]
    tmp <- (1:(nt + nc))[z == 0]
    ind[(nt + 1):length(ind)] <- tmp[indc]
    out <- list(matched = unique(ind), pairs = matrix(ind, 
                                                      length(ind)/2, 2), ind.mt = ind.mt, cnts = cnts)
  }
  if (!replace) {
    n <- length(score)
    matched <- rep(0, n)
    pairs <- rep(0, n)
    b <- (sum(z) < n/2) * 1
    tally <- 0
    for (i in (1:n)[z == b]) {
      available <- (1:n)[(z != b) & (matched == 0)]
      j <- available[order(abs(score[available] - score[i]))[1]]
      matched[i] <- j
      matched[j] <- i
      tally <- tally + 1
      pairs[c(i, j)] <- tally
    }
    out <- cbind.data.frame(matched = matched, pairs = pairs)
  }
  return(out)
}