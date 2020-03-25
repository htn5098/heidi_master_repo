library(ncdf4)

file1 = "E:\\UW_MACA_data\\UW_GCM\\Actual_UW\\force_SERC_8th.1979_2016.nc"
filewind = "E:\\UW_MACA_data\\UW_GCM\\Actual_UW\\wind_SERC_8th.1979_2016.nc"
coord_se <- read.csv('SDGrid0125sort.txt', sep = ',', header = T)
indx = sort(unique(coord_se$Grid))
county = sort(unique(coord_se$COUNTYNS))

nc_file1 <- nc_open(file1) # change filename
nc_filewind <- nc_open(filewind)

var = 'wind_speed'
nc_var <- ncvar_get(nc_filewind, varid = var)
dim <- dim(nc_var)
varM <- aperm(nc_var, c(3,2,1))
dim(varM) <- c(dim[3],dim[2]*dim[1])
varM_sel <- varM[,indx]
colnames(varM_sel) <- as.character(indx)
indx_NA <- which(colSums(is.na(varM_sel)) != 0)
varM_sel[,indx_NA] <- 0
#var_df <- data.frame(varM_sel)

fwrite(varM_sel,paste0("SD_",var,"_grid.csv"),row.names = F)
