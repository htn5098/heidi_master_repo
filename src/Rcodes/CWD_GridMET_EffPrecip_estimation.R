# *** ESTIMATING EFFECTIVE PRECIPITATION ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
var=as.character(inputs[2])
method=as.character(inputs[3])

cat('\n Historical effective rainfall estimation using ', method, '\n')

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
spfile <- fread('./data/external/SDGridMET4km.txt',header=T) # files for COUNTYNS, grid cell and grid area weight 
county <- sort(unique(spfile$COUNTYNS)) # all unique counties
pr_county = fread('./data/processed/GridMET_hist_pr_county.csv',header=T)
cat('\n Dimension of full pr:',dim(pr_county),'\n')
time <- seq.Date(from=as.Date('1979-01-01','%Y-%m-%d'),length.out = nrow(pr_county),by="day")# using year as factor to split the county data into a list according to years later

# AGGREGATING EFFECTIVE PRECIPITATION DATA TO THE COUNTY LEVEL
epfilename=paste0('./data/processed/GridMET_hist_',method,'_county.csv')
if (file.exists(epfilename)) {
  print("EP file already exists")
} else {
      
  # ESTIMATING EFFECTIVE RAINFALL 
  print("Start estimating effective precipitation")
  ep <- pr_county %>%
	mutate(Year=year(time),Month=month(time)) %>%
	group_by(Year,Month) %>%
	summarize_all(sum) %>%
    group_by(Year,Month) %>%
	summarize_all(method) %>%
	ungroup()
  colnames(ep) <- c('Year','Month',as.character(county))
  print("Finshed estimating effective precipitation")
  fwrite(ep,epfilename,row.names = F)  
}

stopCluster(cl)