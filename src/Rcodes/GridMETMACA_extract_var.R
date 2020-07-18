# *** EXTRACTING MACA DATA***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
lonS=as.numeric(inputs[1])
latS=as.numeric(inputs[2])
start=c(lonS,latS,1)
count=c(as.numeric(inputs[3:4]),-1)
rawpath=as.character(inputs[5])
interimpath=as.character(inputs[6])
gcm=inputs[7]
period=inputs[8]
var=inputs[9]
cat('\n\n Extracting ',c(var, period, gcm),'\n')

# CHANGING LIBRARY PATHS
.libPaths("/storage/home/htn5098/local_lib/R35") # local library for packages
setwd('/storage/work/h/htn5098/DataAnalysis')
source('./src/Rcodes/CWD_function_package.R') # Calling the function Rscript

# CALLING PACKAGES
library(foreach)
library(doParallel)
library(parallel)
library(ncdf4)
library(filematrix)

# REGISTERING CORES FOR PARALLEL PROCESSING
no_cores <- detectCores() 
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# EXTRACTING DATA FROM THE .NC FILES TO MATRIX FORM
outname <- paste0(interimpath,'/interim_', gcm,'_',period,'_',var)
if (file.exists(paste0(outname,'.bmat')) & file.exists(paste0(outname,'.desc.txt'))) {
  cat(outname, 'already exists\n')
} else {
  cat("\nStart extracting data\n")
  files=list.files(path=rawpath,pattern = paste0('.*',var,'.*',gcm,'.*',period), 
                   full.names = T) 
  invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
  #clusterExport(cl,list('ncarray2matrix','start','count')) #exporting data into clusters for parallel processing
  matrix.var=foreach(i = files,.combine = rbind) %do% {
                       #library(ncdf4)
                       filename=paste0(i)
                       nc=nc_open(filename)
                       varid=names(nc$var)
                       nc.var=ncvar_get(nc,varid=varid,start=start,count=count)
                       var=ncarray2matrix(nc.var)
                       # return(var)
                     }
  cat("\nDimensions of the file")
  dim(matrix.var)
}
# .packages = c('ncdf4')
# .export = c('ncarray2matrix','start','count')
output = fm.create.from.matrix(outname,matrix.var)
close(output)
print("Finished extracting data")

stopCluster(cl)