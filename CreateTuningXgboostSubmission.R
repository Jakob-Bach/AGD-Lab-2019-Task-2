library(data.table)

inputPath <- "data/"
dateString <- "2019-07-07"
outputPath <- paste0("../Submissions/", dateString, "/Slytherin/")

engineerFeatures <- function(dataset) {
  dataset <- copy(dataset)
  dataset[, c("data_id", "NumberOfClasses") := NULL]
  dataset[, complexity := 1.0 * NumberOfInstances * NumberOfFeatures * nrounds / scimark]
  dataset[, tree_complexity := complexity * colsample_bylevel * colsample_bytree * subsample]
  return(dataset)
}

if (!dir.exists(outputPath)) {
  dir.create(outputPath, showWarnings = FALSE, recursive = TRUE)
}
for (inputTestFile in list.files(inputPath, pattern = "kuhn2018-test-[0-9]+\\.csv", full.names = TRUE)) {
  # Read in
  trainData <- fread(gsub("test", "train", inputTestFile))
  testData <- fread(inputTestFile)

  # Pre-process
  trainData <- engineerFeatures(trainData)
  testData <- engineerFeatures(testData)
  preprocModel <- caret::preProcess(trainData[, -"target"], method = "medianImpute")
  trainData <- predict(preprocModel, trainData)
  testData <- predict(preprocModel, testData)

  # Train model
  xgbTrainPredictors <- Matrix::sparse.model.matrix(~ .,data = trainData[, -"target"])[, -1]
  xgbTrainData <- xgboost::xgb.DMatrix(data = xgbTrainPredictors, label = trainData$target)
  xgbTestPredictors <- Matrix::sparse.model.matrix(~ ., data = testData)[, -1]
  xgbModel <- xgboost::xgb.train(data = xgbTrainData, nrounds = 50,
      params = list(objective = "reg:linear", nthread = 4))

  # Predict
  solution <- data.table(target = predict(xgbModel, newdata = xgbTestPredictors))
  numberString <- regmatches(inputTestFile, regexpr("[0-9]+.csv$", inputTestFile))
  fwrite(solution, file = paste0(outputPath, "Slytherin-", dateString, "-prediction-", numberString),
      quote = FALSE)
}
