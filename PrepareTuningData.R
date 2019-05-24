library(data.table)

metaData <- fread("https://ndownloader.figshare.com/files/10462315")

metaData[, c("accuracy", "brier", "auc") := NULL]
setnames(metaData, old = "runtime", new = "target")
metaData <- metaData[target > 1]

saveRDS(metaData, "data/kuhn2018_metaData.rds")
fwrite(metaData, file = "data/kuhn2018_metaData.csv", quote = FALSE)
