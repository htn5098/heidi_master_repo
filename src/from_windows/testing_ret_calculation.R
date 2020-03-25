# TESTING OF SETTING UP ETO CALCULATION BY PENMAN-MONTEITH EQUATION
setwd('C:\\01.PSU\\02.DataAnalysis\\testing') #("..\testing") for reproducibility

library(dplyr)
library(data.table)
library(lubridate)
library(foreach)

# Input data
SDGridpoints <- fread("SDGrid0125sort.txt")
grid <- unique(SDGridpoints$Grid)
str(SDGridpoints)
SDCoordElevation <- fread("SDElevation.csv")
el <- SDCoordElevation %>%
  rename(Grid=PointID) %>%
  select(c("Grid","Lat","Elev")) %>%
  filter(Grid%in%grid) 
if (any(rowSums(is.na(el)) != 0)) {
  write.csv(el,"SDGridElevation.csv",row.names=F)
} else {
  print("NA values appear")
}

time = seq.Date(from = as.Date("1979-01-01",'%Y-%m-%d'),
                to = as.Date("2016-12-31","%Y-%m-%d"),'day')
J = as.numeric(format(time,'%j'))
# Choosing which county
county.choose <- SDGridpoints %>%
  group_by(COUNTYNS) %>%
  mutate(Area.County = sum(Area)) %>%
  filter(COUNTYNS == 1673011) %>%
  #  subset(Area.County == max(Area.County)) %>% #choosing county with largest area for testing
  mutate(Area.Fraction = Area/Area.County*100) 

# ETo.abatz.county <- fread('RET_county_daily.csv', header = T) 
# ETo.abatz.grid <- fread('RET_grid_daily.csv', header = T)

# Functions:
sat.vp.fucn = function(t) { # calculating saturation vapor pressure at ToC
  svp = 0.6108*exp(17.27*t/(t+237.3))
  return(svp)
}




# For multiple gridcells: -------------------------------------------------
grid <- county.choose %>%
  merge(SDCoordElevation, by.y = 'PointID', by.x = 'Grid') 
## Note: testing of elevation using the https://viewer.nationalmap.gov/basic/#productSearch show that several grids are actually on the sea level

ETo.grid <- foreach(i = grid$Grid,.combine = cbind) %do% {
  # Lattitude, longtitude and elevation
  gridtest <- grid[grid$Grid == i,]
  grid.name <- as.character(gridtest$Grid)
  lat.grid <- (gridtest$Lat)*pi/180 # latitude, converted to rad
  #lon.grid <- gridtest$Lon
  z.grid <- gridtest$Elev
  
  # Climate data:
  tx <- fread("SD_tasmax_grid.csv", header = T, select = as.character(gridtest$Grid)) # [oC] at 2m
  tn <- fread("SD_tasmin_grid.csv", header = T, select = as.character(gridtest$Grid)) # [oC] at 2m
  rhn <- fread("SD_rh_min_grid.csv",header = T, select = as.character(gridtest$Grid)) # [%] at 2m
  rhx <- fread("SD_rh_max_grid.csv",header = T, select = as.character(gridtest$Grid)) # [%] at 2m
  sw <- fread("SD_shortwave_grid.csv",header = T, select = as.character(gridtest$Grid)) # [W/m2]
  Rs <- sw*0.0864 # conversion from W2/m to MJ/m2/day
  u10 <- fread("SD_wind_speed_grid.csv",header = T, select = as.character(gridtest$Grid)) #wind speed [m/s] at 10m height
  #prec <-  fread("SD_prec_grid.csv", header = T, select = as.character(gridtest$Grid)) # [mm]
  
  # ETo calculation by FAO56:
  atm.pressr = 101.3*((293-0.0065*z.grid)/293)^5.26 #atmostpheric pressure [kPa]
  latent.heat = 2.45 # latent heat of vaporization [MJ/kg]
  psycho.const = 0.665*10^-3*atm.pressr
  tmean = (tx+tn)/2 # mean daily temperature [oC]
  SVPmax = sat.vp.fucn(tx) # saturation vapor pressure at Tmax [kPa]
  SVPmin = sat.vp.fucn(tn) # saturation vapor pressure at Tmin [kPa]
  es = (SVPmax + SVPmin)/2 # daily mean saturation vapor pressure [kPa]
  ea = (SVPmax*rhn/100 + SVPmin*rhx/100)/2 # daily mean actual vapor pressure [kPa]
  vpd = es-ea # daily vapor pressure deficit [kPa]
  slope.svp = 4098*(sat.vp.fucn(tmean))/(tmean+237.3)^2 # slope of es
  ## calculating extraterrestrial radiation Ra [MJ/m2/day]
  gsc = 0.082 # solar constant [MJ/m2/day]
  dr = 1 + 0.033*cos(2*pi*J/365)
  solar.dcln = 0.409*sin(2*pi*J/365-1.39) # solar declination [rad]
  ws = acos(-tan(lat.grid)*tan(solar.dcln))
  Ra = data.frame((24*60/pi)*gsc*dr*(ws*sin(lat.grid)*sin(solar.dcln)+cos(lat.grid)*cos(solar.dcln)*sin(ws)))
  colnames(Ra) = grid.name 
  ## calculating net shortwave radiation
  Rso = (0.75+2*10^-5*z.grid)*Ra # clear-sky solar radiation [MJ/m2/day]
  Rns = (1-0.23)*Rs # net shortwave radiation for hypothetical grass with albedo = 0.23
  ## Calcualting net longwave radiation
  clear.sky.ratio = as.matrix(Rs)/as.matrix(Rso)
  Rnl = 4.903e-09*((tx+273.16)^4+(tn+273.16)^4)/2*(0.34-0.14*sqrt(ea))*(1.35*clear.sky.ratio-0.35)
  ## net radiation Rn [MJ/m2/day]
  Rn = Rns - Rnl # so far only positive values
  ## Soil heat flux for daily timestep:
  G = 0
  u2 = u10*4.87/(log(67.8*10-5.42))
  
  ETo = (0.408*slope.svp*(Rn - G)+psycho.const*900/(tmean+273)*u2*vpd)/(slope.svp+psycho.const*(1+0.34*u2))
  #hist(ETo$`3373`)
}

