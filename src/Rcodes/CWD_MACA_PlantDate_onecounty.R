# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
interimpath='/storage/home/htn5098/scratch/DataAnalysis/data/interim'
threshold=10
gcm="GFDL-ESM2G"
period="rcp45"
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
 # READING INPUT AND SUPPORTING DATA FILES
  spfile <- read.csv('./data/external/SDMACA4km.txt',header=T) # files for COUNTYNS, grid cell and grid area weight 
  county <- which(spfile$COUNTYNS==293656)
  grids <- spfile$Grid[spfile$COUNTYNS==county] # all unique grids
  if (period == 'historical') {
    startyear = 1950
  } else {
    startyear = 2006
  }
  startDate <- as.Date(paste0(startyear,"-01-01"),'%Y-%m-%d')
  # Input data
  tx = fm.load(paste0(interimpath,'/interim_',
                      gcm,'_',period,'_tasmax')) # maximum temperature matrix
					  head(tx[,1:6])
  tn = fm.load(paste0(interimpath,'/interim_',
                      gcm,'_',period,'_tasmin')) # minimum temperature matrix
					  head(tn[,1:6])
  tmean.county = (tx + tn)/2 - 273.15 # transforming data K degrees to C degrees
    time <- seq.Date(from=startDate,length.out = nrow(tmean.county),by="day")# using year as factor to split the county data into a list according to years later
  dim(tmean.county)
  head(tmean.county[,county][year(time)==2099])
  tmean.county2 = fm.load(paste0(interimpath,'/interim_',gcm,'_',period,'_tmean'))
  #cat('\n Dimension of tmean:',dim(tmean.county),'\n')
  head(tmean.county[,1:6])
  # a
  b <- tmean.county2[,"293656"][year(time)==2099]
  head(b)
  # l <- ifelse(b>=threshold,1,0)
  # l
  # daysoverTruns(l)
  # ls <- split(l,f=year(time))
  # length(ls)
    # years <- names(ls)
    # pld <- foreach(j = seq_along(ls),.combine=rbind) %do% {
      # t <- ls[[j]]
      # doy <- data.frame(COUNTYNS = county, Period = period,
                        # Year = years[j],PLD=daysoverTruns(t)) 
    # }
  # print(pld)
  
  # FINDING PERIODS OF TWO WEEKS MORE THAN A THRESHOLD
  # print("Start finding sowing date")
  # county.pldate <- foreach(i = as.character(county),.combine=rbind) %do% {
    # # coding the T values into binary values:
    # l <- ifelse(tmean.county[,i]>=threshold,1,0)
    # ls <- split(l,f=year(time))
    # years <- names(ls)
    # pld <- foreach(j = seq_along(ls),.combine=rbind) %do% {
      # t <- ls[[j]]
      # doy <- data.frame(COUNTYNS = county, Period = period,
                        # Year = years[j],PLD=daysoverTruns(t)) 
    # }
  # }
  # print("Finshed finding sowing date")
  # #write.csv(county.pldate,filename,row.names = F)
# #}
# print(county.pldate)

stopCluster(cl)