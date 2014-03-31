\name{lda_pseudo}
\alias{lda_pseudo}
\alias{lda_pseudo.default}
\alias{lda_pseudo.formula}
\alias{predict.lda_pseudo}
\alias{print.lda_pseudo}
\title{Linear Discriminant Analysis (LDA) with the Moore-Penrose Pseudo-Inverse}
\usage{
lda_pseudo(x, ...)

\method{lda_pseudo}{default}(x, y, prior = NULL, tol = 1e-08, ...)

\method{lda_pseudo}{formula}(formula, data, prior = NULL, tol = 1e-08, ...)

\method{print}{lda_pseudo}(x, ...)

\method{predict}{lda_pseudo}(object, newdata, ...)
}
\arguments{
  \item{x}{matrix containing the training data. The rows
  are the sample observations, and the columns are the
  features.}

  \item{y}{vector of class labels for each training
  observation}

  \item{prior}{vector with prior probabilities for each
  class. If NULL (default), then equal probabilities are
  used. See details.}

  \item{tol}{tolerance value below which eigenvalues are
  considered numerically equal to 0}

  \item{formula}{A formula of the form \code{groups ~ x1 +
  x2 + ...} That is, the response is the grouping factor
  and the right hand side specifies the (non-factor)
  discriminators.}

  \item{data}{data frame from which variables specified in
  \code{formula} are preferentially to be taken.}

  \item{x}{object to print}

  \item{...}{unused}

  \item{object}{trained lda_pseudo object}

  \item{newdata}{matrix of observations to predict. Each
  row corresponds to a new observation.}

  \item{...}{additional arguments}
}
\value{
\code{lda_pseudo} object that contains the trained
lda_pseudo classifier

list predicted class memberships of each row in newdata
}
\description{
Given a set of training data, this function builds the
Linear Discriminant Analysis (LDA) classifier, where the
distributions of each class are assumed to be multivariate
normal and share a common covariance matrix. When the
pooled sample covariance matrix is singular, the linear
discriminant function is incalculable. A common method to
overcome this issue is to replace the inverse of the pooled
sample covariance matrix with the Moore-Penrose
pseudo-inverse, which is unique and always exists. Note
that when the pooled sample covariance matrix is
nonsingular, it is equal to the pseudo-inverse.

Summarizes the trained lda_pseudo classifier in a nice
manner.

The Linear Discriminant Analysis (LDA) classifier involves
the assumption that the distributions of each class are
assumed to be multivariate normal and share a common
covariance matrix. When the pooled sample covariance matrix
is singular, the linear discriminant function is
incalculable. A common method to overcome this issue is to
replace the inverse of the pooled sample covariance matrix
with the Moore-Penrose pseudo-inverse, which is unique and
always exists. Note that when the pooled sample covariance
matrix is nonsingular, it is equal to the pseudo-inverse.
}
\details{
The matrix of training observations are given in \code{x}.
The rows of \code{x} contain the sample observations, and
the columns contain the features for each training
observation.

The vector of class labels given in \code{y} are coerced to
a \code{factor}. The length of \code{y} should match the
number of rows in \code{x}.

An error is thrown if a given class has less than 2
observations because the variance for each feature within a
class cannot be estimated with less than 2 observations.

The vector, \code{prior}, contains the \emph{a priori}
class membership for each class. If \code{prior} is NULL
(default), the class membership probabilities are estimated
as the sample proportion of observations belonging to each
class. Otherwise, \code{prior} should be a vector with the
same length as the number of classes in \code{y}. The
\code{prior} probabilties should be nonnegative and sum to
one.
}
\examples{
n <- nrow(iris)
train <- sample(seq_len(n), n / 2)
lda_pseudo_out <- lda_pseudo(Species ~ ., data = iris[train, ])
predicted <- predict(lda_pseudo_out, iris[-train, -5])$class

lda_pseudo_out2 <- lda_pseudo(x = iris[train, -5], y = iris[train, 5])
predicted2 <- predict(lda_pseudo_out2, iris[-train, -5])$class
all.equal(predicted, predicted2)
}
\keyword{internal}
