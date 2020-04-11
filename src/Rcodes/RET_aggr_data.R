.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()
setwd('/storage/work/h/htn5098/DataAnalysis/') # changing working directory
outputpath= './data/processed/'

library(foreach)
library(doParallel)
library(parallel)
library(data.table)

no_cores <- detectCores()
cl <- makeCluster(no_cores-1)
registerDoParallel(cl)

grid.data <- fread("./data/processed/UW_historical_RET_grid_daily.csv",header=T)
gridpoint <- read.table("./data/external/SDGrid0125sort.txt",sep = ',', header = T)
grid = sort(unique(gridpoint$Grid))
county = sort(unique(gridpoint$COUNTYNS))
head(county)

# Aggregating gridded data 
print(paste("Start of aggregating grid to county level"))
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Always import the library path to the workers
aggr.data <- foreach(i = seq_along(county), .combine = cbind) %dopar% {
  pointid <- as.character(gridpoint$Grid[gridpoint$COUNTYNS == county[i]])
  wt <- gridpoint$Area[gridpoint$COUNTYNS == county[i]]
  var <- grid.data[,pointid]
  if(is.null(dim(var))) {
    aggr = 0
  } else { 
    aggr <- apply(var,1,weighted.mean,w = wt,na.rm = T)
  }
}
print("End of aggregation")
aggr.data.df <- data.frame(aggr.data)
colnames(aggr.data.df) <- as.character(county) #indx for pdsi, county for precipitation and pet
head(aggr.data.df[,1:10])
write.csv(aggr.data.df,paste0(outputpath,"UW_historical_RET_county_daily.csv"),row.names=F)