clean <- names(which(colSums(is.na(ETo.grid)) != 0))
ETo.grid[,clean] <- 0

ETo.county <- as.matrix(ETo.grid) %*% (grid$Area.Fraction/100)
county.name <- unique(grid$COUNTYNS)

sum(ETo.abatz.county[,paste0('X',county.name),with=F])/38
sum(ETo.county)/38


# For one gridcell: -------------------------------------------------------

# Lattitude, longtitude and elevation
gridtest <- county.choose %>%
  merge(SDCoordElevation, by.y = 'PointID', by.x = 'Grid') %>%
  filter(Elev == max(Elev)) #choose the grid with highest elevation
grid <- as.character(gridtest$Grid)
lat.grid <- (gridtest$Lat)*pi/180 # latitude, converted to rad
lon.grid <- gridtest$Lon
z.grid <- gridtest$Elev

# Climate data:
tx <- fread("SD_tasmax_grid.csv", header = T, select = as.character(gridtest$Grid)) # [oC] at 2m
tn <- fread("SD_tasmin_grid.csv", header = T, select = as.character(gridtest$Grid)) # [oC] at 2m
rhn <- fread("SD_rh_min_grid.csv",header = T, select = as.character(gridtest$Grid)) # [%] at 2m
rhx <- fread("SD_rh_max_grid.csv",header = T, select = as.character(gridtest$Grid)) # [%] at 2m
sw <- fread("SD_shortwave_grid.csv",header = T, select = as.character(gridtest$Grid)) # [W/m2]
Rs <- sw#*0.0864 # conversion from W2/m to MJ/m2/day
u10 <- fread("SD_wind_speed_grid.csv",header = T, select = as.character(gridtest$Grid)) #wind speed [m/s] at 10m height

prec <-  fread("SD_prec_grid.csv", header = T, select = as.character(gridtest$Grid)) # [mm]

