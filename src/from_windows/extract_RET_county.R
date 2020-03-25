setwd('/storage/hpc/data/htnb4d/RIPS/waterdemandstudy/')
outpath = '/storage/hpc/data/htnb4d/RIPS/waterdemandstudy/RET_daily_county/'

library(foreach)
library(doParallel)
library(parallel)
library(lubridate)
library(dplyr)
library(data.table)

no_cores <- detectCores()
cl <- makeCluster(no_cores)
registerDoParallel(cl)

years <- 1979:2016
months <- 4:9
time <- seq.Date(as.Date('1979-01-01'), as.Date('2016-12-31'), by ='days')
ret_files <- list.files(path = './RET_raw/',pattern = 'pet*', full.names = T)
gridret <- read.table("ret_indx_clean.txt",sep = ',', header = T)
indx <- sort(unique(gridret$Grid))
county <- sort(unique(gridret$COUNTYNS))

# Gridded daily RET dataset
ret_se <- foreach(i = years,.export=c("ret_files","indx"),.verbose=F,.combine = rbind) %dopar% {
  library(ncdf4)
  nc_file <- nc_open(grep(i,ret_files,value=T))
  ret <- ncvar_get(nc_file,varid = 'potential_evapotranspiration',start = c(795,210,1), count = c(391,266,-1))
  dim <- dim(ret) 
  ret_matrix <- aperm(ret, c(3,2,1)) 
  dim(ret_matrix) <- c(dim[3],dim[2]*dim[1]) 
  ret_sel <- ret_matrix[,indx]
  return(ret_sel)
}
colnames(ret_se) = as.character(indx)
ret_grid <- data.frame(time, ret_se)
#write.csv(ret_grid,"RET_grid_daily.csv",row.names = F)

# Gridded growing season monthly RET dataset
ret_grid_month <- ret_grid %>%
  mutate(Month = month(Time), Year = year(Time)) %>%
  subset(Month %in% months, select = -Time) %>%
  group_by(Month,Year) %>%
  summarize_all(sum)
#write.csv(ret_grid_month,"RET_grid_month.csv",row.names = F)

# County-level daily RET dataset 
ret_county_daily <- foreach(i = seq_along(county), .combine = cbind) %dopar% {
  pointid <- as.character(gridret$Grid[gridret$COUNTYNS == county[i]])
  wt <- gridret$Area[gridret$COUNTYNS == county[i]]
  var <- ret_se[,pointid]
  head(var)
  if(is.null(dim(var))) {
    aggr = 0
  } else { 
    aggr <- apply(var,1,weighted.mean,w = wt,na.rm = T)
  }
}
colnames(ret_county_daily) <- as.character(county)
ret.df <- ret_county_daily[,which(colSums(ret_county_daily) != 0)]
#write.csv(ret.df,'RET_county_daily.csv',row.names = F)
foreach(i = years,.export = c('ret.df'),.packages = 'lubridate') %dopar% {
  k <- ret.df[year(time) == i,]
  write.csv(k, paste0(outpath,'RET_county_daily',i,'.csv'),row.names = F)
}
stopCluster(cl)