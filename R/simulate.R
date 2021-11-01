#' Iteratively Simulate a Data-Generating Process
#'
#' This function allows users to generate a dataset much like they would using a call to tibble(). However, rather than generate only a single dataset, the function returns a list of multiple replicates of a dataset.
#'
#' @param R The number of replicates to produce for a dataset. Default is 200.
#' @param N The sample size. Default is 500.
#' @param ... User specified variables.
#'
#' @return The function returns a list of dataset replicates.
#'
#' @export
simulate <-
  function(
    R = 200,
    N = 500,
    ...
  ) {
    design <-
      function()
      {
        fabricatr::fabricate(
          N = N,
          ...
        ) %>% list()
      }
    rep <-
      replicate(
        n = R,
        expr = design()
      )
    for(i in 1:length(rep)) rep[[i]] <- rep[[i]] %>%
      mutate(sim = i)
    return(rep)
  }
