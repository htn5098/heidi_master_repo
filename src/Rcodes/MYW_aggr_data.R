inputs = commandArgs(trailingOnly=T)
namevar=as.character(inputs[1])

.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()
setwd('/storage/work/h/htn5098/DataAnalysis/') # changing working directory
inputpath='/storage/home/htn5098/scratch/DataAnalysis/data/raw/gridMET'
interim= '/storage/home/htn5098/scratch/DataAnalysis/data/interim' # 
outputpath= './data/processed/'

library(foreach)
library(doParallel)
library(parallel)
library(lubridate)
library(dplyr)
library(data.table)

no_cores <- detectCores()
cl <- makeCluster(no_cores-1)
registerDoParallel(cl)

#years <- 1979:2018
#time <- seq.Date(as.Date('1979-01-01'), as.Date('2018-12-31'), by ='days')
csvfiles <- list.files(path = interim,pattern = paste0('^gridMET.*',namevar), full.names = T) # changing path to gridMET files
gridpoint <- read.table("./data/external/ret_indx_clean.txt",sep = ',', header = T)
indx <- sort(unique(gridpoint$Grid))
county <- sort(unique(gridpoint$COUNTYNS))

# Aggregating gridded data to county level
print(paste("Start of aggregating grid to county level"))
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Always import the library path to the workers
aggr.data <- foreach(i = csvfiles,.combine=rbind) %dopar% {
  library(foreach)
  grid.data <- read.csv(i,header=T, check.names=F)
  county.data <- foreach(i = seq_along(county), .combine = cbind) %do% {
    pointid <- as.character(gridpoint$Grid[gridpoint$COUNTYNS == county[i]])
    wt <- gridpoint$Area[gridpoint$COUNTYNS == county[i]]
    var <- grid.data[,pointid]
    if(is.null(dim(var))) {
      aggr = 0
    } else { 
      aggr <- apply(var,1,weighted.mean,w = wt,na.rm = T)
    }
  }
}
aggr.data.df <- data.frame(aggr.data)
colnames(aggr.data.df) <- as.character(county)
write.csv(aggr.data,paste0(outputpath,"GridMET_",namevar,"_county_daily.csv"),row.names=F)
print("End of aggregation")
stopCluster(cl)