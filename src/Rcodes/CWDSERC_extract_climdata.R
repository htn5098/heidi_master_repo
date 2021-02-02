# *** EXTRACTING MACA DATA***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
gcm=as.character(inputs[2])
period=as.character(inputs[3])
var=as.character(inputs[4])
source='MACAV2'

cat('\n\n EXTRACTING DATA FOR',var, gcm, period, '\n\n')

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
outname <- paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_',var,'_Matrix')
if (file.exists(paste0(outname,'.bmat')) & file.exists(paste0(outname,'.desc.txt'))) {
  cat('\nFile already exists\n')
} else {
  cat("\nStart of extracting data\n")
  url <- readLines('./data/external/MACAV2_OPENDAP_allvar_allgcm_allperiod.txt')
  links <- grep(x = url,pattern = paste0('.*',var,'.*',gcm,'_.*',period), value = T) 
  # print(links)
  spfile <- read.csv('./data/external/SERC_MACAV2_Elev.csv',header = T)
  grids <- sort(unique(spfile$Grid))
  start=c(659,93,1) # lon, lat, time
  count=c(527,307,-1)
  invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
  clusterExport(cl,list('ncarray2matrix','start','count','grids')) #exporting data into clusters for parallel processing
  varMatrix <- foreach(i = links,.packages=c('ncdf4'),.combine = rbind) %dopar% {
                       nc=nc_open(i)
                       nc.var=ncvar_get(nc,varid=names(nc$var),start=start,count=count)
                       varData=ncarray2matrix(nc.var)
					   varMtr=varData[,grids]
                       colnames(varMtr) <- as.character(grids)
					   ind <- which(colSums(is.na(varMtr)) != 0)
					   varMtr[,ind] <- 0 # setting missing grid to value of 0
					   return(varMtr)
                     }
  cat("\nDimensions of the file",dim(varMatrix),'\n')
  print(head(varMatrix[,1:5]))
  output = fm.create.from.matrix(outname,varMatrix)
  close(output)
  cat("\nEnd of extracting data\n")
}

stopCluster(cl)