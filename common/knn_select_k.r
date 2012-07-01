
KnnSelectK <- function(df, outcome, cv, debug=0) {
  fold <- 5
  n <- nrow(df)

  index.tbl <-  sample(rep(1:fold, length.out=n))
  fold.size <- floor(n/fold)
  train.size <- n-fold.size-1
  
  k.values <- seq(1, train.size)
  
  res.len <- length(k.values)*fold
  
  result <- data.frame(k=numeric(res.len), cv=numeric(res.len), type=character(res.len), train=numeric(res.len), test=numeric(res.len), stringsAsFactors=F)
  result.index <- 1
  distances <- as.matrix(dist(df))
  neighbours <- matrix(0, ncol=ncol(distances), nrow=nrow(distances))
  for(i in 1:nrow(distances)) {
    neighbours[i,] <- order(distances[i,])
  }
  if(debug) {
    print(distances[1:10,1:10])
    print(neighbours[1:10, 1:10])
  }
  for( iternum in 1:fold) {
    cat("Doing CV ",iternum, "/", fold, "\n", sep="")

    intrain <- which(index.tbl != iternum)
    intest <- which(index.tbl == iternum)

    for(k in k.values) {
      if(debug) cat("iternum=", iternum, " k=", k, "\n=====================\n") 
      
      #calculate training set error
      err <-0
      for(curr in intrain) {
        curr.neighbours <- as.numeric(neighbours[curr,])        
        curr.neighbours <- curr.neighbours[which(curr.neighbours %in% intrain)]
        pred <- ifelse(sum(outcome[curr.neighbours[1:k]]==1)>sum(outcome[curr.neighbours[1:k]]==0), 1, 0) 
        if(pred!=outcome[curr]) {
          err <- err+1
        }
      }
      err.train <- err/length(intrain)
      if(debug) cat("err.train=",err.train, "\n")

      ## calculate test error
      err <- 0
      for(curr in intest) {
        curr.neighbours <- as.numeric(neighbours[curr,])
        m <-curr.neighbours[which(curr.neighbours %in% intrain)]
        curr.neighbours <- curr.neighbours[m]
        pred <- ifelse(sum(outcome[curr.neighbours[1:k]]==1)>sum(outcome[curr.neighbours[1:k]]==0), 1, 0)
        if(pred!=outcome[curr]) {
          err <- err+1
        }
      }
      err.test <- err/length(intest)
      if(debug) cat("err.test=",err.test, "\n")

      result[result.index,1] <- k
      result[result.index,2] <- iternum
      result[result.index,3] <- "KNN"
      result[result.index,4] <- err.train
      result[result.index,5] <- err.test
    
      result.index <- result.index+1
    }
  }
  return(result)
}


##################################################

data(iris)
df <- iris[iris$Species=="setosa"|iris$Species=="versicolor",]
df$Species <- factor(df$Species)
outcome <- df[,5]
levels(outcome) <- c(0,1)
outcome <- as.numeric(levels(outcome)[outcome])
df <- df[,-5]
res <- KnnSelectK(df, outcome, 1)

res.m <- melt(res[,-3], id=c("k", "cv"), measured=c("test", "train"))
res.m$id <- rep(1:10, each=79)

res.m.aggr <- aggregate(value~k+variable, res.m, mean)
res.m.aggr$id <- rep(1:2, each=79)

ggplot(res.m, aes(x=k, y=value, group=id))+
  geom_line(aes(color=variable), alpha=1/5)+
  geom_line(data=res.m.aggr, aes(x=k, y=value, group=id, color=variable))
  
  
