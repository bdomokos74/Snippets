library(affy)
library(ALL)
library(genefilter)
data(ALL)
pdat <- pData(ALL)
subset <- intersect(grep("^B", as.character(pdat$BT)),
     which(pdat$mol %in% c("BCR/ABL", "NEG")))
eset <- ALL[, subset]

unfactor <- function(f) {
  levels(f)[f]
}

## non-specific filtering
sample.types <- data.frame(cod=rownames(pdat), mol.biol=pdat[,"mol.biol"], stringsAsFactors=F)
sample.types$mol.biol <- unfactor(sample.types$mol.biol)

samples <- data.frame(cod=colnames(exprs(eset)), stringsAsFactors=F)
samples <- merge(samples, sample.types, by="cod", all.x=T)

neg.sel <- which(samples$mol.biol=="NEG")
pos.sel <- which(samples$mol.biol!="NEG")

avg.neg <- apply(exprs(eset)[,neg.sel], 1, mean)
avg.pos <- apply(exprs(eset)[,pos.sel], 1, mean)
iqrs <- apply(exprs(eset), 1, IQR)
low.expr <- apply(exprs(eset), 1, function(x) sum(x>log2(100))<(.25*length(x)))
df <- data.frame(neg=avg.neg, pos=avg.pos, iqr=iqrs, low.expr=low.expr)
df$col <- "normal"
df[df$iqr<.5|df$low.expr,"col"] <- "filt"
df$col <- factor(df$col)
ggplot(df, aes(neg, pos, color=col))+geom_point()
ggplot(df, aes(neg, iqrs, color=col))+geom_point()
ggplot(df, aes(.5*(neg+pos), .5*(-neg+pos), color=col))+geom_point()

# genefilter
f1 <- pOverA(.25, log2(100))
f2 <- function(x) IQR(x) > .5
ff <- filterfun(f1, f2)
selected <- genefilter(eset, ff)
esetSub <- eset[selected,]
ggplot(df, aes(.5*(neg+pos), .5*(-neg+pos), color=col))+geom_point()

avg.neg.sub <- apply(exprs(esetSub)[,neg.sel], 1, mean)
avg.pos.sub <- apply(exprs(esetSub)[,pos.sel], 1, mean)
iqrs.sub <- apply(exprs(esetSub), 1, IQR)
df.sub <- data.frame(neg=avg.neg.sub, pos=avg.pos.sub, iqr=iqrs.sub)
ggplot(df.sub, aes(.5*(neg+pos), .5*(-neg+pos)))+geom_point()

df.sub$fc = df.sub$pos/df.sub$neg
ggplot(df.sub, aes(iqr, fc))+geom_point()

#####################
library(multtest)
cl <- as.numeric(esetSub$mol == "BCR/ABL")

# FWER control - welch t
resT <- mt.maxT(exprs(esetSub), classlabel = cl, B = 10000)

ggplot(data.frame(pv=resT$rawp), aes(pv))+geom_histogram(binwidth=.01)
ggplot(data.frame(pv=resT$adjp), aes(pv))+geom_histogram(binwidth=.01)

ord <- order(resT$index)
rawp <- resT$rawp[ord]
sum(rawp<.05)
names(rawp) <- featureNames(esetSub)
ggplot(data.frame(pv=rawp), aes(pv))+geom_histogram(binwidth=.01)

## FDR control - BH correction
res <- mt.rawp2adjp(rawp, proc = "BH")
sum(res$adjp[, "BH"] < 0.05)
ggplot(data.frame(pv=res$adjp[,"BH"]), aes(pv))+geom_histogram(binwidth=.01)


## effects of filtering
iqrs <- esApply(eset, 1, IQR)
o.iqr <- order(iqrs)
intensity.score <- esApply(eset, 1, function(x) quantile(x, .75))
o.intensity <- order(intensity.score)
abs.t <- abs(mt.teststat(exprs(eset), classlabel=cl))
filt.effects <- data.frame(t.val = abs.t, r.iqr=o.iqr, r.intensity=o.intensity)

window.x <- as.integer(seq(0, length(abs.t), length.out=20))
intensity.ma <- c()
iqr.ma <- c()
for(i in 1:(length(window.x)-1))
{
  intensity.ma <- c(intensity.ma, quantile(abs.t[o.intensity[window.x[i]:window.x[i+1]]], .95))
  iqr.ma <- c(iqr.ma, quantile(abs.t[o.iqr[window.x[i]:window.x[i+1]]], .95))
}
avg.intensity <- data.frame(x=window.x[1:(length(window.x)-1)], y=intensity.ma)
avg.iqr <- data.frame(x=window.x[1:(length(window.x)-1)], y=iqr.ma)
ggplot(filt.effects, aes(r.intensity, t.val))+geom_point(color="grey")+geom_point(data=avg.intensity, aes(x,y), color="red", size=4)
ggplot(filt.effects, aes(r.iqr, t.val))+geom_point(color="grey")+geom_point(data=avg.iqr, aes(x,y), color="red", size=4)

### filtering based on GO data
library(hgu95av2.db)
library(annotate)
tykin <- unique(lookUp("GO:0004713", "hgu95av2", "GO2ALLPROBES"))

intersect(featureNames(esetSub), tykin[[1]])

sel.go <- which(featureNames(esetSub) %in% tykin[[1]])
eset.go <- esetSub[sel.go,]
res.go <- mt.maxT(exprs(eset.go), classlabel = cl, B = 10000)



