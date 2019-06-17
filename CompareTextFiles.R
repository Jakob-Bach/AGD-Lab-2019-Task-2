sourceFilesBasePath <- "../Submissions/2019-05-12/Gryffindor/"
targetFilesBasePath <- "../Submissions/2019-05-12/Gryffindor_own/"
sourcesFilesPattern <- "\\.csv"
targetFilesPattern <- "\\.csv"

sourceFiles <- list.files(sourceFilesBasePath, pattern = sourcesFilesPattern)
targetFiles <- list.files(targetFilesBasePath, pattern = targetFilesPattern)

if (length(sourceFiles) != length(targetFiles)) {
  stop("Different number of source an traget files.")
}
if (any(sourceFiles != targetFiles)) {
  stop("Different source and target file names.")
}
for (fileName in sourceFiles) {
  if (any(readLines(paste0(sourceFilesBasePath, fileName)) !=
          readLines(paste0(targetFilesBasePath, fileName)))) { # CRLF does not matter here
    cat("Difference in file \"", fileName, "\"\n", sep = "")
  } else {
    print("+++")
  }
}
