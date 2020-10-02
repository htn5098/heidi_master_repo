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
library(VSURF)
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

# data("toys")
# dim(toys$x)

# toys.vsurf.parallel <- VSURF(toys$x, toys$y, mtry = 100, parallel = TRUE, ncores = no_cores, clusterType = "FORK")
# summary(toys.vsurf.parallel)

# DATASETS ----------------------------------------------------------------
data_raw <- fread('./data/processed/ARSN2O_data_panel.csv',header =T) %>%
  mutate(Ring = factor(Ring, levels = c('L','M','H')),
         Treatment = factor(Treatment, levels = c('CRP','Switchgrass_0N','Switchgrass_50N',
                                                  'Miscanthus')))
data_fullN2O <- data_raw %>%
  filter(!is.na(logN2OE)) %>%
  select(-Lab_ID,-starts_with('Well'),-Plot) %>%
  select(-N2OE,-SMdeep,-SMshallow,-SMmiddle,-SoilO2,-Precip) %>%
  na.omit()

data_full_noO2 <- data_raw %>%
  select(-Lab_ID,-starts_with('Well'),-Plot) %>%
  select(-N2OE,-SMdeep,-SMshallow,-SMmiddle,-SoilO2,-Precip,-SoilO2MA) %>%
  filter(!is.na(logN2OE)) %>%
  na.omit()
  
nrow(data_raw)
nrow(data_fullN2O)
nrow(data_full_noO2)

# VARIABLE SELECTION USING VSURF FOR ONE ITERATION -----------------------------
set.seed(2734, kind = "L'Ecuyer-CMRG")
y = data_fullN2O$logN2OE
x = data_fullN2O[,5:32]
colnames(x)
mtry = ncol(x)/3
fullN2O_Varsel <- VSURF(x = x, y = y, mtry = mtry, ntree = 800, parallel = TRUE, ncores = (no_cores -1), clusterType = "FORK")
summary(fullN2O_Varsel)
print(fullN2O_Varsel$varselect.pred)

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