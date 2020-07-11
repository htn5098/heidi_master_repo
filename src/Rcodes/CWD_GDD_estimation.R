# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
crop=inputs[2]
threshold=as.numeric(inputs[3])
threshold2=as.numeric(inputs[4])
gcm=as.character(inputs[5])
period=as.character(inputs[6])
cat('\n\n GDD estimation of', crop, 'for',c(gcm, period),' for threshold',
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
thresholdname = gsub('[.]','',as.character(threshold))
pldfile <- read.csv(paste0('./data/processed/GridMET_',gcm,'_',
                           period,'_pld_county_',
                           thresholdname,'.csv'),header=T)
if (period == 'historical') {
  startyear = 1950
} else {
  startyear = 2006
}
startDate <- as.Date(paste0(startyear,"-01-01"),'%Y-%m-%d')
# Input data
tmean.county <- fm.load(interimpath,'/interim_', gcm,'_',period,'_tmean')
time <- seq.Date(from=startDate,length.out = nrow(tmean),by="day")# using year as factor to split the county data into a list according to years later
county=sort(unique(names(tmean.couty)))

# ESTIMATING GDD
county.gdddaily <- ifelse(tmean.county < threshold,0,
                          ifelse(tmean.county>threshold2,threshold2-threshold,
                                 tmean.county-threshold))
## Estimating GDD for the fixed growing season length (planting date till 6 months later)
print("GDD for the fixed growing season length")
county.gddfixed <- foreach(i = 1:ncol(tmean.county),.combine=rbind,
                           .packages=c('lubridate')) %do% {
  # coding the T values into binary values:
  ls <- split(county.gdddaily[,i],f=year(time))
  years <- names(ls)
  cumm.gdd <- foreach(j = seq_along(ls),.combine=rbind) %do% {
    doy <- pldfile$PLD[pldfile$COUNTYNS==county[i] &
                         pldfile$Year==as.numeric(ls[j])]
    t = sum(ls[[j]][doy,(doy+170)]) # 170 is the calendar length of the growing season for corn
    cgdd <- data.frame(COUNTYNS = county[i], Period = period,
                       Year = years[j],GDD=t) 
  }
                           }
head(county.gddfixed[,1:10])
## Estimating growing season length for 2700 GDD hybrid
print("Length of growing season length for 2700 GDD")
county.gsl <- foreach(i = 1:ncol(county.data),.combine=rbind,
                           .packages=c('lubridate')) %do% {
  # coding the T values into binary values:
  ls <- split(county.gdddaily[,i],f=year(time))
  years <- names(ls)
  cumm.gdd <- foreach(j = seq_along(ls),.combine=rbind) %do% {
    doy <- pldfile$PLD[pldfile$COUNTYNS==names(county.data)[i] &
                         pldfile$Year==as.numeric(ls[j])]
    lastday <- max(which(cumsum(t = sum(ls[[j]][doy,
                                                length(ls[[j]])]) < 2700)))
    len=(lastday-doy+1)
    lgdd <- data.frame(COUNTYNS = county[i], Period = period,
               Year = years[j],GSL=len) 
  }
}
head(county.gsl[,1:10])
print("Finshed calculating seasonal GDD")
write.csv(county.gddfixed,
          paste0('./data/processed/GridMET_',gcm,'_',
                 period,'_gddfixed_county_',crop,'.csv'),row.names = F)
write.csv(county.gddfixed,
          paste0('./data/processed/GridMET_',gcm,'_',
                 period,'_gddfixed_county_',crop,'.csv'),row.names = F)
write.csv(county.gsl,
          paste0('./data/processed/GridMET_',gcm,'_',
                 period,'_gsl_county_',crop,'.csv'),row.names = F)
close(tmean)
stopCluster(cl)