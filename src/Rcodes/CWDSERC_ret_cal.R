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
outname <- paste0('./data/processed/CWD_',source,'_',gcm,'_',period,'_eto.csv')
# if (file.exists(outname)) {
	# cat('\nFile already exists\n')
# } else {
	cat("\nStart of calculating ETO \n")
	
	spfile <- read.csv('./data/external/SERC_MACAV2_Elev.csv',header = T)
	grids <- sort(unique(spfile$Grid))
	
	cat("\nStart of calculating\n")
	
	spfile <- read.csv('./data/external/SERC_MACAV2_Elev.csv',header = T)
	grids <- sort(unique(spfile$Grid))
	lat.grids <- spfile$Lat*pi/180
	elev <- spfile$Elev
	time=seq.Date(as.Date('1950-01-01','%Y-%m-%d'), as.Date('2005-12-31','%Y-%m-%d'),'days')
	J = as.numeric(format(time,'%j'))
	
	# Atmospheric data:
	atm.pressr = 101.3*((293-0.0065*elev)/293)^5.26 #atmostpheric pressure [kPa]
	latent.heat = 2.45 # latent heat of vaporization [MJ/kg]
	psycho.const = 0.665*10^-3*atm.pressr
	gsc = 0.082 # solar constant [MJ/m2/day]
	dr = 1 + 0.033*cos(2*pi*J/365)
	solar.dcln = 0.409*sin(2*pi*J/365-1.39) # solar declination [rad]
	length(solar.dcln)
	
	head(psycho.const)
	length(psycho.const)
	
	
	ws <- matrix(nrow = length(time), ncol = length(grids))
	foreach(s = solar.dcln, i = seq_along(solar.dcln)) %:% 
		foreach(l = lat.grids, j = seq_along(lat.grids)) %dopar% {
		ws[i,j] = acos(-tan(l)*tan(s))
	}
	
	head(ws[,1:5])
	dim(ws)
	
	Ra <- matrix(nrow = length(time), ncol = length(grids))
	foreach(s = solar.dcln, i = seq_along(solar.dcln)) %:% 
		foreach(l = lat.grids, j = seq_along(lat.grids)) %dopar% {
		Ra[i,j] = (24*60/pi)*gsc*dr*(ws*sin(l)*sin(s)+cos(l)*cos(s)*sin(ws[i,j])
	}
	
  
	
	
	head(Ra[,1:5])
	dim(Ra)
	
	# clusterExport(cl,list('grids')) #exporting data into clusters for parallel processing
	# tx <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmax_Matrix')) - 273.15 # converting to C
	# tn <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_tasmin_Matrix')) - 273.15 
	# rhx <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_rhsmax_Matrix')) # unit: %
	# rhn <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_rhsmin_Matrix'))
	# uas <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_uas_Matrix')) # unit: m/s
	# vas <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_vas_Matrix')) # unit: m/s
	# rs <- fm.load(paste0(interimpath,'/interim_', source,'_',gcm,'_',period,'_rsds_Matrix'))*0.0864 #converting from W/m2 to MJ/m2/day
	# u10 <- sqrt(uas^2 + vas^2) # windspeed at 10m
	













	# system.time({
	# data_ls <- lapply(grids[1:30000], function(i) {
		# d <- map_dfc(list(tx,tn,rhx,rhn,u10,rs),~.x[,as.character(i)])
		# })
	# })
	
	# print(length(data_ls))
	# print(dim(data_ls[[1]]))
	# print(head(data_ls[[1]]))
	# rm(tx,tn,rhx,rhn,uas,vas,rs,u10)
	# gc()

	# # CALCULATE REFERENCE EVAPOTRANSPIRATION (PENMANN-MONTEITH)
	# time=seq.Date(as.Date('1950-01-01','%Y-%m-%d'), as.Date('2005-12-31','%Y-%m-%d'),'days')
	# years=year(time)
	# months=month(time)
	# days=day(time)
	# clusterExport(cl,c('years','months','days','grids','spfile'))
	# system.time({
	
	# # Transforming climate data into input file for Evapotranspiration package to read
	# eto <- foreach(k = data_ls[1:10000], i = grids[1:10000],.combine = cbind,
		# .packages = c('Evapotranspiration')) %dopar% {
		# grid = i
		# colnames(k) <- c('Tmax','Tmin','RHmax','RHmin','uz','Rs')
		# data <- data.frame(
			# Station = as.character(i),
			# Year = years,
			# Month = months,
			# Day = days,
			# k
			# )
		# lat.grid <- spfile$Lat[spfile$Grid==as.numeric(i)]
		# z.grid <- spfile$Elev[spfile$Grid==as.numeric(i)]
		# const <- list(
			# lat_rad = lat.grid*pi/180,
			# Elev = z.grid,
			# lambda = 2.45,
			# Gsc = 0.082,
			# z = 10,
			# sigma = 4.903e-09,
			# G = 0
			# )
		# clim.inputs <- Evapotranspiration::ReadInputs(varnames = c('Tmax','Tmin','RHmax','RHmin','Rs','uz'),
						  # climatedata = data,
						  # constants = const, stopmissing = c(99,99,99))
		# ## Using PM function to calculate ETo
		# ETo.est <- Evapotranspiration::ET.PenmanMonteith(data = clim.inputs,
										  # constants = const,
										  # ts = 'daily',
										  # solar = 'data')
		# ETo.daily <- ETo.est$ET.Daily
		# }
	# #ETo <- do.call(cbind,eto)
	# print(head(eto[,1:5]))
	# })
	# # ETo <- do.call(cbind,eto)
	# # })
	# # names(ETo) <- as.character(grids)
	# # head(ETo[,1:10])
	# # dim(ETo)

	# # outname2=paste0(interimpath,source,'_',gcm,'_',period,'_eto_',yearstart,'_',yearend)
	# # output = fm.create.from.matrix(outname2,ETo)
	# # close(output)
	# cat("\nEnd of calculating ETo\n")
#}

stopCluster(cl)