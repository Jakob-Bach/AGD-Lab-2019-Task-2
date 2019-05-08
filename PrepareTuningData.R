library(data.table)

metaData <- fread("https://ndownloader.figshare.com/files/10462315")

metaData[, c("accuracy", "brier", "runtime", "scimark") := NULL]
setnames(metaData, old = "auc", new = "target")

saveRDS(metaData, "data/kuhn2018_metaData.rds")
fwrite(metaData, file = "data/kuhn2018_metaData.csv", quote = FALSE)
