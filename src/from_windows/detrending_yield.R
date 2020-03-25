# Detrending yield for CORN from NASS database
# level: country
# type: time series
setwd('C:\\01.PSU\\02.DataAnalysis')
library(RODBC)
library(dplyr)
library(smooth)
library(Mcomp)
library(fANCOVA)
library(data.table)
library(stringr)

ydb <- odbcConnectAccess2007('./data/raw/USDA_NASS_Yield.accdb')
sqlTables(ydb)

yield38 <- sqlQuery(ydb,"select * from SDNASSYieldCORN_38",as.is = T)


# CHOOSING SERIES MORE THAN 15 CONTINUOUS YEARS --------------------------------------

yield38.list <- yield38 %>%
  mutate(COUNTYNS = as.factor(COUNTYNS)) %>%
  split(f = yield38$COUNTYNS)

runlength.matrix <- data.frame()

for (i in seq_along(yield38.list)) {
  year <- yield38.list[[i]][,'Year']
  dyear <- diff(year)
  run <- rle(dyear)
  maxlength <- max(run$lengths[run$values==-1])
  runlength.matrix[i,1] <- names(yield38.list[i])
  runlength.matrix[i,2] <- maxlength
}

hist(as.numeric(runlength.matrix[,2]))

county.long <- runlength.matrix$V1[runlength.matrix$V2 >= 30]
## choosing counties that are more than 25 years of continous data

# LINEARITY AND STATIONARITY OF TIME SERIES -------------------------------
yield38.long.list <- yield38.list[county.long]
yieldrun.list <- list()

for (i in seq_along(yield38.long.list)) {
  year <- rev(yield38.long.list[[i]][,'Year'])
  year0 <- year[1]
  dyear <- diff(year)
  run <- rle(dyear)
  maxlength <- max(run$lengths[run$values==1])
  year1 <- year0 + which.max(run$length)-1
  year2 <- year0 + sum(run$lengths[1:which.max(run$lengths)])
  data <- subset(yield38.long.list[[i]],Year %in% year1:year2)
  yieldrun.list[[i]] <- data
}

## Normality test with Shapiro-Wilk's test:
yield.normality <- data.frame()
for (i in seq_along(yieldrun.list)) {
  y <- yieldrun.list[[i]]$Yield
  p <- shapiro.test(y)$p.value
  yield.normality[i,1] <- unique(yieldrun.list[[i]]$COUNTYNS)
  yield.normality[i,2] <- p
}

## Statitionarity test:
yield.stationarity <- data.frame()
for (i in seq_along(yieldrun.list)) {
  y <- yieldrun.list[[i]]$Yield
  s <- Box.test(y)$p.value
  yield.stationarity[i,1] <- unique(yieldrun.list[[i]]$COUNTYNS)
  yield.stationarity[i,2] <- s
}

yieldrun.full <- purrr::reduce(list(yield.normality,yield.stationarity,
                                    runlength.matrix),merge, by = 'V1')
names(yieldrun.full) <- c('COUNTYNS','Normality','Stationarity','Length')

# checking a few counties
# check <- subset(yield38,COUNTYNS == '01008545')
# plot(check$Yield)
# plot(diff(check$Yield))
# qqnorm(check$Yield)
# qqline(check$Yield)


# Detrending --------------------------------------------------------------


# # Simple Linear Regression ---------------------------------------------------------------
rmse_slr <- c()
for (i in seq_along(yieldrun.list)) {
  d <- yieldrun.list[[i]]
  slr <- lm(Yield ~ Year, d)
  s <- summary(slr)
  r <- sqrt(sum(s$residuals^2))
  rmse_slr[i] <- r 
}
mean(rmse_slr)


# # Second order polynomial regression --------------------------------------
rmse_quad <- c()
for (i in seq_along(yieldrun.list)) {
  d <- yieldrun.list[[i]]
  qlr <- lm(Yield ~ Year + I(Year^2), d)
  s <- summary(qlr)
  r <- sqrt(sum(s$residuals^2))
  rmse_quad[i] <- r 
}
mean(rmse_quad)


# # Moving average window ---------------------------------------------------


# # Locally weighted scatterplot smoother (LOWESS or LOESS) --------------------------------------------
rmse_loess <- c()
for (i in seq_along(yieldrun.list)) {
  d <- yieldrun.list[[i]]
  lo.mod <- loess.as(d$Year, d$Yield, degree = 2, criterion = 'gcv',
                     plot = T)
  r <- lo.mod$s
  rmse_loess[i] <- r
}
mean(rmse_loess)

d.yield <- list()
for (i in seq_along(yieldrun.list)) {
  d <- yieldrun.list[[i]]
  lo.mod <- loess.as(d$Year, d$Yield, degree = 2, criterion = 'gcv',
                     plot = F)
  dtr <- lo.mod$residuals
  d.yield[[i]] <- data.frame(COUNTYNS = d$COUNTYNS,
                             Year = d$Year, 
                             Yield.dtr = dtr)
}
names(d.yield) <- county.long


# TEST: Detrended yield and Abatz_ETo -------------------------------------

ref.evap <- fread("C:\\01.PSU\\02.DataAnalysis\\testing\\RET_county_daily.csv",
                     select = paste0('X',(as.numeric(county.long))))

county.evap <- str_remove(colnames(ref.evap),'X') %>%
  str_pad(8,side = 'left','0')
colnames(ref.evap) <- county.evap
ref.evap.list <- melt(ref.evap,variable.name = 'COUNTYNS',
                 value.name = 'RET') %>%  split(f = "COUNTYNS")
d.yield_new <- d.yield[county.evap]


for(i in seq_along(d.yield_new)) {
  
}
