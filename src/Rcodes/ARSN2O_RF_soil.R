#### COMPARING MODELS ###
# AUTHOR: HEIDI NGUYEN
# Email: htn5098@psu.edu

# SETTING WORKING DIRECTORY
setwd('/storage/work/h/htn5098/DataAnalysis')

# CHANGING LIBRARY PATH
.libPaths("/storage/home/htn5098/local_lib/R35") # needed for calling packages
.libPaths()

# LIBRARY
library(data.table)
library(dplyr)
library(ranger)
library(randomForest)
library(caret)
library(rsample)
library(foreach)
library(doParallel)
library(parallel)

# Registering cores for parallel processing
no_cores <- detectCores() #24 cores per node - enough for parallel processing
cl <- makeCluster(no_cores)
registerDoParallel(cl)
invisible(clusterEvalQ(cl,.libPaths("/storage/home/htn5098/local_lib/R35")))

# DATASETS ----------------------------------------------------------------
panel_full <- fread('./data/processed/ARSN2O_data_panel.csv',
                    header=T) %>%
  mutate(Ring = factor(Ring, levels = c('L','M','H')),
         Treatment = factor(Treatment,levels = c('CRP','Switchgrass_0N',
                                                 'Switchgrass_50N','Miscanthus')),
         Water_present = as.factor(Water_present)) %>%
  select(-N2OE,-Lab_ID,-SoilO2,-SMdeep,-SMshallow,-SMmiddle,-Precip) 
head(panel_full)
str(panel_full)
panel_o2_rm <- panel_full %>%
  select(-SoilO2MA) %>%
  na.omit()
dim(panel_o2_rm)  
panel_NA_rm <- na.omit(panel_full)
dim(panel_NA_rm)

# RUNNING RANDOM FOREST FOR ALL VARIABLE AVAILABLE -----------------------------
set.seed(123)
iter = 100
cat('Number of iterations:',iter,'\n')
# hyper_grid = expand.grid(
  # mtry = seq(3,(ncol(panel_NA_rm)-4),by=2),
  # node_size = seq(3,30,3),
  # sampe_size = c(.55, .632, .70, .80),
  # OOB_RMSE   = 0
# )
# dim(hyper_grid)
#hyper_optimal_list <- list()
varImp_list <- list()
#purity_list <- list()
## Stratified CV
varImp_tab <- foreach(i = 1:iter, .packages = c('ranger','rsample','randomForest','data.table','dplyr'),
				.combine = rbind) %dopar% {
	breaks <- seq(min(panel_NA_rm$logN2OE),
				max(panel_NA_rm$logN2OE),
				length.out = 11)
	bin_names <- paste0('b',seq(1,10))
	bins <- cut(panel_NA_rm$logN2OE,
			  breaks=breaks,
			  include.lowest = T,
			  right=F,
			  labels=bin_names)
	panel_NA_rm$Bins <- bins
	panel_NA_rm_split <- initial_split(panel_NA_rm,
									 prop=0.7,
									 strata = 'Bins')
	panel_NA_rm_train <- training (panel_NA_rm_split) %>%
		select(-Label_ID,-Year,-Jday,-Bins)
	panel_NA_rm_test <- testing(panel_NA_rm_split) %>%
		select(-Label_ID,-Year,-Jday,-Bins)
	# for (j in 1:nrow(hyper_grid)) { #nrow(hyper_grid)
	# model <- ranger(
	  # formula         = logN2OE ~ ., 
	  # data            = panel_NA_rm_train, 
	  # num.trees       = 800,
	  # mtry            = hyper_grid$mtry[j],
	  # min.node.size   = hyper_grid$node_size[j],
	  # sample.fraction = hyper_grid$sampe_size[j],
	  # seed            = 123)
	# hyper_grid$OOB_RMSE[j] <- sqrt(model$prediction.error)
	# }
	# hyper_optimal <- hyper_grid[which.min(hyper_grid$OOB_RMSE),]
	rf_withO2_final <- randomForest(
	  formula         = logN2OE ~ ., 
	  data            = panel_NA_rm_train, 
	  ntree           = 800,
	  mtry            = 6,#hyper_optimal$mtry,
	  nodesize        = 10,#hyper_optimal$node_size,
	  sampesize       = 0.65,#round(hyper_optimal$sampe_size*nrow(panel_NA_rm_train)),
	  importance      = T)
	#hyper_optimal_list[[i]] <- hyper_optimal
	#varImp_list[[i]] <- rf_withO2_final$importance[,1]
	rf_withO2_final$importance[,1]
	#purity_list[[i]] <- rf_withO2_final$importance[,2]
} 
#hyper_opt_tab <- data.frame(do.call(rbind,hyper_optimal_list))
#varImp_tab <- do.call(rbind,varImp_list)
head(varImp_tab)
#print(varImp_list) 
#purity_tab <- data.frame(do.call(rbind,purity_list))  

#write.csv(hyper_opt_tab,'Optimal_hyperParameter.csv',row.names = F)
write.csv(varImp_tab,paste0('VarImportance_',iter,'.csv',row.names = F)
#write.csv(purity_tab,'VarPurity.csv',row.names = F)

stopCluster(cl)

# # RUNNING RANDOM FOREST FOR DATA WITHOUT SOIL O2 -----------------------------
# set.seed(123)
# iter = 1000
# ## Stratified CV
# panel_o2_rm <- panel_full %>%
  # select(-SoilO2MA) %>%
  # na.omit()
# imp_rmO2 <- foreach( i = 1:iter, .packages = c('ranger','rsample'),.combine = cbind) %do% {
	# breaks <- seq(min(panel_o2_rm$logN2OE),
				  # max(panel_o2_rm$logN2OE),
				  # length.out = 11)
	# bin_names <- paste0('b',seq(1,10))
	# bins <- cut(panel_o2_rm$logN2OE,
				# breaks=breaks,
				# include.lowest = T,
				# right=F,
				# labels=bin_names)
	# panel_o2_rm$Bins <- bins
	# panel_o2_rm_split <- initial_split(panel_o2_rm,
									   # prop=0.7,
									   # strata = 'Bins')
	# panel_o2_rm_train <- training (panel_o2_rm_split) %>%
	  # select(-Label_ID,-Year,-Jday,-Bins)
	# panel_o2_rm_test <- testing(panel_o2_rm_split) %>%
	  # select(-Label_ID,-Year,-Jday,-Bins)
	# rf_rmO2_final <- randomForest(
	# formula         = logN2OE ~ ., 
	# data            = panel_o2_rm_train, 
	# ntree           = 800,
	# mtry            = hyper_optimal$mtry,
	# nodesize        = hyper_optimal$node_size,
	# sampesize       = round(hyper_optimal$sampe_size*nrow(panel_o2_rm_train)),
	# importance      = T
	# )
	# importance <- rf_rmO2_final$importance[,1]
# } 

# write.csv(imp_withO2,'./data/processed/imp_withO2.csv',row.names=F)
# write.csv(imp_rmO2.'./data/processed/imp_rmO2.csv',row.names=F)