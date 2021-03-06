#' Diagonal Quadratic Discriminant Analysis (DQDA)
#'
#' Given a set of training data, this function builds the Diagonal Quadratic
#' Discriminant Analysis (DQDA) classifier, which is often attributed to Dudoit
#' et al. (2002). The DQDA classifier belongs to the family of Naive Bayes
#' classifiers, where the distributions of each class are assumed to be
#' multivariate normal. Note that the DLDA classifier is a special case of the
#' DQDA classifier.
#'
#' The DQDA classifier is a modification to the well-known QDA classifier, where
#' the off-diagonal elements of each class covariance matrix are assumed
#' to be zero -- the features are assumed to be uncorrelated. Under multivariate
#' normality, the assumption uncorrelated features is equivalent to the
#' assumption of independent features. The feature-independence assumption is a
#' notable attribute of the Naive Bayes classifier family. The benefit of these
#' classifiers is that they are fast and have much fewer parameters to estimate,
#' especially when the number of features is quite large.
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
#' @export
#'
#' @inheritParams lda_diag
#' @return `qda_diag` object that contains the trained DQDA classifier
#'
#' @references Dudoit, S., Fridlyand, J., & Speed, T. P. (2002). "Comparison of
#' Discrimination Methods for the Classification of Tumors Using Gene Expression
#' Data," Journal of the American Statistical Association, 97, 457, 77-87.
#' @examples
#' library(modeldata)
#' data(penguins)
#' pred_rows <- seq(1, 344, by = 20)
#' penguins <- penguins[, c("species", "body_mass_g", "flipper_length_mm")]
#' dqda_out <- qda_diag(species ~ ., data = penguins[-pred_rows, ])
#' predicted <- predict(dqda_out, penguins[pred_rows, -1], type = "class")
#'
#' dqda_out2 <- qda_diag(x = penguins[-pred_rows, -1], y = penguins$species[-pred_rows])
#' predicted2 <- predict(dqda_out2, penguins[pred_rows, -1], type = "class")
#' all.equal(predicted, predicted2)
qda_diag <- function(x, ...) {
  UseMethod("qda_diag")
}

#' @rdname qda_diag
#' @export
qda_diag.default <- function(x, y, prior = NULL, ...) {
  x <- pred_to_matrix(x)
  y <- outcome_to_factor(y)
  complete <- complete.cases(x) & complete.cases(y)
  x <- x[complete,,drop = FALSE]
  y <- y[complete]

  obj <- diag_estimates(x = x, y = y, prior = prior, pool = FALSE)

  # Creates an object of type 'qda_diag'
  obj$col_names <- colnames(x)
  obj <- new_discrim_object(obj, "qda_diag")

  obj
}

#' @inheritParams lda_diag
#' @rdname qda_diag
#' @importFrom stats model.frame model.matrix model.response
#' @export
qda_diag.formula <- function(formula, data, prior = NULL, ...) {
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

  est <- qda_diag.default(x = x, y = y, prior = prior)
  est$.terms <- .terms
  est <- new_discrim_object(est, class(est))
  est
}

#' Outputs the summary for a DQDA classifier object.
#'
#' Summarizes the trained DQDA classifier in a nice manner.
#'
#' @inheritParams print.lda_diag
#' @keywords internal
#' @export
print.qda_diag <- function(x, ...) {
  cat("Diagonal QDA\n\n")
  print_basics(x, ...)
  invisible(x)
}

#' DQDA prediction of the class membership of a matrix of new observations.
#'
#' The DQDA classifier is a modification to QDA, where the off-diagonal elements
#' of the pooled sample covariance matrix are set to zero.
#'
#' @rdname qda_diag
#' @export
#' @inheritParams predict.lda_diag

predict.qda_diag <- function(object, newdata, type = c("class", "prob", "score"), ...) {
  type <- rlang::arg_match0(type, c("class", "prob", "score"), arg_nm = "type")
  newdata <- process_newdata(object, newdata)

  scores <- apply(newdata, 1, function(obs) {
    sapply(object$est, function(class_est) {
      with(class_est, sum((obs - xbar)^2 / var + log(var)) + log(prior))
    })
  })
  
  if (type == "prob") {
    # Posterior probabilities via Bayes Theorem
    means <- lapply(object$est, "[[", "xbar")
    covs <- lapply(object$est, "[[", "var")
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
