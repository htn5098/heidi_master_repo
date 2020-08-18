# *** ESTIMATING EFFECTIVE PRECIPITATION ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

# INPUTS
inputs=commandArgs(trailingOnly = T)
interimpath=as.character(inputs[1])
var=as.character(inputs[2])
method=as.character(inputs[3])
dur=as.numeric(inputs[4])

cat('\n Historical effective rainfall estimation using ', method, '\n')

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
# library(parallel)
library(data.table)
library(SPEI)

# REGISTERING WORKERS FOR PARALLEL PROCESSING
# no_cores <- detectCores()
# cl <- makeCluster(no_cores)
# registerDoParallel(cl)
#invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35"))) # Really have to import library paths into the workers

# READING INPUT AND SUPPORTING DATA FILES
op = fread('./data/processed/GridMET_hist_pr_county.csv',header=T)
pet = fread(paste0('./data/processed/GridMET_hist_pet_county.csv'),header=T)
time <- seq.Date(from=as.Date('1979-01-01','%Y-%m-%d'),length.out = nrow(op),by="day")
ep.monthly = fread(paste0('./data/processed/GridMET_hist_',method,'_county.csv'),header=T)

op.monthly <- op %>%
  group_by(Year=year(time),Month=month(time)) %>%
  summarize_all(sum)

pet.monthly <- pet %>%
  group_by(Year=year(time),Month=month(time)) %>%
  summarize_all(sum)

bal.op.monthly <- cbind(op.monthly[,-c(1,2)] - pet.monthly[,-c(1,2)])
bal.ep.monthly <- cbind(ep.monthly[,-c(1,2)] - pet.monthly[,-c(1,2)])

# ESTIMATING DROUGHT INDICES 
## Using OP
spi.op <- apply(op.monthly[,-c(1,2)],2,function(x) {
  t <- ts(x,start=c(1979,1),end=c(2019,12),frequency=12)
  id <- spi(t,dur)
  fit <- unlist(id$fitted)
})
spei.op <- apply(bal.op.monthly,2,function(x) {
  t <- ts(x,start=c(1979,1),end=c(2019,12),frequency=12)
  id <- spei(t,3)
  fit <- unlist(id$fitted)
})

## Using EP
spi.ep <- apply(ep.monthly[,-c(1,2)],2,function(x) {
  t <- ts(x,start=c(1979,1),end=c(2019,12),frequency=12)
  id <- spi(t,dur)
  fit <- unlist(id$fitted)
})
spei.ep <- apply(bal.ep.monthly,2,function(x) {
  t <- ts(x,start=c(1979,1),end=c(2019,12),frequency=12)
  id <- spei(t,3)
  fit <- unlist(id$fitted)
})

fwrite(spi.op,paste0('GridMET_hist_spiop_',dur,'m_county.csv'),row.names = F)  
fwrite(spei.op,paste0('GridMET_hist_speiop_',dur,'m_county.csv'),row.names = F)  
fwrite(spi.ep,paste0('GridMET_hist_spi',method,'_',dur,'m_county.csv'),row.names = F)
fwrite(spei.ep,paste0('GridMET_hist_spei',method,'_',dur,'m_county.csv'),row.names = F)  

#stopCluster(cl)