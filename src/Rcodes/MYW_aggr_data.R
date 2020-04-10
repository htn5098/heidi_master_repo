inputs = commandArgs(trailingOnly=T)
namevar=as.character(inputs[1])
level=as.character(inputs[2])

print(level)

.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()
setwd('/storage/work/h/htn5098/DataAnalysis/') # changing working directory
inputpath='/storage/home/htn5098/scratch/DataAnalysis/data/raw/gridMET'
interim= '/storage/home/htn5098/scratch/DataAnalysis/data/interim' # 
outputpath= './data/processed/'

library(foreach)
library(doParallel)
library(parallel)

no_cores <- detectCores()
cl <- makeCluster(no_cores-1)
registerDoParallel(cl)

csvfiles <- list.files(path = interim,pattern = paste0('^gridMET.*',namevar,'.*1979'), full.names = T) # changing path to gridMET files
print(csvfiles)
gridpoint <- read.table("./data/external/ret_indx_clean.txt",sep = ',', header = T)
column.names <- list(grid = sort(unique(gridpoint$Grid)),
                    county = sort(unique(gridpoint$COUNTYNS)))

# Aggregating gridded data 
print(paste("Start of aggregating grid to",level))
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Always import the library path to the workers
aggr.data <- foreach(i = csvfiles,.combine=rbind) %dopar% {
  library(foreach)
  library(data.table)
  grid.data <- fread(i,header=T, check.names=F)
  if (level=="county") {
    county = column.names$county
    county.data <- foreach(i = seq_along(column.names$county), .combine = cbind) %do% {
      pointid <- as.character(gridpoint$Grid[gridpoint$COUNTYNS == county[i]])
      wt <- gridpoint$Area[gridpoint$COUNTYNS == county[i]]
      var <- grid.data[,pointid,with=F]
      if(is.null(dim(var))) {
        aggr = 0
      } else { 
        aggr <- apply(var,1,weighted.mean,w = wt,na.rm = T)
      }
    }
    return(county.data)
  } else {
    return(grid.data)
  }  
}
print("End of aggregation")

aggr.data.df <- data.frame(aggr.data)
colnames(aggr.data.df) <- as.character(column.names[[level]]) #indx for pdsi, county for precipitation and pet
write.csv(aggr.data.df,paste0(outputpath,"GridMET_",namevar,"_",level,"_daily.csv"),row.names=F)

stopCluster(cl)