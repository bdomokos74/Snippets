GetPerfMetrics <- function(pred, actual, print=F) {
  if(length(pred)!=length(actual))
    stop("Can't compare vectors of different length")
  if(is.factor(pred))
  	pred <- as.numeric(levels(pred))[as.integer(pred)]
  if(is.factor(actual))
  	actual <- as.numeric(levels(actual))[as.integer(actual)]

  P <- sum(pred==1)
  N <- sum(pred==0)
  TP <- sum(pred==actual & pred==1)
  TN <- sum(pred==actual & pred==0)
  FN <- sum(pred!=actual & pred==0)
  FP <- sum(pred!=actual & pred==1)
  SENS <- TP / (TP + FN)
  SPC <-  TN / (FP + TN)
  ACC <-  (TP + TN) / (P + N)
  PREC <- TP / (TP + FP)
  NPV <- TN / (TN + FN)
  F1 <- 2*TP / (2*TP + FP + FN)
  if(print) {
    cat("SENS:", SENS, "\nSPC:", SPC, "\nACC:", ACC, "\nPREC:", PREC, "\nNPV:", NPV, "\nF1:", F1, "\n", sep="")
  }
  return(c(SENS, SPC, ACC, PREC , NPV, F1))
}

Factorize <- function(df) {
  result <- df
  for(cn in colnames(result)) {
    result[,cn] <- factor(result[,cn])
  }
  return (result)
}

