# *** CALCULATING VPD FOR ETO***
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
library(ncdf4)
library(filematrix)
library(purrr)
library(bigmemory)
library(lubridate)

# REGISTERING CORES FOR PARALLEL PROCESSING
no_cores <- detectCores() 
cl <- makeCluster(no_cores)
registerDoParallel(cl)
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers

# *** EXTRACTING MACA DATA***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
gcm=as.character(inputs[2])
period=as.character(inputs[3])
#var=as.character(inputs[4])
source='MACAV2'

cat('\n\n ESTIMATING VPD FOR',gcm, period, '\n\n')

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
#library(abind)

# REGISTERING CORES FOR PARALLEL PROCESSING
no_cores <- detectCores() 
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# EXTRACTING DATA FROM THE .NC FILES TO MATRIX FORM
outname1 <- paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_ea_Matrix')
outname2 <- paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_vpd_Matrix')
if (file.exists(paste0(outname1,'.bmat')) & file.exists(paste0(outname1,'.desc.txt')) &
	file.exists(paste0(outname2,'.bmat')) & file.exists(paste0(outname2,'.desc.txt'))) {
	cat('\nFiles already exist\n')
} else {
	cat("\nStart of extracting data\n")
	url <- readLines('./data/external/MACAV2_OPENDAP_allvar_allgcm_allperiod.txt')

	# spfile <- read.csv('./data/external/SERC_MACAV2_Elev.csv',header = T)
	# grids <- sort(unique(spfile$Grid))
	# invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
	# clusterExport(cl,list('ncarray2matrix','start','count','grids')) #exporting data into clusters for parallel processing
	
	tx <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmax_Matrix')) - 273.16
	tn <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmin_Matrix')) - 273.16
		
	SVPmax = sat.vp.fucn(tx) # saturation vapor pressure at Tmax [kPa]
	SVPmin = sat.vp.fucn(tn) # saturation vapor pressure at Tmin [kPa]
	
	
	rhx <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_rhsmax_Matrix'))
	rhn <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_rhsmin_Matrix'))
		
	es = (SVPmax + SVPmin)/2 # daily mean saturation vapor pressure [kPa]
	ea = (SVPmax*rhn/100 + SVPmin*rhx/100)/2 # daily mean actual vapor pressure [kPa]
	
	
	output1 = fm.create.from.matrix(outname1,ea)
	close(output1)
	
	cat('\nDimesion of ea:',dim(ea),'\n')
	print(head(ea[,1:5]))
	cat("\nEnd of extracting ea\n")
	
	vpd = es-ea
	
	output2 = fm.create.from.matrix(outname2,vpd)
	close(output2)
	
	cat('\nDimesion of vpd:',dim(vpd),'\n')
	print(head(vpd[,1:5]))
	cat("\nEnd of extracting vpd\n")
}

stopCluster(cl)