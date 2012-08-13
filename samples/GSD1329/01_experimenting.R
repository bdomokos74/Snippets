library(affy)

dat <- read.table("data/brca.csv", sep=",", h=T)
dat$Title <- NULL

ma.data <- ReadAffy(filenames=paste("data/array/", dat$Samples, ".CEL", sep=""))
sample.names <- dat$Tumor
colnames(exprs(ma.data)) <- sample.names

e <- exprs(ma.data)
dim(e)

gnames <- geneNames(ma.data)
image(ma.data)

boxplot(ma.data, col=c(rep("green", 6), rep("blue", 16), rep("red", 27)))
mva.pairs(data.frame(a=exprs(ma.data[,c(1,2,7,8, 23, 24)])))

### preprocess :::::
eset <- rma(ma.data)
exprs(eset[1:20,1:3])

boxplot(data.frame(exprs(eset)), col=c(rep("green", 6), rep("blue", 16), rep("red", 27)))
mva.pairs(data.frame(exprs(eset[,c(1,8,23)])))

### limma
library(limma)
design <- model.matrix(~ 0+factor(c(rep("apocrine", 6), rep("basal", 16), rep("luminal", 27))))
colnames(design) <- c("apocrine", "basal", "luminal")
fit <- lmFit(eset, design)

cont.matrix <- makeContrasts(Comp2to1=basal-apocrine, Comp3to1=luminal-apocrine, Comp3to2=luminal-basal, levels=design)
fit2 <- contrasts.fit(fit, cont.matrix)
fit2 <- eBayes(fit2)

## gene list
options(digits=3)
toptable(fit2, coef=1, adjust="BH")

## plots
volcanoplot(fit2, coef=2, highlight=10)
abline(v=c(-1,1), col="red")
ilogit = function(p) exp(p)/(1+exp(p))
abline(h=ilogit(.05), col="blue")

## venn diagram
results <- decideTests(fit2)
venn <- vennCounts(results)
venn
vennDiagram(results, include=c("up", "down"), counts.col=c("red", "green"))




###
# create affybatch
preproc.data <- as.matrix(exprs(eset)[,c(1,8)])
colnames(preproc.data) <- NULL
sample.info <- data.frame( spl = gsub(".CEL", "", colnames(exprs(eset)[,c(1,8)])), stat = levels(dat$Tumor)[dat$Tumor][c(1,8)])
meta.info <- data.frame (labelDescription = c('Sample Name', 'Cancer Status'))

pheno <- new("AnnotatedDataFrame", data = sample.info, varMetadata = meta.info)
my.experiments <- new("AffyBatch",  exprs=preproc.data, phenoData=pheno, cdfName="HG-U133A")

### book example
fake.data <- matrix(rnorm(8*200), ncol=8)


sample.info <- data.frame(spl=paste('A', 1:8, sep=''),stat=rep(c('cancer', 'healthy'), each=4))
pheno <- new("AnnotatedDataFrame", data = sample.info,varMetadata = meta.info)
my.experiments <- new("AffyBatch",exprs=fake.data, phenoData=pheno)

