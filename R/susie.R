#' @title Bayesian sum of single-effect (susie) linear regression of Y on X
#' @details Performs sum of single-effect (susie) linear regression of Y on X.
#' That is, this function
#' fits the regression model Y= sum_l Xb_l + e, where elements of e are iid N(0,s2) and the
#' sum_l b_l is a p vector of effects to be estimated.
#' The assumption is that each b_l has exactly one non-zero element, with all elements
#' equally likely to be non-zero. The prior on the non-zero element is N(0,var=sa2*s2).
#' @param Y an n vector
#' @param X an n by p matrix of covariates
#' @param sa2 the scaled prior variance (vector of length L, or scalar. In latter case gets repeated L times )
#' @param sigma2 the residual variance (defaults to variance of Y)
#' @param niter number of iterations of vb method
#' @param L number of single effects
#' @param calc_elbo indicates whether to compute the evidence lower bound (could slow things down; useful for testing)
#' @return a susie fit, which is a list with some or all of the following elements\cr
#' \item{alpha}{an L by p matrix of posterior inclusion probabilites}
#' \item{mu}{an L by p matrix of posterior means}
#' \item{postvar}{an L by p matrix of posterior variances}
#' \item{Xr}{an n vector of fitted values, equal to X times colSums(alpha*mu))}
#' \item{sigma2}{residual variance}
#' \item{sa2}{scaled prior variance}
#' \item{elbo}{vector of values of elbo achieved (if calc_elbo is TRUE)}
#' @examples
#' set.seed(1)
#' n = 1000
#' p = 1000
#' beta = rep(0,p)
#' beta[1] = 1
#' beta[2] = 1
#' beta[3] = 1
#' beta[4] = 1
#' X = matrix(rnorm(n*p),nrow=n,ncol=p)
#' y = X %*% beta + rnorm(n)
#' res =susie(X,y,niter=10,L=5,calc_elbo = TRUE)
#' coef(res)
#' plot(y,predict(res))
#' @export
susie = function(X,Y,sa2=1,sigma2=NULL,niter=100,L=5,calc_elbo=FALSE){
  if(is.null(sigma2)){
    sigma2=var(Y)
  }

  # Check input X.
  if (!is.double(X) || !is.matrix(X))
    stop("Input X must be a double-precision matrix")


  p = ncol(X)
  n = nrow(X)
  if(length(sa2)==1){
    sa2 = rep(sa2,L)
  }

  # Check inputs sigma and sa.
  if (length(sigma2) != 1)
    stop("Inputs sigma2 must be scalar")
  # Check inputs sigma and sa.
  if (length(sa2) != L)
    stop("Inputs sigma2 must be of length 1 or L")


  #intialize elbo to NA
  elbo = rep(NA,niter)

  #initialize susie fit
  s = list(alpha=matrix(0,nrow=L,ncol=p), mu=matrix(0,nrow=L,ncol=p),
           postvar = matrix(0,nrow=L,ncol=p), Xr=rep(0,n), sigma2= sigma2, sa2= sa2)

  for(i in 1:niter){
    s = update_each_effect(X, Y, s)
    if(calc_elbo){
      elbo[i] = elbo(X,Y,s)
    }
  }
  res = c(s,list(elbo=elbo))
  class(res) <- "susie"
  return(res)
}