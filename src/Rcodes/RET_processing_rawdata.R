args = commandArgs(trailingOnly=T)
filename=as.character(args[1])
var=as.character(args[2])
period=as.character(args[3])

.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

library(ncdf4)
library(data.table)
library(foreach)
library(doParallel)
library(parallel)

# Registering cores for parallel processing
no_cores <- detectCores() #24 cores per node - enough for parallel processing
print(no_cores)
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# Reading the .nc file 
print("Reading nc file")
nc.file <- nc_open(filename) #

# Reading supporting files
print("Reading supporting files")
coord_se <- read.table('./data/SDGrid0125sort.txt', sep = ',', header = T) # File contains information about grid index
indx = sort(unique(coord_se$Grid)) # index numbers of grids in the study area

# Extracting data from array to matrix
print("Extracting data")
nc.var <- ncvar_get(nc.file,varid = var) # variable extracted in array format (lon,lat,day)
nc.att <- ncatt_get(nc.file,varid=var)
print(nc.att$unit)
dim <- dim(nc.var)
var.matrix <- aperm(nc.var, c(3,2,1)) # rearranging the dimensions of the array to (day,lat,lon)
dim(var.matrix) <- c(dim[3],dim[2]*dim[1]) # turning the array into a 2d matrix (day,grid)
var.matrix.sa <- var.matrix[,indx] # selecting only gridcells within the study area
colnames(var.matrix.sa) <- as.character(indx)
indx_NA <- which(colSums(is.na(var.matrix.sa)) != 0) # finding grids with NA's
var.matrix.sa[,indx_NA] <- 0 # eliminating no data grids
print(which(colSums(is.na(var.matrix.sa)) != 0))
print("Data extraction complete")


# Writing .csv file for each grid cells
print("Exporting into the workers")
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
clusterExport(cl,list('var.matrix.sa','period','var')) #list('var.matrix.sa') expporting data into clusters for parallel processing
print("Writing data files")
#setwd("./data/interim") #it is not setting working directory to a new path that resets the library paths, preventing the workers to load the package doParralel
foreach(i = 1:2) %dopar% { #ncol(var.matrix.sa)
  outfile=data.frame(var.matrix.sa[,i])
  colnames(outfile) <- NULL
  grid=colnames(var.matrix.sa)[i]
  outfilename=paste0('./data/interim/UW_',period,'_',var,'_',grid,'.csv')
  write.csv(outfile,outfilename,row.names=F,col.names=F)
}
print("Completed")
stopCluster(cl)
