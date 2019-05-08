library(data.table)

inputPath <- "data/"
dateString <- "2019-06-30"
outputPath <- paste0("../Submissions/", dateString, "/Slytherin/")

if (!dir.exists(outputPath)) {
  dir.create(outputPath, showWarnings = FALSE, recursive = TRUE)
}
inputTrainFile <- list.files(inputPath, pattern = "kuhn2018-train-[0-9]+\\.csv", full.names = TRUE)
inputTestFile <- list.files(inputPath, pattern = "kuhn2018-test-[0-9]+\\.csv", full.names = TRUE)
if (length(inputTrainFile) != 1 || length(inputTestFile) != 1) {
  stop("Unexpected number of training or test files.")
}
trainData <- fread(inputTrainFile)
testData <- fread(inputTestFile)
solution <- data.table(target = rep(median(trainData$target), length.out = nrow(testData)))
numberString <- regmatches(inputTestFile, regexpr("[0-9]+.csv$", inputTestFile))
fwrite(solution, file = paste0(outputPath, "Slytherin-", dateString, "-prediction-", numberString),
    quote = FALSE)
