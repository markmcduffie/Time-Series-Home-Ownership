library(mgcv)
library(ggplot2)
library(TSA)
library(dynlm)
library(stringr)
library(dplyr)


###################################################################################################################
data_pre = read.table("Homeownership Rate-1.csv",header=F)
data_pre <- data_pre[104:264,1]
data <- str_split_fixed(data_pre, ',', 2)
data <- as.data.frame(data)
data <- data %>% rename_at(2, ~'Home Ownership')
data <- data %>% rename_at(1, ~'Fiscal Quarter')
data


##############################
rate = ts(data,start=1,frequency=4)
ts.plot(rate,ylab="Ownership Rate")
############### TREND ESTIMATION ###################
## Is there a trend in the average rateerature?

## X-axis points converted to 0-1 scale, common in nonparametric regression
time.pts = c(1:length(rate))
time.pts = c(time.pts - min(time.pts))/max(time.pts)

## Fit a moving average 
mav.fit = ksmooth(time.pts, rate, kernel = "box")
rate.fit.mav = ts(mav.fit$y,start=1,frequency=4)
ts.plot(rate,ylab="Ownership rate")
lines(rate.fit.mav,lwd=2,col="purple")
abline(rate.fit.mav[1],0,lwd=2,col="blue")

## Fit a parametric quadraric polynomial
x1 = time.pts
x2 = time.pts^2
lm.fit = lm(rate~x1+x2)
summary(lm.fit)
rate.fit.lm = ts(fitted(lm.fit),start=1,frequency=4)
ts.plot(rate,ylab="Ownrship rate")
lines(rate.fit.lm,lwd=2,col="green")
abline(rate.fit.mav[1],0,lwd=2,col="blue")

## Fit a trend using non-parametric regression
## Local Polynomial Trend Estimation
loc.fit = loess(rate~time.pts)
rate.fit.loc = ts(fitted(loc.fit),start=1,frequency=4)
## Splines Trend Estimation
gam.fit = gam(rate~s(time.pts))
rate.fit.gam = ts(fitted(gam.fit),start=1,frequency=4)
## Is there a trend? 
ts.plot(rate,ylab="Ownership rate")
lines(rate.fit.loc,lwd=2,col="brown")
lines(rate.fit.gam,lwd=2,col="red")
abline(rate.fit.loc[1],0,lwd=2,col="blue")

## Compare all estimated trends
all.val = c(rate.fit.mav,rate.fit.lm,rate.fit.gam,rate.fit.loc)
ylim= c(min(all.val),max(all.val))
ts.plot(rate.fit.lm,lwd=2,col="green",ylim=ylim,ylab="Ownership rate")
lines(rate.fit.mav,lwd=2,col="purple")
lines(rate.fit.gam,lwd=2,col="red")
lines(rate.fit.loc,lwd=2,col="brown")
legend(x=60,y=120,legend=c("MAV","LM","GAM","LOESS"),lty = 1, col=c("purple","green","red","brown"))

################ SEASONALITY ESTIMATION #########################

## Estimate seasonality using ANOVA approach
## Drop January (model with intercept)
model1 = lm(rate~season(rate))
summary(model1)
## All seasonal mean effects (model without intercept)
model2 = lm(rate~season(rate)-1)
summary(model2)

## Estimate seasonality using cos-sin model
model3=lm(rate~harmonic(rate))
summary(model3)
model4=lm(rate~harmonic(rate,2))
summary(model4)

## Compare Seasonality Estimates
## Seasonal Means Model
st1 = coef(model2)
## Cos-Sin Model
st2 = fitted(model4)[1:12]
plot(1:12,st1,lwd=2,type="l",xlab="Month",ylab="Seasonality")
lines(1:12,st2,lwd=2, col="brown")

################ TREND AND SEASONALITY ESTIMATION #########################
## Using linear regression

## Fit a parametric model for both trend and seasonality
## Linear trend
lm.fit.lin = dynlm(rate~trend(rate)+harmon(rate,2))
## Quadratic trend
x1 = time.pts
x2 = time.pts^2
lm.fit = dynlm(rate~x1+x2+harmon(rate,2))
summary(lm.fit)
dif.fit.lm = ts((rate-fitted(lm.fit)),start=1879,frequency=12)
ts.plot(dif.fit.lm,ylab="Residual Process")

## Fit a non-parametric model for trend and linear model for seasonality
har2 = harmonic(rate,2)
gam.fit = gam(rate~s(time.pts)+har2)
dif.fit.gam = ts((rate-fitted(gam.fit)),start=1879,frequency=12)
ts.plot(dif.fit.gam,ylab="Residual Process")

## Compare approaches 
ts.plot(dif.fit.lm,ylab="Residual Process",col="brown")
lines(dif.fit.gam,col="blue")

acf(rate,lag.max=12*4,main="")
acf(dif.fit.lm,lag.max=12*4,main="")
acf(dif.fit.gam,lag.max=12*4,main="")