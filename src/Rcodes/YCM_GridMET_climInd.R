# *** AGGREGATING DATA ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
varname=as.character(inputs[1])
fun=as.character(inputs[2])

cat('\n Creating Climate Indices for', varname, '\n')

# CHANGING LIBRARY PATH
.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

# CHANGING WORKING DIRECTORIES AND PATHS FOR INPUT AND INTERIM FILES
setwd('/storage/work/h/htn5098/DataAnalysis')
source('./src/Rcodes/CWD_function_package.R') # calling the functions customized for the job

# CALLING LIBRARIES
library(filematrix)
library(foreach)
library(doParallel)
library(parallel)
library(data.table)
library(lubridate)
library(dplyr)
library(ClimInd)

# REGISTERING WORKERS FOR PARALLEL PROCESSING
no_cores <- detectCores()
cl <- makeCluster(no_cores)
registerDoParallel(cl)
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers

# READING INPUT AND SUPPORTING DATA FILES
data = fread(paste0('./data/processed/GridMET_hist_',varname,'_county.csv'), header =T)
cat('\n Dimension of full data:',dim(data),'\n')
time <- seq.Date(from=as.Date('1979-01-01','%Y-%m-%d'),length.out = nrow(data),by="day")# using year as factor to split the county data into a list according to years later

# CREATING CLIMATE INDICES
opfilename=paste0('./data/processed/GridMET_hist_ind_county.csv')
if (file.exists(opfilename)) {
	print("OP file already exists")
} else {
	# Making a list 
	data_list <- lapply(data, function(x) {
	  names(x) <- as.character(format(time,'%m/%d/%Y'))
	  return(x)
	})
	print(length(data_list))
	print(head(data_list[[1]]))
	#clusterExport(cl,list('aggr_data','data','spfile')) #exporting data into clusters for parallel processing
	clim_ind <- do.call(cbind,lapply(data_list, fun, time.scale = 'year'))
	print(head(clim_ind[,1:10]))
  # county.data <- data.frame(county.data)
  # colnames(county.data) <- as.character(county)
  # print("Finished aggregating")
  # fwrite(county.data,opfilename,row.names = F)
}

stopCluster(cl)