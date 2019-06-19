library(data.table)

inputPath <- "data/"
dateString <- "2019-06-30"
outputPath <- paste0("../Submissions/", dateString, "/Slytherin/")

if (!dir.exists(outputPath)) {
  dir.create(outputPath, showWarnings = FALSE, recursive = TRUE)
}
for (inputTestFile in list.files(inputPath, pattern = "post2016-test-[0-9]+\\.csv", full.names = TRUE)) {
  # Read in
  trainData <- fread(gsub("test", "train", inputTestFile))
  testData <- fread(inputTestFile)

  # Pre-process
  trainData <- trainData[, c("dataset", "Performance_NoSelection", "Performance_Selection") := NULL]
  testData[, dataset := NULL]
  preprocModel <- caret::preProcess(trainData[, -"target"], method = "medianImpute")
  trainData <- predict(preprocModel, trainData)
  testData <- predict(preprocModel, testData)

  # Train model
  xgbTrainPredictors <- Matrix::sparse.model.matrix(~ .,data = trainData[, -c("data.id", "target")])[, -1]
  xgbTrainData <- xgboost::xgb.DMatrix(data = xgbTrainPredictors, label = trainData$target)
  xgbTestPredictors <- Matrix::sparse.model.matrix(~ ., data = testData[, -"data.id"])[, -1]
  xgbModel <- xgboost::xgb.train(data = xgbTrainData, nrounds = 50,
      params = list(objective = "reg:linear", nthread = 4))

  # Predict
  testPrediction <- predict(xgbModel, newdata = xgbTestPredictors)
  solution <- cbind(testData[, .(data.id, classifier)], target = testPrediction)
  numberString <- regmatches(inputTestFile, regexpr("[0-9]+.csv$", inputTestFile))
  fwrite(solution, file = paste0(outputPath, "Slytherin-", dateString, "-prediction-", numberString),
      quote = FALSE)
}
