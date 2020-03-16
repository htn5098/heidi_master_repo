.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

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
spfile <- read.csv('./data/SDGridElevation.csv',header=T) #grid points and elevation
gridpoints <- spfile$Grid
time = seq.Date(from = as.Date("1979-01-01",'%Y-%m-%d'),
                to = as.Date("2016-12-31","%Y-%m-%d"),'day')
J = as.numeric(format(time,'%j')) # turning date into julian days for calculation

# Reading climate data
print("Reading climate data")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
clusterExport(cl,list('spfile')) #list('var.matrix.sa') expporting data into clusters for parallel processing
print("Loop for calculating RET")
ETo <- foreach(i = gridpoints,.combine = cbind) %do% {
  lat.grid <- spfile$Lat[spfile$Grid==i]
  z.grid <- spfile$Elev[spfile$Grid==i]
  grid = as.character(i)
  tx = read.csv(paste0('./data/interim/UW_historical_tasmax_',i,'.csv'),header=F)
  tn = read.csv(paste0('./data/interim/UW_historical_tasmin_',i,'.csv'),header=F)
  rhx = read.csv(paste0('./data/interim/UW_historical_rh_max_',i,'.csv'),header=F)
  rhn = read.csv(paste0('./data/interim/UW_historical_rh_min_',i,'.csv'),header=F)
  Rs = read.csv(paste0('./data/interim/UW_historical_shortwave_',i,'.csv'),header=F)
  head(Rs)
  u10 = read.csv(paste0('./data/interim/UW_historical_wind_speed_',i,'.csv'),header=F)
  # Transforming climate data into input file for Evapotranspiration package to read
  #length(year(time))
  #head(year(time))
  #length(month(time))
  #head(month(time))
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
head(ETo) 
#head(ETo.daily)
#head(ETo.monthly)
stopCluster(cl)
