library(ncdf4)
setwd("C:\\01.PSU\\02.DataAnalysis\\src\\data")
ncold <- nc_open("../../data/raw/wind_SERC_8th.1979_2016.nc")
dim <- ncold$dim
var.att <- ncatt_get(ncold,'wind_speed')
var.val <- ncvar_get(ncold,'wind_speed')
# Redefining dimension
lon <- ncdim_def(name=dim$lon$name,
                     units=dim$lon$units,
                     vals=dim$lon$vals,
                     unlim=T,
                     create_dimvar = T,
                     longname = 'longtitude')
lat <- ncdim_def(name=dim$lat$name,
                     units=dim$lat$units,
                     vals=dim$lat$vals,
                     unlim=T,
                     create_dimvar = T,
                     longname = 'lattitude')
time <- ncdim_def(name=dim$day$name,
                  units=dim$day$units,
                  vals=dim$day$vals,
                  unlim=T,
                  create_dimvar = T,
                  longname = 'time')
var.redef <- ncvar_def(name='wind',
                    unit= var.att$units,
                    dim=list(lon,lat,time),
                    longname='wind speed at 10m',
                    prec='float')

ncnew <- nc_create('testing01.nc',vars=var.redef)
ncvar_put(ncnew,varid='wind',vals=var.val)
nc <- nc_open('testing01.nc')
check<-ncvar_get(nc,var='wind')
identical(check,var.val)
