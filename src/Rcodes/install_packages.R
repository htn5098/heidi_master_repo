lib = "/storage/home/htn5098/local_lib/R35"
repos = "http://lib.stat.cmu.edu/R/CRAN/"

.libPaths(lib)
.libPaths()

# Installing packages that doesn't exist
req.packages <- c("googledrive",
                  "ncdf4",
                  "data.table",
                  "dplyr",
                  "foreach",
                  "doParallel",
                  "filematrix")

installed <- installed.packages()

for(i in req.packages) {
  if (i %in% installed) {
    print(paste(i,'exists'))
  } else {
    install.packages(i,lib=lib,repos=repos,verbose=F)
  }
}
