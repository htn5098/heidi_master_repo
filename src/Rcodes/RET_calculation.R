inputs = commandArgs(trailingOnly=T)
gcm=as.character(inputs[1])
period=as.character(inputs[2])

print(paste0(gcm,'_',period))

.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

setwd('/storage/home/htn5098/work/DataAnalysis')
interim='/storage/home/htn5098/scratch/DataAnalysis/data/interim/' 

library(Evapotranspiration)
library(lubridate)
library(foreach)
library(doParallel)
library(parallel)

# Registering cores for parallel processing
no_cores <- detectCores() #24 cores per node - enough for parallel processing
print(no_cores)
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# Reading supporting files
print("Reading supporting files")
spfile <- read.csv('./data/external/SDElevation12km.csv',header=T) #grid points and elevation
gridpoints <- spfile$Grid
if (period=="historical") {
  time = seq.Date(from = as.Date("1979-01-01",'%Y-%m-%d'),
                to = as.Date("2016-12-31","%Y-%m-%d"),'day')
} else if (period=="control") {
  time = seq.Date(from = as.Date("1950-01-01",'%Y-%m-%d'),
                to = as.Date("2005-12-31","%Y-%m-%d"),'day')
} else {
  time = seq.Date(from = as.Date("2006-01-01",'%Y-%m-%d'),
                to = as.Date("2099-12-31","%Y-%m-%d"),'day')
}
J = as.numeric(format(time,'%j')) # turning date into julian days for calculation

# Reading climate data
print("Reading climate data")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
clusterExport(cl,list('spfile')) #expporting data into clusters for parallel processing
print("Loop for calculating RET")
ETo <- foreach(i = gridpoints,.combine = cbind) %dopar% {
  library(Evapotranspiration)
  library(lubridate)
  library(data.table)
  lat.grid <- spfile$Lat[spfile$Grid==i]
  z.grid <- spfile$Elev[spfile$Grid==i]
  grid = as.character(i)
  tx = fread(paste0(interim,'UW_',gcm,'_',period,'_tasmax_',i,'.csv'),header=F)
  tn = fread(paste0(interim,'UW_',gcm,'_',period,'_tasmin_',i,'.csv'),header=F)
  rhx = fread(paste0(interim,'UW_',gcm,'_',period,'_rh_max_',i,'.csv'),header=F)
  rhn = fread(paste0(interim,'UW_',gcm,'_',period,'_rh_min_',i,'.csv'),header=F)
  Rs = fread(paste0(interim,'UW_',gcm,'_',period,'_shortwave_',i,'.csv'),header=F)*0.0864 #converting from W/m2 to MJ/m2/day
  u10 = fread(paste0(interim,'UW_',gcm,'_',period,'_wind_speed_',i,'.csv'),header=F)
  # Transforming climate data into input file for Evapotranspiration package to read
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
  
  # Using PM function to calculate ETo
  ETo.est <- ET.PenmanMonteith(data = clim.inputs,
                                   constants = const,
                                   ts = 'daily',
                                   solar = 'data')
  ETo.daily <- ETo.est$ET.Daily
}
colnames(ETo) <- as.character(gridpoints)
head(ETo[,1:10]) 
write.csv(ETo,paste0('./data/processed/UW_',period,'_RET_grid_daily.csv'),row.names=F)
stopCluster(cl)
