library(dplyr)
setwd('C:\\01.PSU\\02.DataAnalysis\\data')
pctplanting <- read.csv('./raw/Kurachik2006Paper.csv')
pctplanting %>% #checking length of data
  group_by(State) %>%
  summarize(n_distinct(Year))


  
