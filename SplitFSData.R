library(data.table)

metaData <- fread("data/post2016_metaData.csv")
numFolds <- 10
seedValue <- 1
set.seed(seedValue)
datasetIds <- metaData[, unique(data.id)]
datasetFoldIdx <- sample(rep(1:numFolds, length.out = length(datasetIds))) # integer sampling shuffles by default

for (i in 1:numFolds) {
  trainData <- metaData[data.id %in% datasetIds[datasetFoldIdx != i]]
  testData <- metaData[data.id %in% datasetIds[datasetFoldIdx == i]]
  fwrite(trainData, file = paste0("data/post2016-train-", seedValue + i, ".csv"),
      quote = FALSE)
  fwrite(testData[, -c("Performance_Selection", "Performance_NoSelection", "target")],
      file = paste0("data/post2016-test-", seedValue + i, ".csv"), quote = FALSE)
  fwrite(testData[, .(data.id, classifier, target)], quote = FALSE,
      file = paste0("data/post2016-test-labels-", seedValue + i, ".csv"))
}
