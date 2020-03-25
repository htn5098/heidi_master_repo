library(RODBC)
library(dplyr)
library(ggplot2)
library(data.table)

# Exploring possible relationship between ETo (by Abatzaglou) and detrended yield
ydb <- odbcConnectAccess2007("C:\\01.PSU\\02.DataAnalysis\\data\\processed\\NASSYield.accdb")

ydtr <- sqlQuery(ydb,'select * from SDNASSYieldCORN_dtr',as.is = T) # detrended yield for 

county <- unique(ydtr$COUNTYNS) # 660 counties, which means even counties with short period were included

n.year <- ydtr %>% group_by(COUNTYNS) %>%
  count() # time series from 1980-2005, with lowest of 11 years

missing.data <- ydtr %>%
  dcast(COUNTYNS ~ Year) # looks like all time series are continous

ggplot(ydtr,aes(x = Year, y = YieldDtr, col = COUNTYNS)) +
  geom_line() +
  guides(col = F) # looks like the detrended yields have equal vairance

# Detrended Yield and ETo by Abatzaglou
ETo <- fread("C:\\01.PSU\\02.DataAnalysis\\testing\\RET_county_daily.csv")
ETo.year <- ETo %>%
  mutate(Time = seq.Date(as.Date('1979-01-01','%Y-%m-%d'),
                         as.Date('2016-12-31','%Y-%m-%d'),'days')) %>%
  filter(month(Time) %in% 4:9) %>%
  group_by(Year = year(Time)) %>%
  summarise_at(vars(starts_with('X')),.funs = sum) %>%
  melt(id.var = 'Year', variable.name = 'COUNTYNS', value.name = 'PET',
       variable.factor = F) %>%
  mutate(COUNTYNS = stringr::str_remove(COUNTYNS,'X')) %>%
  mutate(COUNTYNS = stringr::str_pad(COUNTYNS,8,side = 'left','0'))

yieldETo <- inner_join(ydtr,ETo.year, by = c('COUNTYNS','Year'))

yieldETo.corr <- yieldETo %>%
  group_by(COUNTYNS) %>%
  summarise(R = cor(YieldDtr,PET))

hist(yieldETo.corr$R)
  