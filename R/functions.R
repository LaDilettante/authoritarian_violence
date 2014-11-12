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
f_matching_arm <- function (z, score, replace = FALSE) 
{
  if (replace) {
    nt <- sum(z) # Number of treated units
    nc <- length(z) - nt # Number of controlled units
    cnts <- rep(0, nc)
    scorec <- score[z == 0]
    scoret <- score[z == 1]
    indc <- NULL
    nearest <- rep(NA, nt)
    ind.mt <- matrix(0, nc, nt)
    ind.t <- (1:(nt + nc))[z == 1]
    for (j in 1:nt) {
      # near is the index (among the controls 1:nc) of the nearest control
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
      # nearest is a vector of length = # treated, showing the index of the nearest control
      # cnts is a vector of length = # control, each element is how many treated unit being matched to that control
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

# My matching function
f_matching <- function(z, score, replace=FALSE) {
  if (replace) {
    n <- length(score)
    nc <- sum(z == 0)
    nt <- sum(z == 1)
    matched <- rep(0, n)
    scorec <- score[z == 0]
    scoret <- score[z == 1]
    for (i in (1:nt)) {
      near <- (1:nc)[abs(scoret[i] - scorec) == min(abs(scoret[i] - scorec))]
      if (length(near) == 1) {
        nearest[j] <- near
        indc <- c(indc, near)
      } else {
        nearest[j] <- near[sample(1:length(near), 1, 
                                  replace = F)]
        indc <- c(indc, nearest[j])
      }
    }
  }
}

# Find transition point
f_find_transition_point <- function(df, varname="democracy", keep=NULL) {
  df <- df[!is.na(df[ , varname]), ]
  
  wanted_rows <- data.table:::uniqlist(df[ , varname, drop=FALSE])[-1] # -1 to get rid of the first row
  
  df_transition <- data.frame(df[wanted_rows, ],
                              previous_value=df[wanted_rows - 1, varname])
  df_transition_into_treatment <- df_transition[df_transition[ , varname]==1, ]
  if (!is.null(keep)) {
    return(df_transition_into_treatment[ , keep])
  } else {
    return(df_transition_into_treatment)  
  } 
}

# Find never treated countries
f_find_never_treated <- function(df, varname="liec7") {
  if (max(unique(df[ , varname]), na.rm=T) == 0) {
    return(df)
  }
}

# Create short panel
f_turn_country_into_panel <- function(df, t=5, idvar="country", timevar="year", drop=NULL) {
  n <- length(unique(df$year))
  if (n >= t) {
    # Create moving windows of length t. First window starts at 1, last window starts at n - t + 1
    idx <- lapply(1:(n-t+1), FUN=`+`, 0:(t-1))
    # Create a list of short panels
    short_panels <- lapply(idx, function(i) data.frame(df[i, setdiff(names(df), "year")], year=0:(t-1)))
    # Add first difference to each short_panel
    # short_panels <- lapply(short_panels, function(df)
    #  mutate(df, goldstein_avg_growth=c(NA, diff(goldstein_avg) / goldstein_avg[-length(goldstein_avg)] * 100)))
    # Name that list
    names(short_panels) <- df$year[1:(n-t+1)]
    # Convert each short panel in the list from long to wide
    widened_short_panels <- lapply(short_panels, reshape, 
                                   idvar=idvar, timevar=timevar, drop=drop, direction="wide")
    # rbind and returns those widened panels
    res <- do.call(rbind, args=widened_short_panels)
    res <- data.frame(start.year = as.numeric(rownames(res)), 
                      after.year = as.numeric(rownames(res)) + t, res)
    return(res)  
  }
}

# Pad data so that all country years are present
f_pad_countryyear <- function(df, idvar="country", timevar="year") {
  years <- seq(min(df[ , timevar]), max(df[ , timevar]))
  return(data.frame(country=rep(unique(df[ , idvar]), length(years)),
                    year=years))
}