# ETo calculation by FAO56:
atm.pressr = 101.3*((293-0.0065*z.grid)/293)^5.26 #atmostpheric pressure [kPa]
latent.heat = 2.45 # latent heat of vaporization [MJ/kg]
psycho.const = 0.665*10^-3*atm.pressr
tmean = (tx+tn)/2 # mean daily temperature [oC]
SVPmax = sat.vp.fucn(tx) # saturation vapor pressure at Tmax [kPa]
SVPmin = sat.vp.fucn(tn) # saturation vapor pressure at Tmin [kPa]
es = (SVPmax + SVPmin)/2 # daily mean saturation vapor pressure [kPa]
ea = (SVPmax*rhn/100 + SVPmin*rhx/100)/2 # daily mean actual vapor pressure [kPa]
vpd = es-ea # daily vapor pressure deficit [kPa]
slope.svp = 4098*(sat.vp.fucn(tmean))/(tmean+237.3)^2 # slope of es
## calculating extraterrestrial radiation Ra [MJ/m2/day]
gsc = 0.082 # solar constant [MJ/m2/day]
dr = 1 + 0.033*cos(2*pi*J/365)
solar.dcln = 0.409*sin(2*pi*J/365-1.39) # solar declination [rad]
ws = acos(-tan(lat.grid)*tan(solar.dcln))
Ra = data.frame((24*60/pi)*gsc*dr*(ws*sin(lat.grid)*sin(solar.dcln)+cos(lat.grid)*cos(solar.dcln)*sin(ws)))
colnames(Ra) = grid
## calculating net shortwave radiation
Rso = (0.75+2*10^-5*z.grid)*Ra # clear-sky solar radiation [MJ/m2/day]
Rns = (1-0.23)*Rs # net shortwave radiation for hypothetical grass with albedo = 0.23
## Calcualting net longwave radiation
clear.sky.ratio = as.matrix(Rs)/as.matrix(Rso)
Rnl = 4.903e-09*((tx+273.16)^4+(tn+273.16)^4)/2*(0.34-0.14*sqrt(ea))*(1.35*clear.sky.ratio-0.35)
## net radiation Rn [MJ/m2/day]
Rn = Rns - Rnl # so far only positive values
## Soil heat flux for daily timestep:
G = 0
u2 = u10*4.87/(log(67.8*10-5.42)) # measured wind speed at 10 m/s

ETo = (0.408*slope.svp*(Rn - G)+psycho.const*900/(tmean+273)*u2*vpd)/(slope.svp+psycho.const*(1+0.34*u2))
ETo = unlist(ETo)
# hist(ETo)
sum(ETo)/38

grid24 <- c(46963:46965,47229:47231,47495:47497)
  
#c(26299:26301, 26565:26566, 26831:26833)

ETo.abatz.grid24 <- ETo.abatz.grid[,as.character(grid24),with =F] #
ETo.abatz.grid8 <- apply(ETo.abatz.grid24,1,mean)
hist(ETo.abatz.grid8)
sum(ETo.abatz.grid8)/38

diff <- ETo - ETo.abatz.grid8
hist(diff)    # my calculation mostly underestimate ETo compared to Abatzoglou 


# ETo by the Evaplotranspiration R package ---------------------------------
library('Evapotranspiration')
data("climatedata")
data("constants")

gridtest <- county.choose %>%
  merge(SDCoordElevation, by.y = 'PointID', by.x = 'Grid') %>%
  filter(Elev == max(Elev)) #choose the grid with highest elevation
grid <- as.character(gridtest$Grid)
lat.grid <- (gridtest$Lat)*pi/180 # latitude, converted to rad
lon.grid <- gridtest$Lon
z.grid <- gridtest$Elev

time <- seq.Date(as.Date('1979-01-01','%Y-%m-%d'),
                 as.Date('2016-12-31','%Y-%m-%d'),'days')

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
#  Precip = unlist(prec)
)

const <- list()
const$lat_rad <- (gridtest$Lat)*pi/180
const$Elev <- z.grid
const$lambda <- constants$lambda
const$Gsc <- constants$Gsc 
const$z <- 10
const$sigma <- constants$sigma
const$G <- 0

inputs <- ReadInputs(varnames = c('Tmax','Tmin','RHmax','RHmin','Rs','uz'),
                     climatedata = data,
                     constants = const, stopmissing = c(10,10,5))

ETo.package <- ET.PenmanMonteith(data = inputs,
                                 constants = const,
                                 ts = 'daily',
                                 solar = 'data')

ETo.p.output <- ETo.package$

head(ETo)
head(ETo.p.output)

hist(ETo - ETo.p.output)


