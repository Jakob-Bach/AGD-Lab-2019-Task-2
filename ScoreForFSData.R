library(data.table)

# Things that have to be adapted per week and group:
dateString <- "2019-06-02"
predictionBasePath <- paste0("../Submissions/", dateString, "/Slytherin/")

# Get names of split files
truthFiles <- list.files("data/", pattern = "post2016-.*-labels-.*\\.csv", full.names = TRUE)
if (length(truthFiles) == 0) {
  stop("The ground truth files seem to have disappeared.")
}
if (length(list.files(predictionBasePath, pattern = "\\.csv")) != length(truthFiles)) {
  stop("Number of prediction and ground truth files differ.")
}

score <- 0 # will be averaged over splits
for (truthFileName in truthFiles) {
  numberString <- regmatches(truthFileName, regexpr("[0-9]+.csv$", truthFileName))
  predictionFileName <- list.files(predictionBasePath, full.names = TRUE,
      pattern = paste0(dateString, "-prediction-", numberString))
  if (length(predictionFileName) != 1) {
    stop(paste0("Zero or multiple matching prediction files found for \"", numberString, "\"."))
  }
  groundTruth <- fread(truthFileName)
  prediction <- fread(predictionFileName, quote = "")
  if (nrow(prediction) != nrow(groundTruth)) {
    stop("Number of observations wrong.")
  }
  if (ncol(prediction) != ncol(groundTruth)) {
    stop("Number of columns wrong (might be because of row names).")
  }
  if (any(colnames(prediction) != colnames(groundTruth))) {
    stop("Column name wrong (quoted or wrong string).")
  }
  if (any(grepl("\"", prediction$classifier))) {
    stop("Colum values quoted.")
  }
  if (!is.numeric(prediction$target)) {
    stop("Wrong prediction type.")
  }
  mergedData <- merge(groundTruth, prediction, by = c("classifier", "data.id"))
  if (nrow(mergedData) != nrow(groundTruth)) {
    stop("Identifier columns have some different values in prediction file.")
  }
  score <- score + mergedData[, sqrt(mean((target.x - target.y)^2))]
}
print(round(score / length(truthFiles), digits = 3))
