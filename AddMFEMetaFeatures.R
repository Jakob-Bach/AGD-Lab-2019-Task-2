library(data.table)

IN_FILE <- "data/post2016_metaData.csv"
OUT_FILE <- "data/post2016_metaData_enhanced.csv"
ID_COL <- "data.id" # where is the OpenML dataset id stored?

OpenML::setOMLConfig(apikey = "c1994bdb7ecb3c6f3c8f3b35f4b47f1f") # read-only demo key
metaData <- fread(IN_FILE)

dataIds <- metaData[, unique(get(ID_COL))]
progressBar <- txtProgressBar(min = 0, max = length(dataIds), style = 3)
library(foreach)
showProgress <- function(n) setTxtProgressBar(progressBar, n)
computingCluster <- parallel::makeCluster(parallel::detectCores())
doSNOW::registerDoSNOW(computingCluster)
mfeTable <- rbindlist(foreach(i = 1:length(dataIds), .packages = "OpenML",
    .options.snow = list(progress = showProgress)) %dopar% {
  setTxtProgressBar(progressBar, value = i)
  dataList <- OpenML::getOMLDataSet(data.id = dataIds[i])
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
    groups = c("general", "infotheo", "landmarking", "model.based", "statistical")
  )
  result <- list()
  result[[ID_COL]] <- dataIds[i]
  result[names(metaFeatureVec)] <- metaFeatureVec
  return(result)
})
parallel::stopCluster(computingCluster)
close(progressBar)

metaData <- merge(metaData, mfeTable, by = ID_COL, all.x = TRUE)
fwrite(metaData, file = OUT_FILE, quote = FALSE)
