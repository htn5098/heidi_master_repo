args = commandArgs(trailingOnly=TRUE)
link=args[1]
folder=args[2]

path= paste0("/storage/home/htn5098/work/DataAnalysis/data/raw/UW_clim/",folder)

.libPaths("/storage/home/htn5098/local_lib/R35")
.libPaths()

library(googledrive)
library(ncdf4)

setwd("/storage/work/h/htn5098/DataAnalysis/data/raw/UW_clim/control")

data.meta=drive_get(link)
filename=data.meta$name
print(filename)
data.raw=drive_download(link,path=paste0(path,'/',filename),overwrite=T)
print(data.raw)




