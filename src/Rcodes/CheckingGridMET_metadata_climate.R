args = commandArgs(trailingOnly=TRUE)
link=args[1]
folder=args[2]

path= paste0("/storage/home/htn5098/work/DataAnalysis/data/raw/UW_clim/",folder)

.libPaths("/storage/home/htn5098/local_lib/R35")
.libPaths()

library(googledrive)
library(ncdf4)

setwd("/storage/home/htn5098/scratch/DataAnalysis/data/raw/gridMET_check")

files=list.files(full.names=T)
for (i in files) {
  nc = nc.open(i)
  var = names(nc$var)
  lat = ncatt_get(nc,vaird='lat')
  lon = ncatt_get(nc,varid='lon')
  varatt = ncatt_get(nc,varid=var)
  #sink("/storage/work/h/htn5098/DataAnalysis/data/log_files/GridMET_metadata.txt")
  print(i)
  print(var)
  print(varatt)
  print(lat)
  print(lon)
  #sink()
}




