# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
threshold=as.numeric(inputs[2])
gcm=as.character(inputs[3])
period=as.character(inputs[4])
cat('\n\n Planting date estimation for',c(gcm, period),' for threshold',
    threshold,'oC\n')

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
thresholdname = gsub('[.]','',as.character(threshold))
filename=paste0('./data/processed/GridMET_',gcm,'_',period,'_pld_county_',
                thresholdname,'.csv')
if (file.exists(filename)) {
  print("Planting date file already exists")
} else {
  # READING INPUT AND SUPPORTING DATA FILES
  spfile <- read.csv('./data/external/SDMACA4km.txt',header=T) # files for COUNTYNS, grid cell and grid area weight 
  #grids <- sort(unique(spfile$Grid)) # all unique grids
  county <- sort(unique(spfile$COUNTYNS)) # all unique counties
  if (period == 'historical') {
    startyear = 1950
  } else {
    startyear = 2006
  }
  startDate <- as.Date(paste0(startyear,"-01-01"),'%Y-%m-%d')
  # Input data
  tmean.county = fm.load(paste0(interimpath,'/interim_',gcm,'_',period,'_tmean'))
  cat('\n Dimension of tmean:',dim(tmean.county),'\n')
  time <- seq.Date(from=startDate,length.out = nrow(tmean.county),by="day")# using year as factor to split the county data into a list according to years later
  
  # FINDING PERIODS OF TWO WEEKS MORE THAN A THRESHOLD
  print("Start finding sowing date")
  county.pldate <- foreach(i = 1:ncol(tmean.county),.combine=rbind) %do% {
    # coding the T values into binary values:
    l <- ifelse(tmean.county[,i]>=threshold,1,0)
    ls <- split(l,f=year(time))
    years <- names(ls)
    pld <- foreach(j = seq_along(ls),.combine=rbind) %do% {
      t <- ls[[j]]
      doy <- data.frame(COUNTYNS = county[i], Period = period,
                        Year = years[j],PLD=daysoverTruns(t)) 
    }
  }
  print("Finshed finding sowing date")
  write.csv(county.pldate,filename,row.names = F)
}

stopCluster(cl)