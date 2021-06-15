#' Evaluate Power for Select Variables
#'
#' This function allows users to specify power to detect effects for select variables over a range of hypothetical effect sizes.
#'
#' @param data The output from estimate().
#' @param delta A numeric vector of effect sizes over which to calculate power.
#' @param level The level of the statistical test. Default is 0.05.
#'
#' @return Returns computed power for each variable of interest over the range of use-specified effect sizes.
#'
#' @export
evaluate <-
  function(
    data,
    delta,
    level = 0.05
  ) {
    pwr <- foreach::foreach(
      i = 1:length(delta)
    ) %do% {
      data %>%
        dplyr::mutate(
          delta = delta[i],
          new_stat =
            (.data$estimate + .data$delta) /
            .data$std.error
        ) %>%
        dplyr::group_split(
          .data$term
        ) %>%
        purrr::map(
          ~ {
            tibble::tibble(
              term = .$term,
              delta = .$delta,
              p.value = foreach(
                j = 1:length(.$new_stat),
                .combine = "c"
              ) %do% mean(abs(.$statistic) >=
                            abs(.$new_stat[j]))
            )
          }
        )
    } %>%
      dplyr::bind_rows() %>%
      dplyr::group_by(
        .data$term,
        .data$delta
      ) %>%
      dplyr::summarise(
        power = mean(.data$p.value <= level),
        .groups = "drop"
      )
    return(pwr)
  }
