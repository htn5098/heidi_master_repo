.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()
library(dplyr)
setwd("/storage/work/h/htn5098/DataAnalysis/") #changing working directory

# For UW grid expand (gridcell 12 km)
SDGridpoints <- read.csv("./data/external/SDGrid12km.txt")
grid <- unique(SDGridpoints$Grid)
SDCoordElevation <- read.csv("./data/external/SDElevation12km.csv")
el <- SDCoordElevation %>%
  select(c("Grid","Lat","Elev")) %>%
  filter(Grid%in%grid) 
if (any(rowSums(is.na(el)) == 0)) {
  write.csv(el,"./data/SDGridElev12km.csv",row.names=F)
} else {
  print("NA values appear")
}
# For GridMET historical grid expand (gricell 4km)
SDGridpoints <- read.csv("./data/external/SDGrid12km.txt")
grid <- unique(SDGridpoints$Grid)
SDCoordElevation <- read.csv("./data/external/SDElevation12km.csv")
el <- SDCoordElevation %>%
  select(c("Grid","Lat","Elev")) %>%
  filter(Grid%in%grid) 
if (any(rowSums(is.na(el)) == 0)) {
  write.csv(el,"./data/SDGridElev12km.csv",row.names=F)
} else {
  print("NA values appear")
}
# For GridMET MACA grid expand