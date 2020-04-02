.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

setwd('/storage/work/h/htn5098/DataAnalysis/') # changing working directory
interim= '/storage/home/htn5098/scratch/DataAnalysis/data/interim/'

library(Evapotranspiration)
library(lubridate)
library(foreach)
library(doParallel)
library(parallel)

# Registering cores for parallel processing
no_cores <- detectCores() #24 cores per node - enough for parallel processing
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# Reading supporting files
print("Reading supporting files")
spfile <- read.csv('./data/external/SDElevation4km.csv',header=T) #grid points and elevation
gridpoints <- spfile$Grid
time = seq.Date(from = as.Date("1979-01-01",'%Y-%m-%d'),
                to = as.Date("1979-12-31","%Y-%m-%d"),'day')
J = as.numeric(format(time,'%j')) # turning date into julian days for calculation

# Reading climate data
print("Reading climate data")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
clusterExport(cl,list('spfile')) #list('var.matrix.sa') expporting data into clusters for parallel processing
print("Loop for calculating RET")
library(data.table)
ETo <- foreach(i = gridpoints,.combine=rbind) %dopar% {
  library(data.table)
  lat.grid <- spfile$Lat[spfile$Grid==i]
  z.grid <- spfile$Elev[spfile$Grid==i]
  grid = as.character(i)
  tx = fread(paste0(interim,'gridMET_tmmx.csv'),header=T,select=grid)
  tn = fread(paste0(interim,'gridMET_tmmn.csv'),header=T,select=grid)
  rhx = fread(paste0(interim,'gridMET_rmax.csv'),header=T,select=grid)
  rhn = fread(paste0(interim,'gridMET_rmin.csv'),header=T,select=grid)
  Rs = fread(paste0(interim,'gridMET_srad.csv'),header=T,select=grid)*0.0864 #converting from W/m2 to MJ/m2/day
  u10 = fread(paste0(interim,'gridMET_vs.csv'),header=T,select=grid)
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
head(ETo[,1:10]) 
stopCluster(cl)
