.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

library(foreach)
library(doParallel)
library(parallel)

# Registering cores for parallel processing
no_cores <- detectCores() #24 cores per node - enough for parallel processing
print(no_cores)
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# Reading the .nc file 
print("Test loop")
clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35")) # Really have to import library paths into the workers
foreach(i = 1:10) %dopar% { #ncol(var.matrix.sa)
  print(i)
#  outfile=data.frame(var.matrix.sa[,i])
#  grid=colnames(var.matrix.sa)[i]
#  outfilename=paste0('./data/interim/UW_',period,'_',var,'_',grid,'.csv')
#  write.csv(outfile,outfilename,row.names=F,col.names=F)
}
print("Completed")
stopCluster(cl)