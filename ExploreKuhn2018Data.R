library(data.table)

#### Retrieve data ####

# Data available at https://figshare.com/articles/OpenML_R_Bot_Benchmark_Data_final_subset_/5882230

## Option 1: Get CSV data (one for each base classifer)

classifiers <- c("glmnet", "kknn", "ranger", "rpart", "svm", "xgboost")
inputFileNames <- paste0("OpenMLRandomBotResultsFinal_mlr.classif.", classifers, ".csv")
dataUrls <- paste0("https://ndownloader.figshare.com/files/",
    c("10462300", "10462309", "10811312", "10462312", "10462306", "10462315"))
allMetaData <- lapply(dataUrls, function(dataUrl) {
  fread(dataUrl)
})

## Option 2: Get .RData (several tables, hyperparameter settings in long format)

urlConnection <- url("https://ndownloader.figshare.com/files/10811309")
load(urlConnection)
close(urlConnection)

## Focus on base classifer with most hyperparameters (xgboost)

metaData <- fread("https://ndownloader.figshare.com/files/10462315")

#### Try meta-models ####

metaData[, c("accuracy", "brier", "auc", "scimark") := NULL]
setnames(metaData, old = "runtime", new = "target")

# Train-test split (considering base datasets)

set.seed(25)
datasetIds <- metaData[, unique(data_id)]
datasetTrainIds <- sample(datasetIds, size = round(0.8 * length(datasetIds)), replace = FALSE)
trainData <- metaData[data_id %in% datasetTrainIds, -"data_id"]
testData <- metaData[!(data_id %in% datasetTrainIds), -"data_id"]

# Train-test split (ignoring base datasets)

set.seed(25)
trainIdx <- metaData[, sample(1:.N, size = round(0.8 * .N), replace = FALSE)]
trainData <- metaData[trainIdx, -"data_id"]
testData <- metaData[-trainIdx, -"data_id"]

# Now the models in "ExplorePost2016Data.R" can be used
