library(plyr)

NMissing <- function(x) sum(is.na(x))
colwise(NMissing)(df)