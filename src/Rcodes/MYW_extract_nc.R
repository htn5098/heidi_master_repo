inputs = commandArgs(trailingOnly=T)
var=as.character(inputs[1])
end.year = inputs[2]

.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()
setwd('/storage/work/h/htn5098/DataAnalysis/') # changing working directory
inputpath='/storage/home/htn5098/scratch/DataAnalysis/data/raw/gridMET/'
interim= '/storage/home/htn5098/scratch/DataAnalysis/data/interim/' # 
outputpath= './data/processed/'

library(foreach)
library(doParallel)
library(parallel)
library(lubridate)
library(dplyr)
library(data.table)
library(ncdf4)

no_cores <- detectCores()
cl <- makeCluster(no_cores-1)
registerDoParallel(cl)

years = 1979:end.year
ncfiles <- list.files(path = inputpath,pattern = var, full.names = T) # changing path to gridMET files
gridpoint <- read.table("./data/external/ret_indx_clean.txt",sep = ',', header = T)
indx <- sort(unique(gridpoint$Grid))
county <- sort(unique(gridpoint$COUNTYNS))

# Extracting data from .nc files
print("Starting extracting data from individual .nc files")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Always import the library path to the workers
foreach(i = years,.verbose=F,.errorhandling='remove') %dopar% { 
  library(ncdf4)
  nc <- nc_open(grep(i,ncfiles,value=T))
  dt <- ncvar_get(nc,varid = names(nc$var),start = c(795,210,1), count = c(391,266,-1))
  dim <- dim(dt) 
  dt.m <- aperm(dt, c(3,2,1)) 
  dim(dt.m) <- c(dim[3],dim[2]*dim[1])
  dt.sd <- dt.m[,indx]
  dt.df <- data.frame(dt.sd)
  colnames(dt.df) <- as.character(indx)  
  write.csv(dt.df,paste0(interim,'gridMET_',names(nc$var),'_',i,'.csv'),row.names=F)
}
print("End of extracting")

stopCluster(cl)