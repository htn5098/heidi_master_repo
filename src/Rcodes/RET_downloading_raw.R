inputs=commandArgs(trailingOnly = T)
link=inputs[1]


.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

library("googledrive")
drive_auth(email = "haint2307@gmail.com") #inserting gmail here to access the drive
dataRaw="/storage/home/htn5098/scratch/DataAnalysis/data/raw" #storing large raw files in scratch directory (no backup)

# Retrieving information on the drive file
linkGet = drive_get(link)
print(linkGet)
name=linkGet$name

# Downloading files from Google Drive
print("Start downloading")
drive_download(file=linkGet,path=paste0(dataRaw,'/',name),overwrite=F)

print("Download finished")
