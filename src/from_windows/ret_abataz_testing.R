setwd('C:\\01.PSU\\02.DataAnalysis\\data\\raw\\abatz_met')
library(ncdf4)
library(dplyr)

files <- list.files()

clim.ls <- list()
gridret <- read.table("C:\\01.PSU\\02.DataAnalysis\\data\\external\\ret_indx.txt", sep = ',',
                      header = T)[,c('Grid','COUNTYNS')]

for (i in 1:length(files)) {
  nc_file <- nc_open(files[i])
  var <- names(nc_file$var)
  ret_se <- ncvar_get(nc_file,var,start = c(795,210,1), count = c(391,266,-1))
  dim <- dim(ret_se)
  ret_se_matrix <- aperm(ret_se, c(3,2,1))
  dim(ret_se_matrix) <- c(dim[3],dim[2]*dim[1])
  ret_se_matrix[1:20,1:2]
  dim(ret_se_matrix)
  ret_se_sel <- ret_se_matrix[,gridret$Grid]
  grid.choose <- ret_se_sel[1:10,46963]
  clim.ls[[i]] <- grid.choose
  names(clim.ls)[i] <- var
}

clim.df <- do.call(cbind,clim.ls)

eto.abatz.test <- clim.df[,c(6,5,2,3,8,4)]
colnames(eto.abatz.test) <- NULL
eto.abatz.test[,1:2] <- eto.abatz.test[,1:2] - 273
eto.abatz.test[,6] <- eto.abatz.test[,6]*0.0864

write.table(eto.abatz.test,'E:\\Applications\\EToCalculator64Bit\\IMPORT\\gridmet_testfile.cxt',sep = ' ', 
            row.names = F, col.names = F)
