library(data.table)

MAIN_IN_FILE <- "data/kuhn2018_metaData.csv" # should contain all data ids
IN_FILES <- list.files("data/", pattern = "kuhn2018-((train)|(test))", full.names = TRUE)
IN_FILES <- IN_FILES[!grepl("labels", IN_FILES)]
OUT_FILES <- gsub("kuhn2018-", "kuhn2018-OML-", IN_FILES)
ID_COL <- "data_id" # where is the OpenML dataset id stored?

cat("Start time:", as.character(Sys.time()), "\n")
OpenML::setOMLConfig(apikey = "c1994bdb7ecb3c6f3c8f3b35f4b47f1f") # read-only demo key
datasetIds <- fread(MAIN_IN_FILE)[, unique(get(ID_COL))]

cat("Retrieving dataset qualities...\n")
progressBar <- txtProgressBar(min = 0, max = length(datasetIds), style = 3)
datasetQualityTable <- rbindlist(lapply(1:length(datasetIds), function(i) {
  tryCatch({# there might be problems with some base datasets
    datasetQualities <- OpenML::getOMLDataSetQualities(datasetIds[i], verbosity = 0)
    result <- list()
    result[[ID_COL]] <- datasetIds[i]
    result[datasetQualities$name] <- datasetQualities$value
    setTxtProgressBar(progressBar, value = i)
    return(result)
  }, error = function(e) NULL)
}), fill = TRUE)
close(progressBar)

cat("Merging to meta-data...\n")
progressBar <- txtProgressBar(min = 0, max = length(IN_FILES), style = 3)
for (i in 1:length(IN_FILES)) {
  metaData <- fread(IN_FILES[i])
  metaData[, (setdiff(intersect(colnames(metaData), colnames(datasetQualityTable)), ID_COL)) := NULL] # merge only by id
  metaData[, Pos := 1:.N] # to retain original oder after merge
  metaData <- merge(metaData, datasetQualityTable, all.x = TRUE)
  setkey(metaData, Pos)
  metaData[, Pos := NULL]
  fwrite(metaData, file = OUT_FILES[i], quote = FALSE)
  setTxtProgressBar(progressBar, value = i)
}
close(progressBar)

cat("End time:", as.character(Sys.time()), "\n")
