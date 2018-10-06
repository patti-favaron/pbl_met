---
title: "Comparison Report for SonicLib and pbl_met"
author: "Mauri Favaron"
date: "4 October 2018"
output: word_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r code, include=FALSE}
get.amf <- function() {
  d <- read.csv("amf.csv", stringsAsFactors = FALSE)
  d$t.stamp <- as.POSIXct(d$t.stamp, tz="UTC")
  return(d)
}

get.pbm <- function() {
  d <- read.csv("AF_20150414.csv", stringsAsFactors = FALSE)
  e <- read.csv("AF_20150630.csv", stringsAsFactors = FALSE)
  d <- rbind(d,e)
  d$date <- as.POSIXct(d$date, tz="UTC")
  return(d)
}

dir <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$Dir
  new  <- e$dir
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="Dir (° from N)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

vel.chk <- function() {
  e <- get.pbm()
  test <- sqrt(e$u^2+e$v^2)
  new  <- e$vel
  plot(test,new,xlab="sqrt(u^2+v^2)",ylab="pbl_met",cex=0.5,main="Vel (m/s)")
  abline(0,1)
  out <- data.frame(component.vel=test, pbl_met=new)
  return(out)
}

vel.chk.soniclib.2 <- function() {
  e <- get.amf()
  test <- sqrt(e$u.avg^2+e$v.avg^2)
  new  <- e$resultant.vel
  plot(test,new,xlab="sqrt(u^2+v^2)",ylab="SonicLib",cex=0.5,main="Vel (m/s)")
  abline(0,1)
  out <- data.frame(component.vel=test, pbl_met=new)
  return(out)
}

vel.chk.soniclib <- function() {
  e <- get.amf()
  test <- sqrt(e$u.avg^2+e$v.avg^2)
  new  <- e$vel
  plot(test,new,xlab="sqrt(u^2+v^2)",ylab="SonicLib",cex=0.5,main="Vel (m/s)")
  abline(0,1)
  out <- data.frame(component.vel=test, soniclib=new)
  return(out)
}

vel <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$resultant.vel
  new  <- e$vel
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="Vel (m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

u <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$u.avg
  new  <- e$u
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="U (m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

v <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$v.avg
  new  <- e$v
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="V (m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

w <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$w.avg
  new  <- e$w
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="W (m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

t <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$t.avg
  new  <- e$temp
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="Ta (°C)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

q <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$q.avg
  new  <- e$Q
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="Water vapor (mmol/mol)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

c <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$c.avg
  new  <- e$C
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="Carbon dioxide (mmol/mol)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

uu <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$uu
  new  <- e$uu
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="UU (m2/s2)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

vv <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$vv
  new  <- e$vv
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="VV (m2/s2)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

ww <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$ww
  new  <- e$ww
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="WW (m2/s2)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

uv <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$uv
  new  <- e$uv
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="UV (m2/s2)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

uw <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$uw
  new  <- e$uw
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="UW (m2/s2)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

vw <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$vw
  new  <- e$vw
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="VW (m2/s2)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

ut <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$ut
  new  <- e$ut
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="UT (°C m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

vt <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$vt
  new  <- e$vt
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="VT (°C m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

wt <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$wt
  new  <- e$wt
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="WT (°C m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

phi <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$phi
  new  <- e$phi
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="phi (rad)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

theta <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$theta
  new  <- e$theta
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="theta (rad)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}

u.star <- function() {
  d <- get.amf()
  e <- get.pbm()
  test <- d$u.star
  new  <- e$u.star
  plot(test,new,xlab="SonicLib",ylab="pbl_met",cex=0.5,main="u* (m/s)")
  abline(0,1)
  out <- data.frame(soniclib=test, pbl_met=new)
  return(out)
}
```


## Introduction

This is the Comparison Report, documenting the similarity (or not) between analogous computations in SonicLib and pbl_met.

Its use is basically as a test report, starting from the assumption the well-established SonicLib library can be considered as a sort of higher-order instrument than pbl_met eddy covariance section.

The comparison is documented through a set of scatter plots, in which supposedly "identical" quantities from the two libraries are plotted along with the 1st quadrant bisector: ideally, all experimental points should be on this line.

The output report - a Word document - will be expanded as test progress, along with this source file. Scatter plots showing a significant deviation do typically result in issues and investigations, which will result in pbl_met corrections and comparison remakes. As a result, the "wrong" plot will be sooner or later be replaced by a "right" one, and this report will then expand on.

Comparisons are made assuming delay is zero, no trend removal is made, and spikes are detected with a threshold of 3000 standard deviations - that is, it is actually disabled in SonicLib, but "results" of it are reported so to confirm officially that the number of spikes processed is always positively zero.

The test data set is the two days of AmeriFlux Golden Files.

Processing has been made on behalf os a fictional location, let's name it Arcadia (but in reality it's unexistent, despite having well defined coordinates), on two fake dates (compatible with the Ameriflux Golden File day-in-the-year). As indicated by Ameriflux Golden Files instruction, averaging time is set to 30 minutes.

Note the purpose of the test documented in this report is to check "bare" eddy covariance, and not trend removal, nor spike detection and treatment. These may devise their own test reports in future - but you will not find them here.

## Wind components

The block-averages of wind components are expected to be the same in SonicLib and pbl_met - up to rounding and the number of significant figures printed by R and the am_test.f90 pbl_met test procedure.

And here are the plots.

```{r U.plot, echo=FALSE}
d<-u()
```

```{r V.plot, echo=FALSE}
d<-v()
```

```{r W.plot, echo=FALSE}
d<-w()
```

As can be seen, nothing to say: unanimous identity.

## Temperature

Here's the comparison plot:

```{r T.plot, echo=FALSE}
d<-t()
```

All right - or so it visually seems to me.

## Raw (un-rotated) 2nd moments

### Some points

Second moments constitute in a sense the core of eddy covariance, and demand very close attention. Their computing by means of the accumulator method, as used in pbl_met, is notoriously numerically unstable (this is why all moments are computed in double precision in pbl_met).

In addition, an ambiguity arises: when computing the final values, should we divide by N or N-1? That is, would we love more population, or sample statistics? And, may we do something more than just "loving"?

Questions.

Nevertheless, their answer comes necessarily from comparisons.

### Momentum variances

```{r UU.plot, echo=FALSE}
d<-uu()
```

```{r VV.plot, echo=FALSE}
d<-vv()
```

```{r WW.plot, echo=FALSE}
d<-ww()
```

All rights visually.


### Momentum covariances

```{r UV.plot, echo=FALSE}
d<-uv()
```

```{r UW.plot, echo=FALSE}
d<-uw()
```

```{r VW.plot, echo=FALSE}
d<-vw()
```

All rights visually.


### Temperature variance

No plot is supplied, because SonicLib does not evaluate this parameter, and consequently no comparison can be made.

### Momentum - Temperature covariances

```{r UT.plot, echo=FALSE}
d<-ut()
```

```{r VT.plot, echo=FALSE}
d<-vt()
```

```{r WT.plot, echo=FALSE}
d<-wt()
```

## Water vapor

Here comes the mean concentration:

```{r Q.plot, echo=FALSE}
d<-q()
```

## Carbon dioxide

Here comes the mean concentration:

```{r C.plot, echo=FALSE}
d<-c()
```

## Rotation angles

First and second rotation angles are the numerical core of eddy-covariance, and "must" equal between SonicLib and pbl_met.

```{r Iheta.plot, echo=FALSE}
d<-theta()
```

```{r Phi.plot, echo=FALSE}
d<-phi()
```

