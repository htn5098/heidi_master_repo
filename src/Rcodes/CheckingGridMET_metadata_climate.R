.libPaths("/storage/home/htn5098/local_lib/R35")
.libPaths()

library(ncdf4)

setwd("/storage/home/htn5098/scratch/DataAnalysis/data/raw/gridMET_check")

files=list.files(full.names=T)#
sink("/storage/work/h/htn5098/DataAnalysis/data/log_files/GridMET_metadata.txt",append=T)
for (i in files) { 
  nc = nc_open(i)
  varatt = ncatt_get(nc,varid=names(nc$var))
  lat = ncvar_get(nc,varid='lat')
  lon = ncvar_get(nc,varid='lon') 
  cat(paste('Filename:', i,'\n'))
  cat(paste('\tVariable id:',names(nc$var),'\n'))
  cat(paste('\tVariable std name:',varatt$standard_name,'\n'))
  cat(paste('\tVariable unit:',varatt$units,'\n'))
  cat(paste('\tLattitude range is:',round(lat[1],3),'to',round(lat[length(lat)],3),' Unit:',nc$dim[[2]]$units,'\n'))
  cat(paste('\tLongtitude range is:',round(lon[1],3),'to',round(lon[length(lon)],3),' Unit:',nc$dim[[1]]$units,'\n'))
  cat('\n') 
}
sink()



