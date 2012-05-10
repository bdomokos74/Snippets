setwd("/Users/domokosbalint/projects/Snippets/projects/logreg_vs_bayes")
library(reshape)

ReadData <- function(fname, hdr=F) {
  skip <- ifelse(hdr, 1, 0 )
  result <- read.table(fname, sep=",", strip.white=T, na.strings="?", skip=skip, stringsAsFactors=F)
  cn <- c( "age", "workclass", "fnlwgt", "education", "education-num", "marital-status", "occupation", 
            "relationship", "race", "sex", "capital-gain", "capital-loss", "hours-per-week", "native-country", "income")
  colnames(result) <- cn
  result <- subset(result, complete.cases(result))
  result[result$income=="<=50K","outcome"] <- 0
  result[result$income==">50K", "outcome"] <- 1
  return(result[,-15])
}

adult.train <- ReadData("data/adult.data")
adult.train <- adult.train[,-c(1,3,5,11,12,13)]
adult.test <- ReadData("data/adult.test", hdr=T)
adult.test <- adult.test[,-c(1,3,5,11,12,13)]

build.bayes <- function(X, y) {
  X$id <- 1:nrow(X)
  df <- cbind(X, data.frame(outcome=y))
  molten <- melt(df, id.vars=c("id", "outcome"))
  result = new("bayes.model")

  tmp <- aggregate(outcome~variable+value, molten, sum)
  tmp$pc0 <- tmp$outcome/sum(y==0)
  tmp$pc1 <- tmp$outcome/sum(y==1)
  result@table <- tmp

  result@n0 <- sum(y==0)
  result@n1 <- sum(y==1)
  return(result)
}
predict.bayes <- function(model, X.pred) {
  cn <- colnames(X.pred)
  result <- rep(0, nrow(X.pred))
  for(i in 1:nrow(X.pred)) {
    l <- log(model@n0/model@n1)
    for(j in 1:ncol(X.pred)) {
      sel <- model@table$variable==cn[j]&model@table$value==X.pred[i,j]
      l <- l + log(model@table[sel, "pc1"]/model@table[sel, "pc0"])
    }
    result[i] <- ifelse(l>0, 1, 0)
  }
  return(result)
}
setClass("bayes.model", representation(table="data.frame", n0="integer", n1="integer") )
setMethod("predict", "bayes.model", function(object, X.pred) predict.bayes(object, X.pred))

bm <- build.bayes(adult.train[,-9], adult.train[,9])
pred <- predict(bm, adult.test[,-9])


df <- adult.train
df$id <- 1:nrow(df)
molten <- melt(df, id.vars=c("id", "one", "outcome"))
#table <- aggregate(one~variable+value+outcome, molten, sum)

