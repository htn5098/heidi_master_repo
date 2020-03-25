setwd('C:\\01.PSU\\02.DataAnalysis\\data\\raw\\abatz_met')
library(ncdf4)
library(dplyr)
library(Evapotranspiration)

files <- list.files()

clim.ls <- list()
gridret <- read.table("C:\\01.PSU\\02.DataAnalysis\\data\\external\\ret_indx.txt", sep = ',',
                      header = T)[,c('Grid','COUNTYNS')]

for (i in 1:length(files)) {
  nc_file <- nc_open(files[i])
  var <- names(nc_file$var)
  ret_se <- ncvar_get(nc_file,var,start = c(795,210,1), count = c(391,266,-1))
  dim <- dim(ret_se)
  ret_se_matrix <- aperm(ret_se, c(3,2,1))
  dim(ret_se_matrix) <- c(dim[3],dim[2]*dim[1])
  ret_se_matrix[1:20,1:2]
  dim(ret_se_matrix)
  ret_se_sel <- ret_se_matrix[,gridret$Grid]
  grid.choose <- ret_se_sel[,46963]
  clim.ls[[i]] <- grid.choose
  names(clim.ls)[i] <- var
}

clim.df <- data.frame(do.call(cbind,clim.ls))

eto.abatz.test <- clim.df[,c(6,5,2,3,8,4)]
colnames(eto.abatz.test) <- c('Tmax','Tmin','RHmax','RHmin','Rs','uz')
eto.abatz.test[,1:2] <- eto.abatz.test[,1:2] - 273
eto.abatz.test[,6] <- eto.abatz.test[,6]*0.0864

time.abatz <- seq.Date(as.Date('1979-01-01','%Y-%m-%d'),
                 as.Date('1979-12-31','%Y-%m-%d'),'days')

data("climatedata")
data("constants")

data.abatz <- data.frame(
  Station = 46963,
  Year = year(time.abatz),
  Month = month(time.abatz),
  Day = day(time.abatz),
  eto.abatz.test
)

inputs.abatz <- ReadInputs(varnames = c('Tmax','Tmin','RHmax','RHmin','Rs','uz'),
                           climatedata = data.abatz,
                           constants = const.abatz, stopmissing = c(10,10,5))

const.abatz <- list(lat_rad = (34.608337)*pi/180,
                    Elev = 656.5381,
                    lambda = constants$lambda,
                    Gsc = constants$Gsc,
                    z = 10,
                    sigma = constants$sigma,
                    G = 0
                    )

ETo.package.abatz <- ET.PenmanMonteith(data = inputs.abatz,
                                       constants = const.abatz,
                                       solar = 'data')
ETo.p.abatz.output <- ETo.package.abatz$ET.Daily

head(ETo.p.abatz.output)
head(ETo.abatz.grid[,'46963'])


# Check vpd calculations:
es.abatz <- (sat.vp.fucn(eto.abatz.test$Tmax) + sat.vp.fucn(eto.abatz.test$Tmin))/2
ea.abatz <- (sat.vp.fucn(eto.abatz.test$Tmax)*eto.abatz.test$RHmin/100+
               sat.vp.fucn(eto.abatz.test$Tmin)*eto.abatz.test$RHmax/100)/2
vpd.test <- es.abatz - ea.abatz
head(vpd.test)
head(clim.df$mean_vapor_pressure_deficit)

hist(vpd.test - clim.df$mean_vapor_pressure_deficit)
