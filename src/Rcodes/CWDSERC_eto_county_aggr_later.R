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
outname <- paste0('./data/processed/CWD_',source,'_',gcm,'_',period,'_eto_county.csv')
if (file.exists(outname)) {
	cat('\nETo grid monthly already exists\n')
} else {
	cat("\nStart of calculating ETO \n")
	if(period=='historical') {
		time <- seq.Date(as.Date("1950-01-01","%Y-%m-%d"),
						as.Date("2005-12-31","%Y-%m-%d"),
						'day')
	} else {
		time <- seq.Date(as.Date("2006-01-01","%Y-%m-%d"),
						as.Date("2099-12-31","%Y-%m-%d"),
						'day')
	}
	
	# Temperature
	eto <- fm.load(paste0(interimpath,'/CWD_',source,'_',gcm,'_',period,'_eto'))  
	
	eto.df <- data.table(Year = year(time),
                   Month = month(time),
                   eto)

	eto.monthly <- eto.df[,(lapply(.SD,sum)), by = c('Year','Month')]
	
	fwrite(eto.monthly,outname,row.names = F)
	
	head(eto.monthly[,1:5])
	
	cat("\nEnd of aggregating ETo grid to monthly level\n")
}

stopCluster(cl)