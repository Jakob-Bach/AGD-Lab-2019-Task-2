library(data.table)

inputPath <- "data/"
dateString <- "2019-06-02"
outputPath <- paste0("../Submissions/", dateString, "/Slytherin/")

if (!dir.exists(outputPath)) {
  dir.create(outputPath, showWarnings = FALSE, recursive = TRUE)
}
for (inputTestFile in list.files(inputPath, pattern = "post2016-test-[0-9]+\\.csv", full.names = TRUE)) {
  testData <- fread(inputTestFile)
  solution <- testData[, .(data.id, classifier, target = 0)]
  numberString <- regmatches(inputTestFile, regexpr("[0-9]+.csv$", inputTestFile))
  fwrite(solution, file = paste0(outputPath, "Slytherin-", dateString, "-prediction-", numberString),
      quote = FALSE)
}
