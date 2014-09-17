rm(list=ls())
###
Y<-dget("http://www.stat.washington.edu/hoff/Code/hoff_2005_jasa/IR/Y")

n<-dim(Y)[1]

Xd<-dget("http://www.stat.washington.edu/hoff/Code/hoff_2005_jasa/IR/X.dist") #distance
Xd<-array(Xd,dim=c(n,n,1))/1000

Xp<-dget("http://www.stat.washington.edu/hoff/Code/hoff_2005_jasa/IR/X.pop") #pops
Xp<-log(matrix( Xp,nrow=n,ncol=1))

###

source("http://www.stat.washington.edu/hoff/Code/hoff_2005_jasa/gbme.r")

##
gbme(Y=Y,Xd=Xd,Xs=Xp,Xr=Xp,fam="poisson",k=2,odens=50)                       

source("http://www.stat.washington.edu/hoff/Code/hoff_2005_jasa/gbme.postana.r")
 
