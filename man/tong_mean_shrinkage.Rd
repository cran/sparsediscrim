% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tong-shrinkage.r
\name{tong_mean_shrinkage}
\alias{tong_mean_shrinkage}
\title{Tong et al. (2012)'s Lindley-type Shrunken Mean Estimator}
\usage{
tong_mean_shrinkage(x, r_opt = NULL)
}
\arguments{
\item{x}{a matrix with \code{n} rows and \code{p} columns.}

\item{r_opt}{the shrinkage coefficient. If \code{NULL} (default), we calculate
the shrinkage coefficient with the formula given just above Equation 5 on page
533 and denoted by \eqn{\hat{r}_{opt}}. We allow the user to specify an
alternative value to investigate better approximations.}
}
\value{
vector of length \code{p} with the shrunken mean estimator
}
\description{
An implementation of the Lindley-type shrunken mean estimator utilized in
shrinkage-mean-based diagonal linear discriminant analysis (SmDLDA).
}
\references{
Tong, T., Chen, L., and Zhao, H. (2012), "Improved Mean
Estimation and Its Application to Diagonal Discriminant Analysis,"
Bioinformatics, 28, 4, 531-537.
\url{https://academic.oup.com/bioinformatics/article/28/4/531/211887}
}
