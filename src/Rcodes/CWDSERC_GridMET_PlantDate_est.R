# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
#interimpath=as.character(inputs[1])
threshold=as.numeric(inputs[1])
#gcm=as.character(inputs[3])
#period=as.character(inputs[4])
cat('\n\n Planting date estimation of GridMET for threshold',threshold,'oC\n')

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
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers

# PROCESSING DATA
#thresholdname = gsub('[.]','',as.character(threshold))
filename=paste0('./data/processed/GridMET_hist_pld_county_',
                threshold,'.csv')
if (file.exists(filename)) {
  print("Planting date file already exists")
} else {
  # READING INPUT AND SUPPORTING DATA FILES
  spfile <- read.csv('./data/external/SERC_GridMET.csv',header=T) # files for COUNTYNS, grid cell and grid area weight 
  #grids <- sort(unique(spfile$Grid)) # all unique grids
  county <- sort(unique(spfile$COUNTYNS)) # all unique counties
  startyear = 1979
  startDate <- as.Date(paste0(startyear,"-01-01"),'%Y-%m-%d')
  # Input data
  tx.county = fread("./data/processed/GridMET_hist_tmmx_county.csv",header=T)
  tn.county = fread("./data/processed/GridMET_hist_tmmn_county.csv",header=T)
  tmean.county = (tx.county + tn.county)/2 - 273.16
  cat('\n Dimension of tmean:',dim(tmean.county),'\n')
  head(tmean.county[,1:5]) 
  time <- seq.Date(from=startDate,length.out = nrow(tmean.county),by="day")# using year as factor to split the county data into a list according to years later
  
  # FINDING PERIODS OF TWO WEEKS MORE THAN A THRESHOLD
  print("Start finding sowing date")
  county.pldate <- foreach(i = 1:ncol(tmean.county),.combine=rbind,
	.export=c('time','daysoverTruns','threshold','county'),
	.packages = c('lubridate','foreach')) %dopar% {
    # coding the T values into binary values:
    l <- ifelse(tmean.county[,i]>=threshold,1,0)
    ls <- split(l,f=year(time))
    years <- names(ls)
    pld <- foreach(j = seq_along(ls),.combine=rbind) %do% {
      t <- ls[[j]]
      doy <- data.frame(COUNTYNS = county[i], Year = years[j],PLD=daysoverTruns(t)) 
    }
  }
  print("Finshed finding sowing date")
  write.csv(county.pldate,filename,row.names = F)
}

stopCluster(cl)