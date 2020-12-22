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

# CALCULATING REFERENCE EVAPOTRANSPIRATION USING FAO PENMANN-MONTEITH EQUATION
outname <- paste0(interimpath,'/CWD_',source,'_',gcm,'_',period,'_eto')
if (file.exists(paste0(outname,'.bmat')) & file.exists(paste0(outname,'.desc.txt'))) {
	cat('\nETo already exists\n')
} else {
	cat("\nStart of calculating ETO \n")
	spfile <- read.csv('./data/external/SERC_MACAV2_Elev.csv',header = T)
	grids <- sort(unique(spfile$Grid))
	elev <- spfile$Elev[sort(spfile$Grid%in%grids)]
	lat <- spfile$Lat[sort(spfile$Grid%in%grids)]*pi/180 # converting to rad 
	
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
	
	# clusterExport(cl,list('grids')) #exporting data into clusters for parallel processing
	
	slope.svp <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_slopesvp_Matrix')) # unit: kPa/oC
	
	# Constant values
	Cn = 900 # unit: K mm s3Mg−1d−1
	Cd = 0.34 # unit: s m-1
	
	# Atmospheric data:
	atm.pressr = 101.3*((293-0.0065*elev)/293)^5.26 #atmostpheric pressure [kPa]
	head(atm.pressr)
	latent.heat = 2.45 # latent heat of vaporization [MJ/kg]
	psycho.const = 0.665*10^-3*atm.pressr
	head(psycho.const)
	length(psycho.const)
	
	# Temperature
	tx <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmax_Matrix')) - 273.16 # converting to C
	tn <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmin_Matrix')) - 273.16 
	tmean = (tx+tn)/2
	slope.svp = 4098*(sat.vp.fucn(tmean))/(tmean+237.3)^2
	
	cat('\nLoaded slope.svp\n')
	
	# Windpseed:
	uas <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_uas_Matrix')) # unit: m/s
	head(uas[,1])
	vas <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_vas_Matrix')) # unit: m/s
	#rs <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_rsds_Matrix'))*0.0864 #converting from W/m2 to MJ/m2/day
	u2 <- sqrt(uas^2 + vas^2)*4.87/(log(67.8*10-5.42)) # windspeed at 10m, converted to 2m
	rm(uas,vas)
	
	cat('\nLoaded u2\n')
	
	# Vapor pressure deficit
	vpd <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_vpd_Matrix'))
		
	cat('\nLoaded vpd\n')
	
	# Radiation
	G = 0 # daily soil heat flux
	ea <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_ea_Matrix'))
	clear.sky.ratio = fm.load(paste0(interimpath,'/interim_',source,'_',gcm,'_',period,'_clearsky_Matrix'))
	Rns = fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_Rns_Matrix'))
		
	Rnl <- 4.903e-09*((tx+273.16)^4+(tn+273.16)^4)/2*(0.34-0.14*sqrt(ea))*(1.35*clear.sky.ratio-0.35)
	Rn = Rns - Rnl  
		
	cat('\nRn calculated \n')
	
	# ETO CALCULATION
	g1 <- t(0.408*slope.svp*(Rn - G))
	g2 <- t(u2*vpd)
	g3 <- t(tmean+273)
	g4 <- t(slope.svp)
	g5 <- t(u2)
	ETo <- t((g1 + (psycho.const*Cn*g2/g3))/(g4 + psycho.const*(1+Cd*g5)))
	
	#ETo = (0.408*slope.svp*(Rn - G)+psycho.const*Cn/(tmean+273)*u2*vpd)/(slope.svp+psycho.const*(1+Cd*u2))
			
	output = fm.create.from.matrix(outname,ETo)
	close(output)
		
	cat('\nDimesion of ETo:',dim(ETo),'\n')
	print(head(ETo[,1:5]))
	cat("\nEnd of calculating ETo\n")
}

stopCluster(cl)