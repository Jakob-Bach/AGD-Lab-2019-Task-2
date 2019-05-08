library(data.table)

metaData <- fread("data/kuhn2018_metaData.csv")

seedValue <- 25
set.seed(seedValue)
datasetIds <- metaData[, unique(data_id)]
datasetTrainIds <- sample(datasetIds, size = round(0.8 * length(datasetIds)), replace = FALSE)
trainData <- metaData[data_id %in% datasetTrainIds]
testData <- metaData[!(data_id %in% datasetTrainIds)]

fwrite(trainData, quote = FALSE,
    file = paste0("data/kuhn2018-train-", seedValue, ".csv"))
fwrite(testData[, -"target"], quote = FALSE,
    file = paste0("data/kuhn2018-test-", seedValue, ".csv"))
fwrite(testData[, .(target)], quote = FALSE,
    file = paste0("data/kuhn2018-test-labels-", seedValue, ".csv"))
