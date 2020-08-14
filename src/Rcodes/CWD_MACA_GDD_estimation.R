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
    threshold,'-',threshold2,'oC\n')

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
tmean.county <- fm.load(paste0(interimpath,'/interim_', gcm,'_',period,'_tmean'))
dim(tmean.county)
time <- seq.Date(from=startDate,length.out = nrow(tmean.county),by="day")# using year as factor to split the county data into a list according to years later
county=colnames(tmean.county)

# ESTIMATING GDD
county.gdddaily <- ifelse(tmean.county < threshold,0,
                          ifelse(tmean.county>threshold2,threshold2-threshold,
                                 tmean.county-threshold))
## Estimating GDD for the fixed growing season length (planting date till 6 months later)
if (file.exists(paste0('./data/processed/GridMET_',gcm,'_',
           period,'_gddfixed_county_',crop,'.csv'))) {
  print("GDD for the fixed growing season length file exists")
} else {
  print("GDD for the fixed growing season length") #.packages=c('lubridate')
  county.gddfixed <- foreach(i = 1:ncol(county.gdddaily),.combine=rbind,
                             .packages=c('lubridate')) %dopar% {
                               # coding the T values into binary values:
                               # coding the T values into binary values:
                               ls <- split(county.gdddaily[,i],f=year(time))
                               years <- names(ls)
                               cgdd <- sapply(seq_along(ls),function(j) {
                                 doy <- pldfile$PLD[pldfile$COUNTYNS==county[i] &
                                                      pldfile$Year==as.numeric(years[j])]
                                 t = sum(ls[[j]][doy:(doy+170)]) # 170 is the calendar length of the growing season for corn
                               })
                               cumm.gdd <- data.frame(COUNTYNS = county[i], Period = period,
                                                      Year = years,GDD=cgdd)
                             }
  fwrite(county.gddfixed,
            paste0('./data/processed/GridMET_',gcm,'_',
                   period,'_gddfixed_county_',crop,'.csv'),row.names = F)
  print("Finshed calculating seasonal GDD")
}
  
## Estimating growing season length for 2700 GDD hybrid
if(file.exists(paste0('./data/processed/GridMET_',gcm,'_',
                      period,'_gsl_county_',crop,'.csv'))) {
  print("Length of growing season length for 2700 GDD file exists")
} else {
  print("Length of growing season length for 2700 GDD")
  county.gsl <- foreach(i = 1:ncol(county.gdddaily),.combine=rbind,
                        .packages=c('lubridate')) %dopar% {
                          # coding the T values into binary values:
                          ls <- split(county.gdddaily[,i],f=year(time))
                          years <- names(ls)
                          gdd2700 <- sapply(seq_along(ls),function(j) {
                            doy <- pldfile$PLD[pldfile$COUNTYNS==county[i] &
                                                 pldfile$Year==as.numeric(years[j])]
                            len <- sum(cumsum(ls[[j]][doy:length(ls[[j]])]) < 2700) + 1
                          })
                          len2700 <- data.frame(COUNTYNS = county[i], Period = period,
                                                Year = years,GSL=gdd2700)
                          }
  fwrite(county.gsl,
            paste0('./data/processed/GridMET_',gcm,'_',
                   period,'_gsl_county_',crop,'.csv'),row.names = F)
  print("Finshed calculating seasonal GDD")
}

stopCluster(cl)