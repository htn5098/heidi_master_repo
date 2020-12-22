# *** CALCULATING NET RADIATION FOR ETO***
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
outname1 <- paste0(interimpath,'/interim_',source,'_',gcm,'_',period,'_clearsky_Matrix')
outname2 <- paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_Rns_Matrix')
if (file.exists(paste0(outname1,'.bmat')) & file.exists(paste0(outname1,'.desc.txt')) &
	file.exists(paste0(outname2,'.bmat')) & file.exists(paste0(outname2,'.desc.txt'))) {
	cat('\nFiles already exist\n')
} else {
	cat("\nStart of extracting data\n")
	# url <- readLines('./data/external/MACAV2_OPENDAP_allvar_allgcm_allperiod.txt')

	spfile <- read.csv('./data/external/SERC_MACAV2_Elev.csv',header = T)
	grids <- sort(unique(spfile$Grid))
	elev <- spfile$Elev[sort(spfile$Grid%in%grids)] 
	lat <- spfile$Lat[sort(spfile$Grid%in%grids)]*pi/180 # converting to rad 
	
	# invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers
	# clusterExport(cl,list('ncarray2matrix','start','count','grids')) #exporting data into clusters for parallel processing
	
	if(period=='historical') {
		time <- seq.Date(as.Date("1950-01-01","%Y-%m-%d"),
						as.Date("2005-12-31","%Y-%m-%d"),
						'day')
	} else {
		time <- seq.Date(as.Date("2006-01-01","%Y-%m-%d"),
						as.Date("2099-12-31","%Y-%m-%d"),
						'day')
	}
	
	J = as.numeric(format(time,'%j')) # Julian day
	
	# input variables
	# tx <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmax_Matrix')) - 273.16
	# tn <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmin_Matrix')) - 273.16
	# ea <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_ea_Matrix'))
	Rs <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_rsds_Matrix'))*0.0864 #converting from W/m2 to MJ/m2/day
	head(Rs[,1])
	
	## calculating extraterrestrial radiation Ra [MJ/m2/day]
	gsc = 0.082 # solar constant [MJ/m2/day]
	dr = 1 + 0.033*cos(2*pi*J/365)
	head(dr)
	solar.dcln <- matrix(rep(0.409*sin(2*pi*J/365-1.39),length(grids)),ncol = length(grids)) # solar declination [rad]
	head(solar.dcln[,1])
	
	system.time({	
		ws <- t(acos(-tan(lat)*t(tan(solar.dcln)))) # matrix
	})
	head(ws[,1])

	a <- t(t(sin(solar.dcln))*sin(lat)) # matrix
	head(a[,1])
	b <- t(t(cos(solar.dcln))*cos(lat)) # matrix
	head(b[,1])
	
	system.time({
		Ra <- (24*60/pi)*gsc*dr*(ws*a+b*sin(ws))
	})
	head(Ra[,1])
	
	## calculating net shortwave radiation
	Rso <- t((0.75+2*10^-5*elev)*t(Ra)) # clear-sky solar radiation [MJ/m2/day]
	Rns = (1-0.23)*Rs # net shortwave radiation for hypothetical grass with albedo = 0.23
	head(Rso[,1])
	head(Rns[,1])
	
	## calcualting net longwave radiation
	system.time({
		clear.sky.ratio = Rs/Rso
	# Rnl <- 4.903e-09*((tx+273.16)^4+(tn+273.16)^4)/2*(0.34-0.14*sqrt(ea))*(1.35*clear.sky.ratio-0.35)
	})
	head(clear.sky.ratio[,1])
	
	## net radiation Rn [MJ/m2/day]
	# Rn = Rns - Rnl 
	
	system.time({
	output1 = fm.create.from.matrix(outname1,clear.sky.ratio)
	close(output1)
	})
	
	cat('\nDimesion of clear.sky.ratio:',dim(clear.sky.ratio),'\n')
	print(head(clear.sky.ratio[,1:5]))
	cat("\nEnd of extracting clear.sky.ratio\n")
	
	system.time({
	output2 = fm.create.from.matrix(outname2,Rns)
	close(output2)
	})
	
	cat('\nDimesion of Rns:',dim(Rns),'\n')
	print(head(Rns[,1:5]))
	cat("\nEnd of extracting Rns\n")
}

stopCluster(cl)