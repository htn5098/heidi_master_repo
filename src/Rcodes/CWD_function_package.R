# *** CREATING FOUNDATIONAL FUNCTIONS FOR CWD ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# Function to extract climate variable from array to matrix
ncarray2matrix <- function(nc.var){
  dim <- dim(nc.var)
  # rearranging the dimensions of the array from (lon,lat,day) to (day,lat,lon)
  var.matrix <- aperm(nc.var, c(3,2,1)) 
  dim(var.matrix) <- c(dim[3],dim[2]*dim[1]) # turning the array into a 2d matrix (day,grid)
  return(var.matrix)
}

# Function to aggregate data
aggr_data <- function(gridpoint,county,data) {
  pointid <- gridpoint$Grid[gridpoint$COUNTYNS == county]
  wt <- gridpoint$Area[gridpoint$COUNTYNS == county]/sum(gridpoint$Area[gridpoint$COUNTYNS == county])
  var <- data[,pointid]
  if(is.null(dim(var))) {
    aggr = 0
  } else { 
	ind <- which(colSums(is.na(var)) != 0)
	var[,ind] <- 0	
    aggr <- var%*%wt #apply(var,1,weighted.mean,w = wt,na.rm = T)
  }
  return(aggr)
}

# Function to find the first period of time with more than 14 days over threshold temperature
daysoverTruns <- function(t) {
  for(start in 1:length(t)) {
    run=sum(t[start:(start+14)])
    if(run==15 | start == (length(t)-13)) {
      doy=start+14
      break
    }
  }
  return(doy)
}

# Effective precipitation methods
ep_cropwat <- function(x) {
	if(x <= 250) {
		ep <- x*(125-0.2*x)/125
	} else {
		ep <- 125+0.1*x
	}
}
ep_usda_simplified <- function(x) { #semi-arid
	ep <- 1.9443*(x^0.82416) - 4.56 #1.9443*(x^0.82416) - 4.56
}
ep_fao <- function(x) {
	if(x <= 70) {
		ep <- 0.6*x - 10
	} else {
		ep <- 0.8*x - 25
	}
}

# Saturation vapor pressure
sat.vp.fucn = function(t) { # calculating saturation vapor pressure at ToC
  svp = 0.6108*exp(17.27*t/(t+237.3))
  return(svp)
}
