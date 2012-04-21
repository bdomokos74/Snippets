library(ggplot2)
library(reshape)

source("cv.r")
data(iris)

df <- iris[iris$Species=="setosa"|iris$Species=="versicolor",]
df$Species <- factor(df$Species)
outcome <- df[,5]
levels(outcome) <- c(0,1)
outcome <- as.numeric(levels(outcome)[outcome])
outcome.fac <- factor(outcome)
df <- df[,-5]
outcome.fac.df <- data.frame(outcome=outcome.fac)

iris.df <- cbind(df, outcome)
iris.df$outcome <- factor(iris.df$outcome)
iris.df$id <- rownames(iris.df)
iris.df <- cbind(iris.df[,6,drop=F], iris.df[,-6])

ggplot(iris.df, aes(Sepal.Length, Sepal.Width, color=outcome))+geom_point()
ggplot(iris.df, aes(Sepal.Length, Petal.Width, color=outcome))+geom_point()

BaselineFit <- function(x, y) {
  return( list(x,y))
}
BaselinePred <- function(m, x) {
  return(rep(1, length(x)))
}
LogregFit <- function(x,y) {
   return(glmnet(x, y, family="binomial"))
}
LogregPred  <- function(m, x) {
  return(ifelse(predict(m, newx=x)>0, 1, 0))
}

fns <- list(fit.fn=BaselineFit, pred.fn=BaselinePred, init.fn=InitErrRate, metrics.fn=ErrRate)
cv.iris.base <- CV2(df, outcome.fac.df, fns=fns, dataset="iris2", model="base")
lc.iris.base <- LC2(df, outcome.fac.df ,fns=fns, do.training.err=T, start.n=5, debug=F, progress=F, model="baseline", dataset="iris2" )
lc.iris.base.aggr <- aggregate(ErrRate~n+type+model+dataset, lc.iris.base, mean)


fns <- list(fit.fn=LogregFit, pred.fn=LogregPred, init.fn=InitErrRate, metrics.fn=ErrRate)
cv.iris.logreg <- CV2(df, outcome.fac.df, fns, dataset="iris2", model="logreg")
lc.iris.logreg <- LC2(df, outcome.fac.df ,fns=fns, do.training.err=T, start.n=6, debug=F, progress=F, model="logreg", dataset="iris2" )
lc.iris.logreg.aggr <- aggregate(ErrRate~n+type+model+dataset, lc.iris.logreg, mean)

lc.iris.all <- rbind(lc.iris.base.aggr, lc.iris.logreg.aggr)
(p.lc.iris <- ggplot(lc.iris.all, aes(x=n, y=ErrRate, color=type))+geom_point()+geom_line()+facet_grid(model~., scales="free_y")+opts(title="iris2 LC"))


