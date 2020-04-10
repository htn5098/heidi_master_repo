inputs=commandArgs(trailingOnly = T)
link=as.character(inputs[1])
period=as.character(inputs[2])
action=as.character(inputs[3])


# Author: Heidi Nguyen
# Downloading and processing metadata information of .nc file

.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

setwd('/storage/work/h/htn5098/DataAnalysis/')

library(ncdf4)
library("googledrive")
drive_auth(email = "haint2307@gmail.com") #inserting gmail here to access the drive
dataRaw=paste0("/storage/home/htn5098/scratch/DataAnalysis/data/raw/UW_clim/",period) #storing large raw files in scratch directory (no backup)

# Retrieving information on the drive file
linkGet = drive_get(link)
print(linkGet)
name=linkGet$name

# Downloading files from Google Drive
if(action=="download") {
  print("Start downloading and creating metadata file")
  drive_download(file=linkGet,path=paste0(dataRaw,'/',name),overwrite=F)
  nc = nc_open(paste0(dataRaw,'/',name))
  lat = range(ncvar_get(nc,varid='lat'))
  lon = range(ncvar_get(nc,varid='lon')) 
  time = range(ncvar_get(nc,varid='time'))
  varls <- names(nc$var)
  varls <- varls[!grepl(pattern='time',varls)]
  sink(paste0('./data/log_files/',name,'_meta.txt'))
  print(nc)
  sink()
  sink(paste0('./data/log_files/',name,'_meta_short.txt'),append=T)
  cat(paste('Filename:', name,'\n'))
  for (i in varls) {
      varatt=ncatt_get(nc,varid=i)
      cat(paste('Variable id:',i,'\n'))
      cat(paste('\tVariable std name:',varatt$standard_name,'\n'))
      cat(paste('\tVariable unit:',varatt$units,'\n'))
      cat(paste('\tLattitude range is:',round(lat[1],3),'to',round(lat[2],3),' Unit:',nc$dim[[2]]$units,'\n'))
      cat(paste('\tLongtitude range is:',round(lon[1],3),'to',round(lon[2],3),' Unit:',nc$dim[[1]]$units,'\n'))
      cat(paste('\tTime range is:',time[1],'to',time[2],' Unit: daily'))
      cat('\n') 
  }
  sink()
} else {
  print("Start creating metadata file")
  nc = nc_open(paste0(dataRaw,'/',name))
  lat = ncvar_get(nc,varid='lat')
  lon = ncvar_get(nc,varid='lon')
  time = range(ncvar_get(nc,varid='time'))
  varls <- names(nc$var)
  varls <- varls[!grepl(pattern='time',varls)]
  sink(paste0('./data/log_files/',name,'_meta.txt'))
  print(nc)
  sink()
  sink(paste0('./data/log_files/',name,'_meta_short.txt'),append=T)
  cat(paste('Filename:', name,'\n'))
  for (i in varls) {
      varatt=ncatt_get(nc,varid=i)
      cat(paste('Variable id:',i,'\n'))
      cat(paste('\tVariable std name:',varatt$standard_name,'\n'))
      cat(paste('\tVariable unit:',varatt$units,'\n'))
      cat(paste('\tLattitude range is:',round(lat[1],3),'to',round(lat[length(lat)],3),' Unit:',nc$dim[[2]]$units,'\n'))
      cat(paste('\tLongtitude range is:',round(lon[1],3),'to',round(lon[length(lon)],3),' Unit:',nc$dim[[1]]$units,'\n'))
      cat(paste('\tTime range is:',time[1],'to',time[2],' Unit: daily'))
      cat('\n') 
  }
  sink()
} 
# Creating variable inputs for processing data
print("Creating input files for processing")
print(period)
varfile <- data.frame(Filename = name,
                      Period = period,
                      Var=varls)
print(varfile)
write.csv(varfile,paste0('./data/external/',name,'_vars.csv'),row.names=F)
print("Complete!")