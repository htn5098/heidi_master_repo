# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu
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

# READING INPUT AND SUPPORTING DATA FILES
spfile <- read.csv('./data/external/SDMACA4km.txt',header=T) # files for COUNTYNS, grid cell and grid area weight 
grids <- sort(unique(spfile$Grids)) # all unique grids
county <- sort(unique(spfile$COUNTYNS)) # all unique counties
if (period == 'historical') {
  startyear = 1950
} else {
  startyear = 2006
}
startDate <- as.Date(paste0(startyear,"-01-01"),'%Y-%m-%d')
# Input data
tx = fm.load(paste0(interimpath,'/interim_',
                    gcm,'_',period,'_tasmax')) # maximum temperature matrix
tn = fm.load(paste0(interimpath,'/interim_',
                          gcm,'_',period,'_tasmin')) # minimum temperature matrix
tmean = (tx + tn)/2 - 273.15 # transforming data K degrees to C degrees
cat('\n Dimension of tmean:')
dim(tmean)
time <- seq.Date(from=startDate,length.out = nrow(tmean),by="day")# using year as factor to split the county data into a list according to years later

# AGGREGATE GRIDS TO COUNTY
print("Start aggregating")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
# After several trials, using %dopar% is actually slower and more error-prone than using %do%
# using %do% thus no need for clusterExport
county.data <- foreach(i = county, .combine = cbind) %do% { 
  d <- aggr_data(gridpoint=spfile,county=i,data=tmean)
  return(d)
}
print("Fnished aggregating")

# FINDING PERIODS OF TWO WEEKS MORE THAN A THRESHOLD
print("Start finding sowing date")
county.pldate <- foreach(i = 1:ncol(county.data),.combine=rbind) %do% {
  # coding the T values into binary values:
  l <- ifelse(county.data[,i]>=threshold,1,0)
  ls <- split(l,f=year(time))
  years <- names(ls)
  pld <- foreach(j = seq_along(ls),.combine=rbind) %do% {
    t <- ls[[j]]
    doy <- data.frame(COUNTYNS = county[i], Period = period,
                       Year = years[j],PLD=daysoverTruns(t)) 
  }
}
# .packages=c('lubridate'),
# .export=c('time','daysoverTruns')
print("Finshed finding sowing date")

thresholdname = gsub('[.]','',as.character(threshold))
write.csv(county.pldate,paste0('./data/processed/GridMET_',gcm,'_',period,'_pld_county_',thresholdname,'.csv'),row.names = F)

stopCluster(cl)