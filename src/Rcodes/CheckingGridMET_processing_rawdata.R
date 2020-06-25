.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()
setwd('/storage/work/h/htn5098/DataAnalysis/') # changing working directory
#inputpath='/storage/home/htn5098/scratch/DataAnalysis/data/raw/gridMET_check/'
#interim= '/storage/home/htn5098/scratch/DataAnalysis/data/interim/' # 

library(foreach)
library(doParallel)
library(parallel)
library(ncdf4)

no_cores <- detectCores()
cl <- makeCluster(no_cores-1)
registerDoParallel(cl)

ncfiles <- './src/jobs/macav2metdata_tasmax_HadGEM2-ES365_r1i1p1_historical_2005_2005_CONUS_daily.nc'
#list.files(path = inputpath, full.names = T) # changing path to gridMET files
gridpoint <- read.table("./data/external/ret_indx_clean.txt",sep = ',', header = T)
indx <- sort(unique(gridpoint$Grid))

# Extracting data from .nc files
print("Starting extracting data from individual .nc files")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Always import the library path to the workers
#foreach(i = ncfiles,.verbose=F,.errorhandling='remove') %dopar% { 
  i = ncfiles
  library(ncdf4)
  nc <- nc_open(i)
  print(nc)
  varatt <- ncatt_get(nc,varid=names(nc$var))
  dt <- ncvar_get(nc,varid = names(nc$var),start = c(795,210,1), count = c(391,266,-1))
  dim <- dim(dt) 
  dt.m <- aperm(dt, c(3,2,1)) 
  dim(dt.m) <- c(dim[3],dim[2]*dim[1])
  dt.sd <- dt.m[,indx]
  dt.df <- data.frame(dt.sd)
  colnames(dt.df) <- as.character(indx)  
  write.csv(dt.df,paste0('gridMET_',varatt$standard_name,'.csv'),row.names=F) #interim,
#}
print("End of extracting")

stopCluster(cl)