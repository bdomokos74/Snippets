setwd("/Users/domokosbalint/projects/Snippets/projects/logreg_vs_bayes")
library(reshape)
library(e1071)
source("../../common/util.r")

##################################################################
# Functions
##################################################################

ReadData <- function(fname, hdr=F) {
  skip <- ifelse(hdr, 1, 0 )
  result <- read.table(fname, sep=",", strip.white=T, na.strings="?", skip=skip, stringsAsFactors=F)
  cn <- c( "age", "workclass", "fnlwgt", "education", "education-num", "marital-status", "occupation", 
            "relationship", "race", "sex", "capital-gain", "capital-loss", "hours-per-week", "native-country", "income")
  colnames(result) <- cn
  result <- subset(result, complete.cases(result))
  result[result$income=="<=50K"|result$income=="<=50K.","outcome"] <- 0
  result[result$income==">50K"|result$income==">50K.", "outcome"] <- 1
  return(result[,-15])
}

build.bayes <- function(X, y) {
  X$id <- 1:nrow(X)
  df <- cbind(X, data.frame(outcome=y))
  molten <- melt(df, id.vars=c("id", "outcome"))
  result = new("bayes.model")
  n1 <- sum(y==1)
  n0 <- sum(y==0)
  GetProbs <- function(df) {
    n <- nrow(df)
    laplace = 1
    if(n==0) {
      can("n=0, ", df[1,"variable"], " ", df[1,"value"], "\n", sep="")
    }
    if(df[1,"outcome"]==1) {
      return( (n+laplace)/(n1+2*laplace) )
    } else {
      return((n+laplace)/(n0+2*laplace) )
    }
  }
  tmp <- ddply(molten, .(outcome, variable, value), GetProbs)
  cn <- colnames(tmp)
  cn[4] <- "p"
  colnames(tmp) <- cn
  print(tmp[1,])

  result@table <- tmp

  result@n0 <- n0
  result@n1 <- n1
  return(result)
}
predict.bayes <- function(model, X.pred, laplace=0) {
  cn <- colnames(X.pred)
  result <- rep(0, nrow(X.pred))
  for(i in 1:nrow(X.pred)) {
    l <- log(model@n1/model@n0)
    for(j in 1:ncol(X.pred)) {
      sel <- model@table$variable==cn[j]&model@table$value==X.pred[i,j]
      tmp <- model@table[which(sel),]
      
      c1 <- ifelse(sum(tmp$outcome==1)==0, 0, tmp[tmp$outcome==1, "count"])  
      c0 <- ifelse(sum(tmp$outcome==0)==0, 0, tmp[tmp$outcome==0, "count"])  
      
      p1 <- (c1+laplace)/(model@n1+laplace*2)
      p0 <- (c0+laplace)/(model@n0+laplace*2)
      l <- l + log(p1/p0)
      
      # cat("l=", l, " i=", i, " col=", cn[j]," p0=", p0, " p1=", p1," c0=", c0, " c1=", c1, "\n", sep="") 
    }
    
    result[i] <- ifelse(l>0, 1, 0)
  }
  return(result)
}
setClass("bayes.model", representation(table="data.frame", n0="integer", n1="integer") )
setMethod("predict", "bayes.model", function(object, X.pred) predict.bayes(object, X.pred))


##################################################################
# Prepare data
##################################################################

adult.train <- ReadData("data/adult.data")
adult.train <- adult.train[,-c(1,3,5,11,12,13)]
adult.test <- ReadData("data/adult.test", hdr=T)
adult.test <- adult.test[,-c(1,3,5,11,12,13)]
adult.train.f <- Factorize(adult.train)
adult.test.f <- Factorize(adult.test)

##################################################################
# Try own naive bayes predictor
##################################################################

bm <- build.bayes(adult.train[,-9], adult.train[,9])
pred <- predict(bm, adult.test[,-9], laplace=1)
GetPerfMetrics(pred, adult.test[,9])

##################################################################
# Try naiveBayes in e1071
##################################################################


nbm <- naiveBayes(outcome~., adult.train.f, laplace=1)
pred2 <- predict(nbm, adult.test.f[,-9])
GetAcc(pred2, adult.test.f[,9])

##################################################################
#
##################################################################

df <- adult.train
df$id <- 1:nrow(df)
molten <- melt(df[,-10], id.vars=c("outcome"))
tmp <- ddply(molten, .(outcome, variable, value), nrow)
#table <- aggregate(one~variable+value+outcome, molten, sum)


tmp <- ddply(molten, .(variable, value), function(df) {
  n <- nrow(df)
  ones <- subset(df, outcome=="1")
  return(c( (ones+laplace)/(n1+2*laplace), (n-ones+laplace)/(n0+2*laplace)) )
})


sel <- which(levels(variable)[variable]=="workclass"&levels(value)[value]=="Private")
tmp <- molten[sel,]

