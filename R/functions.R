# Install and load packages
f_install_and_load <- function(packs) {
  new.packs <- packs[!(packs %in% installed.packages()[ ,"Package"])]
  lapply(new.packs, install.packages, repos="http://cran.rstudio.com/")
  lapply(packs, library, character.only=TRUE)
}

# Center and scale a variable
f_center_and_scale <- function(vector, num.sd = 2) {
  # num.sd is how many sd to divide by
  (vector - mean(vector, na.rm=T)) / (num.sd * sd(vector, na.rm=T))
}

# Create an environment that contains the stata var labels
f_extract_stata_label <- function(df) {
  lab_env <- new.env()
  for (i in seq_along(names(df))) {
    lab_env[[names(df)[i]]] <- attr(df, "var.labels")[i]  
  }
  return(lab_env)
}