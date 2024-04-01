project_data <- read.csv("/Users/jayco/Desktop/EBGN590/Data Memos/Data/project_data.csv")

library("tidyverse")
library("dplyr")
library("moments")
library("lmtest")
library("sandwich")
library("car") 

head(project_data)

obe_rate <- project_data$ObeRate
mhi <- project_data$MedHouseInc
black_pop <- project_data$BlackPopPercent
latino_pop <- project_data$LatinoPopPercent
college_edu <- project_data$CollegeEduPercent

min(college_edu, na.rm = TRUE)
max(college_edu, na.rm = TRUE)
mean(college_edu, na.rm = TRUE)
sd(college_edu, na.rm = TRUE)

skewness(college_edu, na.rm = TRUE)
kurtosis(college_edu, na.rm = TRUE)

project_model <- lm(formula = obe_rate~mhi+black_pop+latino_pop+college_edu, project_data)
summary(project_model)
with(project_data, plot(mhi, obe_rate,
                    ylab="Obesity Rate 2019 (age 10-17 in %)",
                    xlab="Median Household Income 2019 (in $)",
                    main="Childhood Obesity Rate vs Median Household Income, 2019"))
abline(project_model)

coeftest(project_model, vcov = vcovHC(project_model, type = "HC0"))



project_model1 <- lm(formula = obe_rate~mhi, project_data)
project_model2 <- lm(formula = obe_rate~mhi+black_pop, project_data)
project_model3 <- lm(formula = obe_rate~mhi+black_pop+latino_pop, project_data)
project_model4 <- lm(formula = obe_rate~mhi+black_pop+latino_pop+college_edu, project_data)

summary(project_model1)
summary(project_model2)
summary(project_model3)
summary(project_model4)

coeftest(project_model1, vcov = vcovHC(project_model1, type = "HC0"))
coeftest(project_model2, vcov = vcovHC(project_model2, type = "HC0"))
coeftest(project_model3, vcov = vcovHC(project_model3, type = "HC0"))
coeftest(project_model4, vcov = vcovHC(project_model4, type = "HC0"))
