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
outname <- paste0('/gpfs/scratch/htn5098/DataAnalysis/data/processed/CWD_',source,'_',gcm,'_',period,'_',var,'_grid_monthly.csv')
if (file.exists(outname)) {
	cat('\Gridded monthly data file already exists\n')
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
	climvar <- fm.load(paste0(interimpath,'/CWD_',source,'_',gcm,'_',period,'_'var))  
	
	climvar.df <- data.table(Year = year(time),
                   Month = month(time),
                   climvar)

	climvar.monthly <- climvar.df[,(lapply(.SD,sum)), by = c('Year','Month')]
	
	fwrite(climvar.monthly,outname,row.names = F)
	
	head(climvar.monthly[,1:5])
	
	cat("\nEnd of aggregating grid to monthly level\n")
}

stopCluster(cl)