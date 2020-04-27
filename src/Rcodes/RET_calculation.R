# *** CALCULATING REFERENCE EVAPOTRANSPIRATION FROM UW CLIMATE DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu
 
inputs = commandArgs(trailingOnly=T)
gcm=as.character(inputs[1])
period=as.character(inputs[2])
timeLength=as.numeric(inputs[3])

# CHANGING LIBRARY PATH
.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

# CHANGING WORKING DIRECTORIES AND PATHS FOR INPUT AND INTERIM FILES
setwd('/storage/home/htn5098/work/DataAnalysis')
interim='/storage/home/htn5098/scratch/DataAnalysis/data/interim/'

# CALLING LIBRARIES
library(Evapotranspiration)
library(lubridate)
library(foreach)
library(doParallel)
library(parallel)

# REGISTERING WORKERS FOR PARALLEL PROCESSING
no_cores <- detectCores() #24 cores per node - enough for parallel processing
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# READING INPUT AND SUPPORTING DATA FILES
print("Reading supporting files")
spfile <- read.csv('./data/external/SDElevation12km.csv',header=T) #grid points and elevation
gridpoints <- spfile$Grid
if (period=="historical") {
  startDate <- as.Date("1979-01-01",'%Y-%m-%d')
} else if (period=="control") {
  startDate <- as.Date("1950-01-01",'%Y-%m-%d')
} else {
  startDate <- as.Date("2006-01-01",'%Y-%m-%d')
}
time = seq.Date(from = startDate,length.out = timeLength, by='day')
J = as.numeric(format(time,'%j')) # turning date into julian days for calculation

# CALCULATING REFERENCE EVAPOTRANSPIRATION - PENMANN-MONTEITH
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
clusterExport(cl,list('spfile','var','period','gcm')) #expporting data into clusters for parallel processing
print("Loop for calculating RET")
ETo <- foreach(i = gridpoints,.combine = cbind) %dopar% { #gridpoints
 library(Evapotranspiration)
 library(lubridate)
 library(data.table)
 lat.grid <- spfile$Lat[spfile$Grid==i]
 z.grid <- spfile$Elev[spfile$Grid==i]
 grid = as.character(i)
 tx = fread(paste0(interim,'UW_',gcm,'_',period,'_tx_',i,'.csv'),header=F)
 tn = fread(paste0(interim,'UW_',gcm,'_',period,'_tn_',i,'.csv'),header=F)
 rhx = fread(paste0(interim,'UW_',gcm,'_',period,'_rhx_',i,'.csv'),header=F)
 rhn = fread(paste0(interim,'UW_',gcm,'_',period,'_rhn_',i,'.csv'),header=F)
 u10 = fread(paste0(interim,'UW_',gcm,'_',period,'_ws_',i,'.csv'),header=F)
 Rs = fread(paste0(interim,'UW_',gcm,'_',period,'_rs_',i,'.csv'),header=F)*0.0864 #converting from W/m2 to MJ/m2/day
 ## Transforming climate data into input file for Evapotranspiration package to read
 data <- data.frame(
   Station = grid,
   Year = year(time),
   Month = month(time),
   Day = day(time),
   Tmax = unlist(tx),
   Tmin = unlist(tn),
   RHmax = unlist(rhx),
   RHmin = unlist(rhn),
   Rs = unlist(Rs),
   uz = unlist(u10)
 )
 head(data)
 const <- list(
   lat_rad = lat.grid*pi/180,
   Elev = z.grid,
   lambda = 2.45,
   Gsc = 0.082,
   z = 10,
   sigma = 4.903e-09,
   G = 0
 )
 clim.inputs <- ReadInputs(varnames = c('Tmax','Tmin','RHmax','RHmin','Rs','uz'),
                      climatedata = data,
                      constants = const, stopmissing = c(10,10,5))
 ## Using PM function to calculate ETo
 ETo.est <- ET.PenmanMonteith(data = clim.inputs,
                                  constants = const,
                                  ts = 'daily',
                                  solar = 'data')
 ETo.daily <- ETo.est$ET.Daily
}
colnames(ETo) <- as.character(gridpoints)
head(ETo)
write.csv(ETo,paste0('./data/processed/UW_',gcm,'_',period,'_RET_grid_daily.csv'),row.names=F)
print("Complete!")
stopCluster(cl)
