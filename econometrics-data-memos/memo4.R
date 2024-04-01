ps3_data <- read.csv("/Users/jayco/Desktop/EBGN590/Data Memos/Data/rural_atlas_merged.csv")

 
library("tidyverse")
library("dplyr")
library("moments")
library("lmtest")
library("sandwich")
library("car") 

head(ps3_data) 

ps3_data$loginc <- ln(ps3_data$PerCapitaInc)
head(ps3_data$loginc) 


summary(ps3_data$loginc) 
mean(ps3_data$loginc, na.rm=TRUE)
sd(ps3_data$loginc, na.rm = TRUE) 
length(ps3_data$loginc) 
skewness(ps3_data$loginc, na.rm = TRUE) 
kurtosis(ps3_data$loginc, na.rm = TRUE) 

model1<-lm(formula = loginc~UnempRate2013+Ed5CollegePlusPct+BlackNonHispanicPct2010+HispanicPct2010+Metro2013, ps3_data)
summary(model1)


coeftest(model1, vcov = vcovHC(model1, type = "HC0"))


linearHypothesis(model1, c("UnempRate2013=0", "Ed5CollegePlusPct=0", "BlackNonHispanicPct2010=0", "HispanicPct2010", "Metro2013"))

linearHypothesis(model1, c("Ed5CollegePlusPct=0", "BlackNonHispanicPct2010=0", "HispanicPct2010", "Metro2013"))


