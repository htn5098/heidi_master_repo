inputs=commandArgs(trailingOnly = T)
link=as.character(inputs[1])
folder=as.character(inputs[2])
action=as.character(inputs[3])
# Author: Heidi Nguyen
# Downloading and processing metadata information of .nc file

.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

library(ncdf4)

library("googledrive")
drive_auth(email = "haint2307@gmail.com") #inserting gmail here to access the drive
dataRaw=paste0("/storage/home/htn5098/scratch/DataAnalysis/data/raw/UW_clim/",folder) #storing large raw files in scratch directory (no backup)

# Retrieving information on the drive file
linkGet = drive_get(link)
print(linkGet)
name=linkGet$name

nc = nc_open(paste0(dataRaw,'/',name))
varls <- names(nc$var)
varls <- varls[-grepl(pattern='time',varls)]
print(varls)

# Downloading files from Google Drive
#if(action=="download") {
#  print("Start downloading and creating metadata file")
#  drive_download(file=linkGet,path=paste0(dataRaw,'/',name),overwrite=F)
#  nc = nc_open(paste0(dataRaw,'/',name))
#  print(names(nc$var))
#  varatt = ncatt_get(nc,varid=names(nc$var))
#  #lat = ncvar_get(nc,varid='lat')
#  #lon = ncvar_get(nc,varid='lon') 
#  #cat(paste('Filename:', i,'\n'))
#  #cat(paste('\tVariable id:',names(nc$var),'\n'))
#  #cat(paste('\tVariable std name:',varatt$standard_name,'\n'))
#  #cat(paste('\tVariable unit:',varatt$units,'\n'))
#  #cat(paste('\tLattitude range is:',round(lat[1],3),'to',round(lat[length(lat)],3),' Unit:',nc$dim[[2]]$units,'\n'))
#  #cat(paste('\tLongtitude range is:',round(lon[1],3),'to',round(lon[length(lon)],3),' Unit:',nc$dim[[1]]$units,'\n'))
#  #cat('\n') 
#} else {
#  print("Start creating metadata file")
#  nc = nc_open(paste0(dataRaw,'/',name))
#  print(names(nc$var))
#}
print("Complete!")
