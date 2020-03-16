.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()
library(dplyr)
setwd("/gpfs/scratch/htn5098/DataAnalysis/testing/testing_RET_calculation/")
SDGridpoints <- read.csv("./data/SDGrid0125sort.txt")
grid <- unique(SDGridpoints$Grid)
SDCoordElevation <- read.csv("./data/SDElevation.csv")
el <- SDCoordElevation %>%
  rename(Grid=PointID) %>%
  select(c("Grid","Lat","Elev")) %>%
  filter(Grid%in%grid) 
if (any(rowSums(is.na(el)) == 0)) {
  write.csv(el,"SDGridElevation.csv",row.names=F)
} else {
  print("NA values appear")
}
