#' Estimate Results Estimated for Multiple Dataset Replicates
#'
#' This function allows users to iteratively estimate a linear regression for a list of dataset replicates produced with the simdata() function.
#'
#' @param data A list of dataset replicates produced with simdata().
#' @param formula A formula object specifying the right- and left-hand side variables to be used in estimation.
#' @param vars A vector or single character string indicating the names of covariates to return results for.
#' @param estimator The estimator to be used for estimation. Default is estimatr::lm_robust.
#'
#' @return The function returns a tidy dataframe of estimates for each selected variable for each dataset replicate.
#'
#' @export
estimate <-
  function(
    data = NULL,
    formula,
    vars,
    estimator = estimatr::lm_robust
  ) {
    est <-
      data %>%
      purrr::map_dfr(
        ~ estimator(
          formula,
          data = .
        ) %>%
          estimatr::tidy() %>%
          dplyr::filter(
            .data$term %in% vars
          )
      ) %>%
      dplyr::mutate(
        sim = rep(1:length(data), each = dplyr::n() /
                    length(data)),
        term = factor(.data$term, levels = vars)
      )
    return(est)
  }
