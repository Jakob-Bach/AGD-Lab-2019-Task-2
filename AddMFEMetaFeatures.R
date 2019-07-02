library(data.table)

MAIN_IN_FILE <- "data/kuhn2018_metaData.csv" # should contain all data ids
IN_FILES <- list.files("data/", pattern = "kuhn2018-((train)|(test))", full.names = TRUE)
IN_FILES <- IN_FILES[!grepl("labels", IN_FILES)]
OUT_FILES <- gsub("kuhn2018-", "kuhn2018-mfe-", IN_FILES)
ID_COL <- "data_id" # where is the OpenML dataset id stored?

cat("Start time:", as.character(Sys.time()), "\n")
OpenML::setOMLConfig(apikey = "c1994bdb7ecb3c6f3c8f3b35f4b47f1f") # read-only demo key
datasetIds <- fread(MAIN_IN_FILE)[, unique(get(ID_COL))]

cat("Extracting meta-features with mfe...\n")
progressBar <- txtProgressBar(min = 0, max = length(datasetIds), style = 3)
library(foreach)
showProgress <- function(n) setTxtProgressBar(progressBar, n)
computingCluster <- parallel::makeCluster(parallel::detectCores())
doSNOW::registerDoSNOW(computingCluster)
mfeTable <- rbindlist(foreach(i = 1:length(datasetIds), .packages = "OpenML",
    .options.snow = list(progress = showProgress)) %dopar% {
  setTxtProgressBar(progressBar, value = i)
  dataList <- OpenML::getOMLDataSet(data.id = datasetIds[i])
  dataset <- dataList$data
  targetColumn <- dataList$target.features
  dataset <- data.frame(lapply(dataset, function(col) {
    if (any(is.na(col))) { # mfe cannot handle NAs
      if (is.factor(col)) { # make NA a separate factor level
        col <- as.character(col)
        col[is.na(col)] <- "NA"
        col <- factor(col)
      } else if (is.numeric(col)) {# median impute
        col[is.na(col)] <- median(col, na.rm = TRUE)
      } else {
        stop("Unknown column type.")
      }
    }
    return(col)
  }))
  metaFeatureVec <- mfe::metafeatures(
    x = dataset[, which(colnames(dataset) != targetColumn)],
    y = dataset[, which(colnames(dataset) == targetColumn)],
    groups = c("general", "infotheo", "statistical")
  )
  result <- list()
  result[[ID_COL]] <- datasetIds[i]
  result[names(metaFeatureVec)] <- metaFeatureVec
  return(result)
})
parallel::stopCluster(computingCluster)
close(progressBar)

cat("Merging to meta-data...\n")
progressBar <- txtProgressBar(min = 0, max = length(IN_FILES), style = 3)
for (i in 1:length(IN_FILES)) {
  metaData <- fread(IN_FILES[i])
  metaData[, Pos := 1:.N] # to retain original oder after merge
  metaData <- merge(metaData, mfeTable, all.x = TRUE)
  setkey(metaData, Pos)
  metaData[, Pos := NULL]
  fwrite(metaData, file = OUT_FILES[i], quote = FALSE)
  setTxtProgressBar(progressBar, value = i)
}
close(progressBar)
cat("End time:", as.character(Sys.time()), "\n")
