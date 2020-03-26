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
outpath = '...' # changing path to output files

library(foreach)
library(doParallel)
library(parallel)
library(lubridate)
library(dplyr)
library(data.table)

no_cores <- detectCores()
cl <- makeCluster(no_cores)
registerDoParallel(cl)

years <- 1979:2018
time <- seq.Date(as.Date('1979-01-01'), as.Date('2018-12-31'), by ='days')
ret_files <- list.files(path = '/storage/home/htn5098/scratch/DataAnalysis/data/raw/gridMET',pattern = var, full.names = T) # changing path to gridMET files
gridpoint <- read.table("./data/external/ret_indx_clean.txt",sep = ',', header = T)
indx <- sort(unique(gridpoint$Grid))
county <- sort(unique(gridpoint$COUNTYNS))

# Gridded daily RET dataset
print("Starting aggregating individual .nc files")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Always import the library path to the workers
ret.sd <- foreach(i = years,.verbose=F,.combine = rbind) %dopar% { #.export=c("ret_files","indx") -> this returns a warning
  library(ncdf4)
  nc_file <- nc_open(grep(i,ret_files,value=T))
  ret <- ncvar_get(nc_file,varid = names(nc_file$var),start = c(795,210,1), count = c(391,266,-1))
  dim <- dim(ret) 
  ret_matrix <- aperm(ret, c(3,2,1)) 
  dim(ret_matrix) <- c(dim[3],dim[2]*dim[1]) 
  ret_sel <- ret_matrix[,indx]
  return(ret_sel)
}
print("End of aggregation")

print(paste("Start of aggregating grid to", write_file))
if (write_file == "grid_daily") {
  # Gridded daily RET dataset
  ret.grid.daily <- data.frame(year(time),month(time),ret.sd)
  colnames(ret.grid.daily) = c("Year","Month",as.character(indx))
  write.csv(ret.grid.daily,"GridMET_RET_grid_daily.csv",row.names = F)
} else if (write_file == "grid_monthly") {
  # Gridded monthly RET dataset
  ret.grid.daily <- data.frame(year(time),month(time),ret.sd)
  colnames(ret.grid.daily) = c("Year","Month",as.character(indx))
  ret.grid.monthly <- ret.grid.daily %>%
    group_by(Year,Month) %>%
    summarize_all(fun)
  write.csv(ret.grid.monthly,"GridMET_RET_grid_monthly.csv",row.names = F)
} else if (write_file == "county_daily") {
  # County-level daily RET dataset 
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
    summarize_all(fun)
  head(ret.county.monthly[,1:10])
  #write.csv(ret.county.monthly,"GridMET_RET_county_monthly.csv",row.names = F)
}
print("End of aggregation")
stopCluster(cl)