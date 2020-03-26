inputs = commandArgs(trailingOnly=T)
var=as.character(inputs[1])
write_file = as.character(inputs[2])
fun=as.character(inputs[3])

print(var)
print(write_file)
print(fun)

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

years <- 1979:2018
time <- seq.Date(as.Date('1979-01-01'), as.Date('2018-12-31'), by ='days')
ret_files <- list.files(path = inputpath,pattern = var, full.names = T) # changing path to gridMET files
gridpoint <- read.table("./data/external/ret_indx_clean.txt",sep = ',', header = T)
indx <- sort(unique(gridpoint$Grid))
county <- sort(unique(gridpoint$COUNTYNS))

# Extracting data from .nc files
print("Starting extracting data from individual .nc files")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Always import the library path to the workers
foreach(i = years,.verbose=F) %dopar% {
  library(ncdf4)
  nc_file <- nc_open(grep(i,ret_files,value=T))
  dt <- ncvar_get(nc_file,varid = names(nc_file$var),start = c(795,210,1), count = c(391,266,-1))
  dim <- dim(dt.m) 
  dt.m <- aperm(dt, c(3,2,1)) 
  dim(dt.m) <- c(dim[3],dim[2]*dim[1])
  dt.df <- data.frame(dt.m)
  colnames(dt.df) <- as.character(indx)
  write.csv(dt.df,paste0(names(nc_file$var),'_',i),row.names=F)
}
print("End of extracting")

print(paste("Start of aggregating grid to", write_file))
if (write_file == "grid_daily") {
  # Gridded daily dataset
  ret.grid.daily <- data.frame(year(time),month(time),ret.sd)
  colnames(ret.grid.daily) = c("Year","Month",as.character(indx))
  write.csv(ret.grid.daily,"GridMET_RET_grid_daily.csv",row.names = F)
} else if (write_file == "grid_monthly") {
  # Gridded monthly dataset
  ret.grid.daily <- data.frame(year(time),month(time),ret.sd)
  colnames(ret.grid.daily) = c("Year","Month",as.character(indx))
  ret.grid.monthly <- ret.grid.daily %>%
    group_by(Year,Month) %>%
    summarize_all(fun)
  write.csv(ret.grid.monthly,"GridMET_RET_grid_monthly.csv",row.names = F)
} else if (write_file == "county_daily") {
  # County-level daily dataset 
  ret.county.daily.m <- foreach(i = seq_along(county), .combine = cbind) %dopar% {
    pointid <- as.character(gridpoint$Grid[gridpoint$COUNTYNS == county[i]])
    wt <- gridpoint$Area[gridpoint$COUNTYNS == county[i]]
    var <- ret.sd[,pointid]
    head(var)
    if(is.null(dim(var))) {
      aggr = 0
    } else { 
      aggr <- apply(var,1,weighted.mean,w = wt,na.rm = T)
    }
  }
  ret.county.daily <- data.frame(year(time),month(time), ret.county.daily.m[,which(colSums(ret.county.daily.m) != 0)])
  colnames(ret.grid.daily) = c("Year","Month",as.character(county))
  head(ret.county.daily[,1:10])
  #write.csv(ret.county.daily,'GridMET_RET_county_daily.csv',row.names = F)
} else if (write_file == "county_monthly"){
  # County-level monthly dataset 
  ret.county.daily.m <- foreach(i = seq_along(county), .combine = cbind) %dopar% {
    pointid <- as.character(gridpoint$Grid[gridpoint$COUNTYNS == county[i]])
    wt <- gridpoint$Area[gridpoint$COUNTYNS == county[i]]
    var <- ret.sd[,pointid]
    head(var)
    if(is.null(dim(var))) {
      aggr = 0
    } else { 
      aggr <- apply(var,1,weighted.mean,w = wt,na.rm = T)
    }
  }
  ret.county.daily <- data.frame(year(time),month(time), ret.county.daily.m[,which(colSums(ret.county.daily.m) != 0)])
  colnames(ret.grid.daily) = c("Year","Month",as.character(county))
  ret.county.monthly <- ret.county.daily %>%
    group_by(Year,Month) %>%
    summarize_all(sum)
  head(ret.county.monthly[,1:10])
  #write.csv(ret.county.monthly,"GridMET_RET_county_monthly.csv",row.names = F)
}
print("End of aggregation")
stopCluster(cl)