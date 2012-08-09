InitErrRate <- function(n) {
  return(data.frame(iter=numeric(n), n=numeric(n), type=character(n), ErrRate=numeric(n), stringsAsFactors=F))
}
ErrRate <- function(pred, real) {
  if(is.factor(pred)) {
    pred <- levels(pred)[pred]
  }
  if(is.factor(real)) {
    real <- levels(real)[real]
  }
  return(mean(pred!=real))
}
LCDebug <- function(pred, real) {
  a<-pred
  b<-real
  if(is.factor(pred)) {
    a <- levels(pred)[pred]
  }
  if(is.factor(real)) {
    b <- levels(real)[real]
  }
  pm <- GetPerfMetrics(a, b)
	cat("\t", a," 1/all=", sum(a==1)/length(a), " P=", sum(a==1), " N=", sum(a==0),"\n", sep="")
	cat("\t", b," 1/all=", sum(b==1)/length(b), " P=", sum(b==1), " N=", sum(b==0), " TP=", sum(a==1&a==b), " TN=", sum(a==0&a==b),"\n", sep="")
	cat("\tSENS=", pm[1]," SPC=",pm[2], " ACC=",pm[3], " PREC=",pm[4], " NPV=", pm[5], "\n", sep="")
}

LC2 <- function(df, df.outcome, fns, fold=10, do.training.err=T, training.points=50, debug=F, progress=F, start.n=1, model, dataset) {  
  fit.fn <- fns[["fit.fn"]]
  pred.fn <- fns[["pred.fn"]]
  init.fn <- fns[["init.fn"]]
  debug.fn <- fns[["debug.fn"]]
  metrics.fn <- fns[["metrics.fn"]]

  n = nrow(df)
  fold.size <- floor(n/fold)
  max.train.size <- n-fold.size-1
  index.tbl <-  sample(rep(1:fold, length.out=n))
  cat("n=", n, " fold=", fold, " fold.size=", fold.size, " max.train.size=", max.train.size, " start.n=", start.n, " n.points=", 
    length(seq(start.n, max.train.size, by=floor(max.train.size/training.points))), "\n", sep="")
    
  ntp <- length(seq(start.n, max.train.size, by=floor(max.train.size/training.points)))
  df.size <- ntp*fold
  if(do.training.err) {
    df.size <- df.size*2
  }
  result <- init.fn(df.size)
  curr.index <- 1
  curr.progress <- 1
  if(progress) {
    progress.size <- training.points*fold
    pb <- txtProgressBar(min = 0, max = progress.size, style = 3)
  }
  
  for(iter in 1:fold) {
    inTrain <- which(index.tbl!=iter)
    test.x <- data.matrix(df[-inTrain,])
    test.y <- df.outcome[-inTrain,]
    for(train.size in seq(start.n, max.train.size, by=floor((max.train.size-start.n)/training.points))) {
      sel.train <- sample(inTrain, train.size)
      train.x <- data.matrix(df[sel.train,])
      train.y <- df.outcome[sel.train,]
      fit <- fit.fn(train.x, train.y)
      
      if(do.training.err) { 
        prediction <- pred.fn(fit, train.x)
        if(debug&&!is.null(debug.fn)) {
          cat(curr.index, " - train\n")
          debug.fn(prediction, train.y)
        }
        result[curr.index, "iter"] <- iter
        result[curr.index, "n"] <- train.size
        result[curr.index, "type"] <- "Train"
        met <- metrics.fn(prediction, train.y)
        if(length(met)==1) {
           result[curr.index, 4] <- met
        } else {
          for( met.index in 1:length(met)) {
            result[curr.index, 4+(met.index-1)] <- met[met.index]
          }
        }
        curr.index <- curr.index+1
      }
      
      prediction <- pred.fn(fit, test.x)
      if(debug&&!is.null(debug.fn)) {
        cat(curr.index, " - test\n")
        debug.fn(prediction, test.y)
      }
      result[curr.index, "iter"] <- iter
      result[curr.index, "n"] <- train.size
      result[curr.index, "type"] <- "Test"
      met <- metrics.fn(prediction, test.y)
      if(length(met)==1) {
         result[curr.index, 4] <- met
      } else {
        for( met.index in 1:length(met)) {
          result[curr.index, 4+(met.index-1)] <- met[met.index]
        }
      }
      curr.index <- curr.index+1
      
      if(progress && (curr.progress %% floor(progress.size/100))==0) {
        setTxtProgressBar(pb, floor(curr.index/2))
      }
      curr.progress <- curr.progress +1
    }
  }
  if(progress) {
    close(pb)
  }
  result$model <- model
  result$dataset <- dataset
  return(result)
}

CV2 <- function(df, df.outcome, fns, fold=5, do.training.err=T, progress=F, debug=F, model, dataset) {
  fit.fn <- fns[["fit.fn"]]
  pred.fn <- fns[["pred.fn"]]
  init.fn <- fns[["init.fn"]]
  debug.fn <- fns[["debug.fn"]]
  metrics.fn <- fns[["metrics.fn"]]
  n = nrow(df)
  result <- init.fn(fold)
  
  curr.index <- 1
  curr.progress <- 1
  if(progress) {
    progress.size <- fold
    pb <- txtProgressBar(min = 0, max = progress.size, style = 3)
  }
  
  fold.size <- floor(n/fold)
  train.size <- n-fold.size
  index.tbl <-  sample(rep(1:fold, length.out=n))
  for(iter in 1:fold) {
    inTrain <- which(index.tbl!=iter)
    train.x <- data.matrix(df[inTrain,])
    train.y <- df.outcome[inTrain,]
    test.x <- data.matrix(df[-inTrain,])
    test.y <- df.outcome[-inTrain,]
      
    fit <- fit.fn(train.x, train.y)
    
    prediction <- pred.fn(fit, test.x)
    if(debug&&!is.null(debug.fn)) {
      cat(curr.index, " - test\n")
      debug.fn(prediction, test.y)
    }
    result[curr.index, "iter"] <- iter
    result[curr.index, "n"] <- train.size
    met <- metrics.fn(prediction, test.y)
    for( met.index in 1:length(met)) {
      result[curr.index, 4+(met.index-1)] <- met[met.index]
    }
    curr.index <- curr.index+1
    
    if(progress && (curr.progress %% floor(progress.size/100))==0) {
      setTxtProgressBar(pb, floor(curr.index/2))
    }
    curr.progress <- curr.progress +1
  }
  if(progress) {
    close(pb)
  }
  result$model <- model
  result$dataset <- dataset
  result$fold <- fold
  return(result)
}