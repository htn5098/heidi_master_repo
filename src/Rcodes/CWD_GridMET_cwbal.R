# *** ESTIMATING CLIMATIC WATER BALANCE ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])

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

# REGISTERING WORKERS FOR PARALLEL PROCESSING
no_cores <- detectCores()
cl <- makeCluster(no_cores)
registerDoParallel(cl)
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers

if (file.exists('./data/processed/GridMET_hist_cwb_grid_*.csv')) {
	print("CWB file already exists")
} else {
	# READING INPUT AND SUPPORTING DATA FILES
	spfile <- read.csv('./data/external/SDGridMET4km.txt',header=T) # files for COUNTYNS, grid cell and grid area weight 
	grids <- sort(unique(spfile$Grid)) # all unique grids
	pr = fm.load(paste0(interimpath,'/interim_gridmet_hist_pr'))[,grids] # choosing only number of grids in the study area
	pet = fm.load(paste0(interimpath,'/interim_gridmet_hist_pet'))[,grids]
	cat('\n Dimension of full pr data:',dim(pr),'\n')
	cat('\n Dimension of full pet data:',dim(pet),'\n')

	cwb <- pr - pet # estimating the climatic water balance
	cat('\n Dimension of full cwb data:',dim(cwb),'\n')
	time <- seq.Date(from=as.Date('1979-01-01','%Y-%m-%d'),length.out = nrow(cwb),
                 by="day") 
	
	colnames(cwb) <- as.character(grids)	
	cwb_space <- data.table(apply(cwb,2, mean))
	print(dim(cwb_space))
	cwb_time <- data.table(Year = year(time),
		Month = month(time),
		cwb)[,lapply(.SD,mean), by = c('Year','Month')]
		
	fwrite(cwb_time,'./data/processed/GridMET_hist_cwb_grid_time.csv')
	fwrite(cwb_space,'./data/processed/GridMET_hist_cwb_grid_space.csv')
	
	print("Finishing estimating cwb")
}

#stopCluster(cl)