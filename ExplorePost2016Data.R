library(data.table)
library(ggplot2)

OpenML::setOMLConfig(apikey = "c1994bdb7ecb3c6f3c8f3b35f4b47f1f") # read-only, you can get own key

#### Retrieve data ####

study <- OpenML::getOMLStudy(15)

# Performance info ("runs"), can be used as meta-target

runIds <- study$runs$run.id
progressBar <- txtProgressBar(min = 0, max = length(runIds), style = 3)
runs <- lapply(1:length(runIds), function(i) {
  setTxtProgressBar(progressBar, value = i)
  return(OpenML::getOMLRun(study$runs$run.id[i], verbosity = 0))
})
close(progressBar)
names(runs) <- runIds
saveRDS(runs, "data/post2016_runs.rds")

runTable <- rbindlist(lapply(runs, function(run) {
  result <- list(
    data.id = run$input.data$datasets$data.id,
    dataset = run$input.data$datasets$name,
    classifier = run$flow.name
  )
  performanceInfo <- run$output.data$evaluations
  performanceInfo <- performanceInfo[is.na(performanceInfo$fold), c("name", "value")] # only overall performance, not fold performance
  result[performanceInfo$name] <- performanceInfo$value
  return(result)
}), fill = TRUE)

# Meta-features ("dataset qualities")

datasetIds <- study$data$data.id # could also use runTable[, unique(data.id)]
progressBar <- txtProgressBar(min = 0, max = length(datasetIds), style = 3)
datasetQualities <- lapply(1:length(datasetIds), function(i) {
  setTxtProgressBar(progressBar, value = i)
  return(OpenML::getOMLDataSetQualities(study$data$data.id[i], verbosity = 0))
})
close(progressBar)
names(datasetQualities) <- datasetIds
saveRDS(datasetQualities, "data/post2016_datasetQualities.rds")

datasetQualityTable <- rbindlist(lapply(1:length(datasetQualities), function(i) {
  result <- list(data.id = as.numeric(names(datasetQualities)[i]))
  result[datasetQualities[[i]]$name] <- datasetQualities[[i]]$value
  return(result)
}), fill = TRUE)

#### Explore data ####

# Completeness of runs
runTable[, .(RunsPerDataset = .N), by = data.id][, .N , by = RunsPerDataset]

# Completeness of dataset qualities

missingValueTable <- data.table(DatasetQuality = names(datasetQualityTable),
    NumMissing = sapply(datasetQualityTable, function(x) sum(is.na(x))))
missingValueTable[NumMissing == 0, DatasetQuality]
missingValueTable[NumMissing > 0.5 * nrow(datasetQualityTable)]

# Try additional meta-feature generation with [mfe]

baseDataset <- OpenML::getOMLDataSet(datasetQualityTable$data.id[1])
mfeMetaFeatures <- mfe::metafeatures(formula = as.formula(
    paste0(baseDataset$desc$default.target.attribute, " ~ .")), data = baseDataset$data)

#### Try meta-models ####

# Approach 1: Predict base performance (feature selection only treated as additional classifiers)

# Exclude some meta-features, focus on one meta-target
nonLandmarkerFeatures <- setdiff(names(datasetQualityTable),
    grep("ErrRate|Kappa|AUC", names(datasetQualityTable), value = TRUE))
metaData <- merge(runTable[, .(data.id, dataset, classifier, predictive_accuracy)],
                  datasetQualityTable[, mget(nonLandmarkerFeatures)])
setnames(metaData, "predictive_accuracy", "target")
metaData[, classifier := as.factor(classifier)]

# Approach 2: Predict difference FS/no FS

metaData <- runTable[, .(data.id, dataset, classifier, area_under_roc_curve)]
setnames(metaData, "area_under_roc_curve", "target")
metaData[, FeaturesSelected := paste0("Selected_", grepl("Selected", classifier))]
metaData[, classifier := gsub("\\([0-9]+\\)", "", classifier)] # simplify naming
metaData[, classifier := gsub("weka.", "", classifier)]
metaData[, classifier := gsub("AttributeSelectedClassifier_CfsSubsetEval_BestFirst_", "", classifier)]
metaData[, classifier := as.factor(classifier)]
metaData <- dcast(metaData, dataset + data.id + classifier ~ FeaturesSelected, value.var = "target")
metaData[, target := Selected_TRUE - Selected_FALSE]
metaData[, c("Selected_TRUE", "Selected_FALSE") := NULL]

nonLandmarkerFeatures <- setdiff(names(datasetQualityTable),
    grep("ErrRate|Kappa|AUC", names(datasetQualityTable), value = TRUE))
metaData <- merge(metaData, datasetQualityTable[, mget(nonLandmarkerFeatures)], by = "data.id")

# Train-test split (considering base datasets)

set.seed(25)
trainDatasetIds <- metaData[, sample(unique(data.id), size = round(0.8 * uniqueN(data.id)), replace = FALSE)]
trainData <- metaData[data.id %in% trainDatasetIds, -c("data.id", "dataset")]
testData <- metaData[!(data.id %in% trainDatasetIds), -c("data.id", "dataset")]

# Baseline: Guess average train performace

mean(abs(testData$target - trainData[, mean(target)]))

# Decision tree [rpart]

rpartModel <- rpart::rpart(formula = target ~ ., data = trainData)
testPrediction <- predict(rpartModel, newdata = testData)
mean(abs(testData$target - testPrediction))

rpartModel$variable.importance
rpart.plot::rpart.plot(rpartModel)

# Boosted trees [xgboost]

preprocModel <- caret::preProcess(trainData, method = "medianImpute") # matrix conversion else deletes NA row
xgbTrainPredictors <- Matrix::sparse.model.matrix(~ .,data =
    predict(preprocModel, trainData)[, -"target"])[, -1]
xgbTrainData <- xgboost::xgb.DMatrix(data = xgbTrainPredictors,
    label = trainData$target)
xgbTestPredictors <- Matrix::sparse.model.matrix(~ ., data =
    predict(preprocModel, testData)[, -"target"])[, -1]
xgbTestData <- xgboost::xgb.DMatrix(data = xgbTestPredictors,
    label = testData$target)
xgbModel <- xgboost::xgb.train(data = xgbTrainData, nrounds = 50, verbose = 2,
    watchlist = list(train = xgbTrainData, test = xgbTestData),
    params = list(objective = "reg:linear", nthread = 4))
testPrediction <- predict(xgbModel, newdata = xgbTestPredictors)
mean(abs(testData$target - testPrediction))

ggplot(data = melt(data = xgbModel$evaluation_log, id.vars = "iter")) +
  geom_line(aes(x = iter, y = value, color = variable)) + ylab("RSME")
xgbImportanceMatrix <- xgboost::xgb.importance(model = xgbModel)
xgboost::xgb.ggplot.importance(importance_matrix = xgbImportanceMatrix, top_n = 10)
xgboost::xgb.plot.shap(data = xgbTrainPredictors, model = xgbModel, top_n = 2)
xgboost::xgb.plot.tree(model = xgbModel, trees = 0)
xgboost::xgb.plot.multi.trees(model = xgbModel) # all trees merged in one
xgboost::xgb.ggplot.deepness(model = xgbModel) # model complexity
