#' Linear Discriminant Analysis using the Schafer-Strimmer Covariance Matrix
#' Estimator
#'
#' Given a set of training data, this function builds the Linear Discriminant
#' Analysis (LDA) classifier, where the distributions of each class are assumed
#' to be multivariate normal and share a common covariance matrix. When the
#' pooled sample covariance matrix is singular, the linear discriminant function
#' is incalculable. This function replaces the inverse of pooled sample
#' covariance matrix with an estimator proposed by Schafer and Strimmer
#' (2005). The estimator is calculated via [corpcor::invcov.shrink()].
#'
#' The matrix of training observations are given in `x`. The rows of `x`
#' contain the sample observations, and the columns contain the features for each
#' training observation.
#'
#' The vector of class labels given in `y` are coerced to a `factor`.
#' The length of `y` should match the number of rows in `x`.
#'
#' An error is thrown if a given class has less than 2 observations because the
#' variance for each feature within a class cannot be estimated with less than 2
#' observations.
#'
#' The vector, `prior`, contains the _a priori_ class membership for
#' each class. If `prior` is NULL (default), the class membership
#' probabilities are estimated as the sample proportion of observations belonging
#' to each class. Otherwise, `prior` should be a vector with the same length
#' as the number of classes in `y`. The `prior` probabilities should be
#' nonnegative and sum to one.
#'
#' @importFrom corpcor cov.shrink invcov.shrink
#' @export
#'
#' @inheritParams lda_diag
#' @param ... Options passed to [corpcor::invcov.shrink()]
#' @return `lda_schafer` object that contains the trained classifier
#' @examples
#' library(modeldata)
#' data(penguins)
#' pred_rows <- seq(1, 344, by = 20)
#' penguins <- penguins[, c("species", "body_mass_g", "flipper_length_mm")]
#' lda_schafer_out <- lda_schafer(species ~ ., data = penguins[-pred_rows, ])
#' predicted <- predict(lda_schafer_out, penguins[pred_rows, -1], type = "class")
#'
#' lda_schafer_out2 <- lda_schafer(x = penguins[-pred_rows, -1], y = penguins$species[-pred_rows])
#' predicted2 <- predict(lda_schafer_out2, penguins[pred_rows, -1], type = "class")
#' all.equal(predicted, predicted2)
#' @references Schafer, J., and Strimmer, K. (2005). "A shrinkage approach to
#' large-scale covariance estimation and implications for functional genomics,"
#' Statist. Appl. Genet. Mol. Biol. 4, 32.
lda_schafer <- function(x, ...) {
  UseMethod("lda_schafer")
}

#' @rdname lda_schafer
#' @export
lda_schafer.default <- function(x, y, prior = NULL, ...) {
  x <- pred_to_matrix(x)
  y <- outcome_to_factor(y)
  complete <- complete.cases(x) & complete.cases(y)
  x <- x[complete,,drop = FALSE]
  y <- y[complete]

  obj <- regdiscrim_estimates(x = x, y = y, prior = prior, cov = FALSE)

  # Centers the data matrix from each class and then estimates the lda_schafer
  # precision matrix
  x_centered <- tapply(seq_along(y), y, function(i) {
    scale(x[i, ], center = TRUE, scale = FALSE)
  })
  x_centered <- do.call(rbind, x_centered)
  obj$cov_pool <- cov.shrink(x_centered, verbose = FALSE, ...)
  obj$cov_inv <- invcov.shrink(x_centered, verbose = FALSE, ...)

  # The `corpcor` package returns a `shrinkage` object, which is actually a
  # matrix with some attributes.
  # Coerces the classes to avoid conflicts downstream.
  class(obj$cov_pool) <- "matrix"
  class(obj$cov_inv) <- "matrix"

  # Creates an object of type 'lda_schafer'
  obj$col_names <- colnames(x)
  obj <- new_discrim_object(obj, "lda_schafer")

  obj
}

#' @inheritParams lda_diag
#' @rdname lda_schafer
#' @importFrom stats model.frame model.matrix model.response
#' @export
lda_schafer.formula <- function(formula, data, prior = NULL, ...) {
  # The formula interface includes an intercept. If the user includes the
  # intercept in the model, it should be removed. Otherwise, errors and doom
  # happen.
  # To remove the intercept, we update the formula, like so:
  # (NOTE: The terms must be collected in case the dot (.) notation is used)
  formula <- no_intercept(formula, data)

  mf <- model.frame(formula = formula, data = data)
  .terms <- attr(mf, "terms")
  x <- model.matrix(.terms, data = mf)
  y <- model.response(mf)

  est <- lda_schafer.default(x = x, y = y, prior = prior)
  est$.terms <- .terms
  est <- new_discrim_object(est, class(est))
  est
}

#' Outputs the summary for a lda_schafer classifier object.
#'
#' Summarizes the trained lda_schafer classifier in a nice manner.
#'
#' @inheritParams print.lda_diag
#' @keywords internal
#' @export
print.lda_schafer <- function(x, ...) {
  cat("LDA using the Schafer-Strimmer Covariance Matrix Estimator\n\n")
  print_basics(x, ...)
  invisible(x)
}

#' Predicts of class membership of a matrix of new observations using Linear
#' Discriminant Analysis (LDA) using the Schafer-Strimmer Covariance Matrix
#' Estimator
#'
#' The Linear Discriminant Analysis (LDA) classifier involves the assumption
#' that the distributions of each class are assumed to be multivariate normal
#' and share a common covariance matrix. When the pooled sample covariance
#' matrix is singular, the linear discriminant function is incalculable. Here,
#' the inverse of the pooled sample covariance matrix is replaced with an
#' estimator from Schafer and Strimmer (2005).
#'
#' @rdname lda_schafer
#' @export
#' @inheritParams predict.lda_diag

predict.lda_schafer <- function(object, newdata, type = c("class", "prob", "score"), ...) {
  type <- rlang::arg_match0(type, c("class", "prob", "score"), arg_nm = "type")
  newdata <- process_newdata(object, newdata)

  # Calculates the discriminant scores for each test observation
  scores <- apply(newdata, 1, function(obs) {
    sapply(object$est, function(class_est) {
      with(class_est, quadform(object$cov_inv, obs - xbar) + log(prior))
    })
  })
  
  if (type == "prob") {
    # Posterior probabilities via Bayes Theorem
    means <- lapply(object$est, "[[", "xbar")
    covs <- replicate(n=object$num_groups, object$cov_pool, simplify=FALSE)
    priors <- lapply(object$est, "[[", "prior")
    res <- posterior_probs(x = newdata, means = means, covs = covs, priors = priors)
    res <- as.data.frame(res)
    
  } else if (type == "class") {
    res <- score_to_class(scores, object)
  } else {
    res <- t(scores)
    res <- as.data.frame(res)
  }
  res
}
