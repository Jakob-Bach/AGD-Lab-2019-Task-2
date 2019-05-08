library(data.table)

# Things that have to be adapted per week and group:
dateString <- "2019-06-30"
predictionBasePath <- paste0("../Submissions/", dateString, "/Slytherin/")

# Get names of files
truthFile <- list.files("data/", pattern = "kuhn2018-.*-labels-.*\\.csv",
    full.names = TRUE)
if (length(truthFile) != 1) {
  stop("The ground truth file seem to have disappeared or multiplied.")
}
numberString <- regmatches(truthFile, regexpr("[0-9]+.csv$", truthFile))
predictionFile <- list.files(predictionBasePath, pattern = paste0(dateString,
    "-prediction-", numberString), full.names = TRUE)
if (length(predictionFile) != length(truthFile)) {
  stop("Number of prediction and ground truth files differ.")
}

# Read in
groundTruth <- fread(truthFile, quote = "")
prediction <- fread(predictionFile, quote = "")

# Sanity checks
if (nrow(prediction) != nrow(groundTruth)) {
  stop("Number of observations wrong.")
}
if (ncol(prediction) != ncol(groundTruth)) {
  stop("Number of columns wrong (might be because of row names).")
}
if (any(colnames(prediction) != colnames(groundTruth))) {
  stop("Column name wrong (quoted or wrong string).")
}
if (!is.numeric(prediction$target)) {
  stop("Wrong prediction type.")
}

# Scoring
print(round(100 * mean(abs((prediction$target - groundTruth$target) / groundTruth$target)), digits = 3))
