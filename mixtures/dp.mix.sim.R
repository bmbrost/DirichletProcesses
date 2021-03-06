rm(list=ls())

library(cluster)

###
### Simulation 1-dimensional Dirichlet process mixture
###

source("/Users/brost/Documents/git/DP/mixtures/dp.utils.R")  # sim functions

n <- 100  # number of observations to simulate
a0 <- 2  # concentration parameter
P0 <- c(0,100)  # lower and upper limits of uniform base measure
H <- 50  # maximum number of clusters for truncation approximation

# Using stick-breaking process (Gelman et al. 2014, BDA Section 23.2)
sim1 <- stick(n,P0,a0,H)
a0*log(n)  # approximates expected number of components

# Using Chinese restaurant process
sim1 <- crp(n,P0,a0)
  
z <- sim1$z  # cluster assignments
hist(z,breaks=1000)
z.tab <- table(z)
z.tab

# Generate observations conditional on cluster assignments
sigma <- 1
y <- rnorm(n,z,sigma)
plot(y,rep(1,n),col=rgb(0,0,0,0.25),pch=19)
points(z,rep(1,n),col="red",pch=19)


###
### Fit models
###

# Fit model according to Escobar (1994), Eq. 3: Gibbs update
# Same as Neal (2000), Algorithm 2
source("/Users/brost/Documents/git/DP/mixtures/dp.mix.escobar.1994.mcmc.R")
out1 <- dp.mix.escobar.1994.mcmc(y,P0,start=list(a0=a0,z=y),n.mcmc=1000)

# Fit model according to Neal (2000), Algorithm 2: Gibbs group update of z
source("/Users/brost/Documents/git/DP/mixtures/dp.mix.neal.2000.algm.2.mcmc.R")
out2 <- dp.mix.neal.2000.algm.2.mcmc(y,P0,start=list(a0=a0,z=y),n.mcmc=1000)

# Fit model according to Neal (2000), Algorithm 5: MH update
source("/Users/brost/Documents/git/DP/mixtures/dp.mix.neal.2000.algm.5.mcmc.R")
out3 <- dp.mix.neal.2000.algm.5.mcmc(y,P0,tune=list(z=0.5),
  start=list(a0=a0,z=y),n.mcmc=1000)

# Fit model according to Neal (2000), Algorithm 7: MH update
source("/Users/brost/Documents/git/DP/mixtures/dp.mix.neal.2000.algm.7.mcmc.R")
out4 <- dp.mix.neal.2000.algm.7.mcmc(y,P0,tune=list(z=0.5),
  start=list(a0=a0,z=y),n.mcmc=1000)

# Fit model according to Neal (2000), Algorithm 8: auxilliary variables
source("/Users/brost/Documents/git/DP/mixtures/dp.mix.neal.2000.algm.8.mcmc.R")
out5 <- dp.mix.neal.2000.algm.8.mcmc(y,P0,priors=list(m=3),tune=list(z=0.5),
  start=list(a0=a0,z=z),n.mcmc=1000)

# Fit model using blocked Gibbs sampler 
source("/Users/brost/Documents/git/DP/mixtures/dp.mix.blocked.mcmc.R")
# hist(rgamma(1000,2,2),breaks=100)
# hist(rgamma(1000,1,1),breaks=100)
start <- list(a0=a0,z=fitted(kmeans(y,rpois(1,10))),pie=rdirichlet(1,rep(1/H,H)),
  sigma=sigma)
out6 <- dp.mix.blocked.mcmc(y,P0,
    priors=list(H=H,r=20,q=10,sigma.l=0,sigma.u=5),
    tune=list(z=0.5,sigma=0.1),start=start,n.mcmc=1000)

mod <- out1
mod <- out2
mod <- out3
mod <- out4
mod <- out5
mod <- out6
idx <- 1:1000
idx <- 1:5000
idx <- 9000:10000

# True clusters
hist(z,breaks=1000,prob=TRUE,col="red",border="red",ylim=c(0,1))
hist(mod$z[,idx],breaks=1000,prob=TRUE,add=TRUE)  # modeled clusters
points(y,rep(-0.01,n),col=rgb(0,0,0,0.25),pch="|",cex=0.75) # observations
points(z,rep(-0.01,n),col="red",pch="|",cex=0.75)  # true clusters

# Concentration parameter
hist(mod$a0[idx],breaks=100);abline(v=a0,col=2,lty=2) 
mean(mod$a0[idx])*log(n)

# Observation error
hist(mod$sigma[idx],breaks=100);abline(v=sigma,col=2,lty=2)

# Modeled number of clusters
plot(apply(mod$z[,idx],2,function(x) length(unique(x))),type="l")  
abline(h=length(z.tab),col=2,lty=2)  # true number of clusters


plot(apply(mod$z[,idx],2,max),type="l")
cl.ranks <- apply(mod$z[,idx],2,dense_rank)
plot(c(mod$z[,idx])[c(cl.ranks)==8],type="l")

hist(c(mod$z[,idx])[c(test)==1],breaks=500,xlim=range(mod$z[idx]),ylim=c(0,5),prob=TRUE)  
hist(c(mod$z[,idx])[c(test)==5],col=5,breaks=500,add=TRUE,prob=TRUE)  

pt.idx <- 94
plot(mod$z[pt.idx,idx],type="l");abline(h=z[pt.idx],col="red",lty=2)
hist(mod$z[,idx],breaks=5000,xlim=c(range(mod$z[pt.idx,])+c(-10,10)),prob=TRUE)
hist(mod$z[pt.idx,idx],breaks=50,col="red",add=TRUE,border="red",prob=TRUE);abline(v=z[pt.idx],col="red",lty=2)
points(y[pt.idx],-0.010,pch=19)

which.max(apply(mod$z,1,var))
abline(v=29.75)
which.min(sapply(y,function(x) dist(c(x,29.75))))
