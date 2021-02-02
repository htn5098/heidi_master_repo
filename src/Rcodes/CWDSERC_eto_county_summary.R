# *** CALCULATING ETO USING MACAV2 DATA***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
gcm=as.character(inputs[2])
period=as.character(inputs[3])
#var=as.character(inputs[4])
source='MACAV2'

cat('\n\n CALCULATING ETO FOR', gcm, period, '\n\n')

# CHANGING LIBRARY PATHS
.libPaths("/storage/home/htn5098/local_lib/R35") # local library for packages
setwd('/storage/work/h/htn5098/DataAnalysis')
source('./src/Rcodes/CWD_function_package.R') # Calling the function Rscript

# CALLING PACKAGES
library(foreach)
library(doParallel)
library(parallel)
library(filematrix)
library(data.table)
library(lubridate)

# REGISTERING CORES FOR PARALLEL PROCESSING
no_cores <- detectCores() 
cl <- makeCluster(no_cores)
registerDoParallel(cl)
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers

# CALCULATING REFERENCE EVAPOTRANSPIRATION USING FAO PENMANN-MONTEITH EQUATION
outname <- paste0('./data/processed/CWD_',source,'_',gcm,'_',period,'_eto_county_monthly.csv')
# if (file.exists(outname)) {
	# cat('\nETo county monthly already exists\n')
# } else {
	spfile <- read.csv('./data/external/SERC_MACAV2_Elev.csv',header = T)
	county <- sort(unique(spfile$COUNTYNS))
	cat("\nStart of aggregating monthly ETO to county\n")
		
	data <- fread(paste0('./data/processed/CWD_',source,'_',gcm,'_',period,'_eto_grid_monthly.csv'),header = T)
	# data$Year <- NULL
	# data$Month <- NULL
	print(head(data[,1:5]))
	
	# county.data <- foreach(i = county, .combine = cbind) %do% { 
		# d <- aggr_data(gridpoint=spfile,county=i,data=data)
		# return(d)
	# }
	# county.data <- data.frame(county.data)
	# colnames(county.data) <- as.character(county)
	
	# print(head(county.data[,1:5]))
	
	# fwrite(county.data,outname,row.names = F)
	
	cat("\nEnd of aggregating ETo grid to monthly level\n")
#}

stopCluster(cl)