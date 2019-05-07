library(data.table)

OpenML::setOMLConfig(apikey = "c1994bdb7ecb3c6f3c8f3b35f4b47f1f") # read-only, you can get own key
study <- OpenML::getOMLStudy(15)

#### Performance info ("runs") for meta-target ####

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

##### Meta-features ("dataset qualities") ####

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

#### Merge data ####

metaData <- runTable[, .(data.id, dataset, classifier, area_under_roc_curve)]
setnames(metaData, "area_under_roc_curve", "target")
metaData[, FeaturesSelected := paste0("Selected_", grepl("Selected", classifier))]
metaData[, classifier := gsub("\\([0-9]+\\)", "", classifier)] # simplify naming
metaData[, classifier := gsub("weka.", "", classifier)]
metaData[, classifier := gsub("AttributeSelectedClassifier_CfsSubsetEval_BestFirst_", "", classifier)]
metaData <- dcast(metaData, dataset + data.id + classifier ~ FeaturesSelected, value.var = "target")
metaData[, target := Selected_TRUE - Selected_FALSE]
setnames(metaData, old = c("Selected_FALSE", "Selected_TRUE"),
    new = c("Performance_NoSelection", "Performance_Selection"))
metaData <- merge(metaData, datasetQualityTable, by = "data.id")
saveRDS(metaData, file = "data/post2016_metaData.rds")
fwrite(metaData, file = "data/post2016_metaData.csv", quote = FALSE)
