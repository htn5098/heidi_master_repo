inputs = commandArgs(trailingOnly = T)
crop = inputs[1]

library("rnassqs")
# Authenticating API for NASS
NASSQS_TOKEN="70725CD7-9172-3A7C-B04F-9F87E3D9F151"
nassqs_auth(key = NASSQS_TOKEN)
library(dplyr)
library(rnassqs)
library(RODBC)
library(foreach)

# FUNCTIONS
res_error <- function(params,index) { #catching errors when failing to querry
  tryCatch(
    expr={
      a <- nassqs_GET(params)
      return(a)
    },
    error=function(e){
      message(paste("Error for",index,':'))
      print(e)
      return(NA)
    },
    warning=function(w){
      print(w)
    }
  )
}

setwd('C:\\01.PSU\\02.DataAnalysis\\data')
inputdb <- odbcConnectAccess2007('./external/SDStatistics.accdb') 
outputdb <- odbcConnectAccess2007('./raw/USDANASSData.accdb') 

# STATE AND COUNTY FIP IN THE STUDY DOMAIN: 
state <- sqlQuery(inputdb, "select STATEFP from SDstates where NOTE is null", as.is = T)
stateFP <- state[,1] #turning into vector # Heidi's research
state_alpha <- c('IL', 'IN', 'IA', 'KS', 
                 'KY', 'MI', 'MO', 'MN', 
                 'NE', 'OH', 'SD', 'WI') # Kurachik paper
# MAJOR FOOD CROPS:
#crop <- c('CORN','SOYBEANS','COTTON')

# PLANTING COMPLETION - STATES
for (j in seq_along(crop)) {
  planting <- NULL
  for(i in seq_along(stateFP)) {
    params <- list('commodity_desc'= crop[j],
                   'statisticcat_desc' = 'PROGRESS',
                   'unit_desc' = 'PCT PLANTED',
                   'agg_level_desc' = 'STATE', 
                   "state_alpha" = state_alpha[i],
                   "year_LE" = 2020)
    res <- res_error(params,index = stateFP[i])
    if(any(is.na(res))) {
      print(paste('StateFP',stateFP[[i]],'does not have any record'))
    } else {
      req <- nassqs_parse(res)
      p <- data.frame("Year" = req$year,
                      "StateFIP" = req$state_fips_code,
                      'State' = req$state_name,
                      'Week' = req$reference_period_desc,
                      "Week_ending" = req$week_ending,
                      "PCTPLT" = as.numeric(req$Value))
      planting[[i]] <- p
    }
  }
  planting <- do.call(rbind,planting)
  name <- paste0('NASSPCTPlanting', crop[j])
  write.csv(planting,'./raw/Kurachik2006Paper.csv',row.names = F)
  #sqlSave(outputdb, planting, tablename = name, verbose = F, rownames = F)
}


odbcCloseAll()
