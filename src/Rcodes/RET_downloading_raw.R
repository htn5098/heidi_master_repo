# *** DOWNLOADING UW CLIMATE DATA FROM GOOGLE DRIVE ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

inputs=commandArgs(trailingOnly = T)
link=as.character(inputs[1])
gcm=as.character(inputs[2])
period=as.character(inputs[3])
filename=paste0('UW_',gcm,'_',period) # this is the name of the .nc file to be stored in the data
print(filename)

# CHANGING LIBRARY PATH (because library paths for users at ASCI is not the same as root)
.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

# PATHS FOR WORKING DIRECTORY AND STORING DATA
setwd('/storage/work/h/htn5098/DataAnalysis/')
dataRaw="/storage/home/htn5098/scratch/DataAnalysis/data/raw/UW_clim/" #storing large raw files in scratch directory (no backup)
interim="/storage/home/htn5098/scratch/DataAnalysis/data/raw/interim/" #storing interim files in scratch directory (no backup) to delete later

# CALLING OUT LIBRARIES 
library(ncdf4)
library(googledrive)
drive_auth(email = "haint2307@gmail.com") #inserting gmail here to access the drive

# DOWNLOADING .NC FILES FROM GOOGLE DRIVE
## Retrieving information on the drive file
linkGet = drive_get(link)
print(linkGet)
drivename=linkGet$name # this is the original name on drive (for checking)

## Downloading files from Google Drive
if(!file.exists(paste0(dataRaw,filename,'.nc'))) { # checking whether file exists, if not start downloading
  print("File doesn't exist - start downloading")
  drive_download(file=linkGet,path=paste0(dataRaw,filename,'.nc'))
}

print("Reading .nc file")
nc = nc_open(paste0(dataRaw,filename,'.nc')) # reading the nc file
varls <- names(nc$var)
lat = ncvar_get(nc,varid='lat')
lon = ncvar_get(nc,varid='lon')
time = ncvar_get(nc,varid='day')
if(!any(grepl(pattern='time',names(nc$var)))) { # this is to eliminate the time variable in the variable list of the .nc file
  varls <- names(nc$var)
  
} else {
  varls <- names(nc$var)[-grep(pattern='time',names(nc$var))]
}
print("Writing metadat file")
sink(paste0('./data/log_files/',filename,'_meta.txt'))
cat(paste('Drive name:',drivename,'\n'))
cat(paste('Name on file:',filename,'.nc','\n'))
for (i in varls) {
    varatt=ncatt_get(nc,varid=i)
    cat(paste('Variable id:',i,'\n'))
    cat(paste('\tVariable std name:',varatt$standard_name,'\n'))
    cat(paste('\tVariable unit:',varatt$units,'\n'))
    cat(paste('\tLattitude range is:',round(lat[1],3),'to',round(lat[length(lat)],3),' Unit:',nc$dim[[2]]$units,'\n'))
    cat(paste('\tLongtitude range is:',round(lon[1],3),'to',round(lon[length(lon)],3),' Unit:',nc$dim[[3]]$units,'\n'))
    cat(paste('\tTime range is:',time[1],'to',time[length(time)],' - Length:',length(time),'Unit: daily'))
    cat('\n') 
}
cat('\n')
cat('Metadata from .nc file:')
print(nc)
sink()

# Creating variable inputs for processing data
print("Creating variable data file")
varfile <- data.frame(Filename = paste0(dataRaw,filename,'.nc'),
                      GCM = gcm,
                      Period = period,
                      Var=varls,
                      TimeLength=length(time))
print(paste0('./data/external/',filename,'_var.txt'))
write.txt(varfile,paste0('./data/external/',filename,'_var.txt'),row.names=F)
print("Complete!")