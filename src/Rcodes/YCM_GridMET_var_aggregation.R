# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
varname=as.character(inputs[2])

cat('\n Aggregating ', varname, '\n')

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
library(dplyr)

# REGISTERING WORKERS FOR PARALLEL PROCESSING
no_cores <- detectCores()
cl <- makeCluster(no_cores)
registerDoParallel(cl)
#invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers

# READING INPUT AND SUPPORTING DATA FILES
spfile <- read.csv('./data/external/SERC_GridMET.csv',header=T) # files for COUNTYNS, grid cell and grid area weight 
grids <- sort(unique(spfile$Grid)) # all unique grids
county <- sort(unique(spfile$COUNTYNS)) # all unique counties
length(county)

# Input data
data = fm.load(paste0(interimpath,'/interim_GridMET_hist_',varname))
cat('\n Dimension of full data:',dim(data),'\n')
time <- seq.Date(from=as.Date('1979-01-01','%Y-%m-%d'),length.out = nrow(data),by="day")# using year as factor to split the county data into a list according to years later

# AGGREGATING PRECIPITATION DATA TO THE COUNTY LEVEL
opfilename=paste0('./data/processed/GridMET_hist_',varname,'_county.csv')
if (file.exists(opfilename)) {
  print("OP file already exists")
} else {
  # AGGREGATE GRIDS TO COUNTY
  print("Start aggregating")
  # hello
  #clusterExport(cl,list('aggr_data','data','spfile')) #exporting data into clusters for parallel processing
  county.data <- foreach(i = county, .combine = cbind) %do% { 
    d <- aggr_data(gridpoint=spfile,county=i,data=data)
    return(d)
  }
  county.data <- data.frame(county.data)
  colnames(county.data) <- as.character(county)
  print("Finished aggregating")
  fwrite(county.data,opfilename,row.names = F)
}

stopCluster(cl)