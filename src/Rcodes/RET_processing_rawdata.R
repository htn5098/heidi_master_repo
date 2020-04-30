# *** PROCESSING UW CLIMATE DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

inputs = commandArgs(trailingOnly=T)
ncfile=as.character(inputs[1])
gcm=as.character(inputs[2])
period=as.character(inputs[3])
var=as.character(inputs[4])
timeLength=as.numeric(inputs[5])
varname=as.character(inputs[6])

# CHANGING LIBRARY PATH
.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

# CHANGING WORKING DIRECTORIES AND PATHS FOR INPUT AND INTERIME FILES
setwd('/storage/home/htn5098/work/DataAnalysis')
#inputpath='/storage/home/htn5098/scratch/DataAnalysis/data/raw/UW_clim/' # where .nc files are
interim='/storage/home/htn5098/scratch/DataAnalysis/data/interim/' #where to put .csv files for next step

# CALLING LIBRARIES
library(ncdf4)
library(data.table)
library(foreach)
library(doParallel)
library(parallel)

# REGISTERING WORKERS FOR PARALLEL PROCESSING
no_cores <- detectCores() #number of cores per node for working
print(no_cores)
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# READING INPUT AND SUPPORTING DATA FILES
print("Reading nc file")
print(ncfile)
nc.file <- nc_open(ncfile) # reading the downloaded .nc file
coord_se <- read.table('./data/external/SDGrid0125sort.txt', sep = ',', header = T) # file contains information about grid index
indx = sort(unique(coord_se$Grid)) # index numbers of grids in the study area

# PROCESSING CLIMATE DATA
## Extracting data from .nc file into 2-d matrix
print("Extracting data")
nc.var <- ncvar_get(nc.file,varid=var) # variable extracted in array format (lon,lat,day)
dim <- dim(nc.var)
var.matrix <- aperm(nc.var, c(3,2,1)) # rearranging the dimensions of the array to (day,lat,lon)
dim(var.matrix) <- c(dim[3],dim[2]*dim[1]) # turning the array into a 2d matrix (day,grid)
var.matrix.sa <- var.matrix[,indx] # selecting only gridcells within the study area
colnames(var.matrix.sa) <- as.character(indx)
indx_NA <- which(colSums(is.na(var.matrix.sa)) != 0) # finding grids with NA's
var.matrix.sa[,indx_NA] <- 0 # eliminating no data grids
if(nrow(var.matrix.sa)!=timeLength) {
  print(paste("Length of data is not",timeLength))
  var.matrix.sa <- var.matrix.sa[1:timeLength,]
} else {
  print(paste("Length of data is ",timeLength))
}
head(var.matrix.sa[,1:10])
print("Data extraction complete")
## Summarizing missing data for later references
sink(paste0('./data/log_files/UW_',gcm,'_',period,'_var_missing.txt'),append=T)
cat('Variable:',var,'\n')
cat('Number of missing data:',length(indx_NA),'\n')
cat('Grids:\n')
cat(paste0(names(indx_NA),collapse=','))
cat('\n')
sink()
## Writing .csv file for each grid cells
print("Exporting into the workers")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
clusterExport(cl,list('var.matrix.sa','period','var','varname','gcm')) #list('var.matrix.sa') expporting data into clusters for parallel processing
print("Writing data files")
foreach(i = 1:ncol(var.matrix.sa)) %dopar% { #ncol(var.matrix.sa)
  outfile=data.frame(var.matrix.sa[,i])
  colnames(outfile) <- NULL
  grid=colnames(var.matrix.sa)[i]
  outfilename=paste0(interim,'UW_',gcm,'_',period,'_',varname,'_',grid,'.csv')
  write.csv(outfile,outfilename,row.names=F,col.names=F)
}
print("Completed")
stopCluster(cl)
