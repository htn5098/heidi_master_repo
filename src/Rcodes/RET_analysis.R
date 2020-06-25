# *** ANALYZING ETO DATA FROM UW GCMs ***
# AUTHOR: HEIDI NGUYEN 
# email: htn5098@psu.edu

inputs = commandArgs(trailingOnly=T)


# CHANGING LIBRARY PATH
.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

# CHANGING WORKING DIRECTORIES AND PATHS FOR INPUT AND INTERIME FILES
setwd('/storage/home/htn5098/work/DataAnalysis')

# CALLING LIBRARIES
library(data.table)

# READING INPUT FILES AND SUPPORTING INFORMATION
etoHist = fread('./data/processed/UW_clim_historical_RET_grid_daily.csv',header=T)
etoCtrl = fread('./data/processed/UW_hadgem2es365_control_RET_grid_daily.csv', header=T)
dim(etoHist)
dim(etoCtrl)
ctrlPeriod = seq.Date(as.Date("1979-01-01",'%Y-%m-%d'),
                         as.Date("2005-12-31",'%Y-%m-%d'),'days')
etoHistPeriod = as.matrix(etoHist[1:length(ctrlPeriod),])
etoCtrlPeriod = as.matrix(etoCtrl[(nrow(etoCtrl)-length(ctrlPeriod) + 1):nrow(etoCtrl),])
# errorEto = etoCtrlPeriod - etoHistPeriod
# hist(errorEto)

etoHistPeriod <- etoHistPeriod[,colnames(etoHistPeriod)%in%missing]
etoCtrlPeriod <- etoCtrlPeriod[,colnames(etoCtrlPeriod)%in%missing]

etoHistPeriodmeanDaily = apply(etoHistPeriod,2,mean)
etoctrlPeriodmeanDaily = apply(etoCtrlPeriod,2,mean)
plot(etoHistPeriodmeanDaily, etoctrlPeriodmeanDaily)




