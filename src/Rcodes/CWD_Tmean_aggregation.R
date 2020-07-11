# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
gcm=as.character(inputs[2])
period=as.character(inputs[3])
cat('\n\n Aggregating Tmean for',c(gcm, period))

# CHANGING LIBRARY PATH
.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

# CHANGING WORKING DIRECTORIES AND PATHS FOR INPUT AND INTERIM FILES
setwd('/storage/work/h/htn5098/DataAnalysis')
source('./src/Rcodes/CWD_function_package.R') # calling the functions customized for the job

# CALLING LIBRARIES
library(filematrix)
library(foreach)
library(doParallel)
library(parallel)
library(data.table)
library(lubridate)

# REGISTERING WORKERS FOR PARALLEL PROCESSING
no_cores <- detectCores()
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# PROCESSING DATA
outname=paste0(interimpath,'/interim_', gcm,'_',period,'_tmean')
if (file.exists(outname)) {
  print("Tmean matrix already exists")
} else {
  print("Starting aggregating Tmean")
  # READING INPUT AND SUPPORTING DATA FILES
  spfile <- read.csv('./data/external/SDMACA4km.txt',header=T) # files for COUNTYNS, grid cell and grid area weight 
  grids <- sort(unique(spfile$Grids)) # all unique grids
  county <- sort(unique(spfile$COUNTYNS)) # all unique counties
  # Input data
  tx = fm.load(paste0(interimpath,'/interim_',
                      gcm,'_',period,'_tasmax')) # maximum temperature matrix
  tn = fm.load(paste0(interimpath,'/interim_',
                      gcm,'_',period,'_tasmin')) # minimum temperature matrix
  tmean = (tx + tn)/2 - 273.15 # transforming data K degrees to C degrees
  cat('\n Dimension of tmean:')
  dim(tmean)
  # AGGREGATE GRIDS TO COUNTY
  print("Start aggregating")
  invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
  # After several trials, using %dopar% is actually slower and more error-prone than using %do%
  # using %do% thus no need for clusterExport
  county.data <- foreach(i = county, .combine = cbind) %dopar% { 
    d <- aggr_data(gridpoint=spfile,county=i,data=tmean)
    return(d)
  }
  print("Fnished aggregating")
  head(county.data[,1:10])
  output = fm.create.from.matrix(outname,tmean)
}

stopCluster(cl)