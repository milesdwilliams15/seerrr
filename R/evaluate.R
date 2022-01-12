#' Evaluate Power for Select Variables
#'
#' This function allows users to specify power to detect effects for select variables over a range of hypothetical effect sizes.
#'
#' @param data The output from estimate().
#' @param delta A numeric vector of effect sizes over which to calculate power. If `what = "mde"` this is the range over which the minimum detectable effect (MDE) is computed. If the MDE lies outside this range, an error message is returned.
#' @param level The level of the statistical test. Default is 0.05.
#' @param power The desired power to detect an effect. Default is 0.8.
#' @param what A character string indicating what to evaluate. By default `"power"` is evaluated. Other options include `"mde"` for the minimum detectable effect (MDE) and `"bias"` for evaluating the performance of an estimator with respect to average bias, coverage, power, and mean squared error.
#' @param truth If `what = "bias"`, performance is evaluated relative to the true parameter estimate. This is an integer value and is 0 by default.
#'
#' @return Returns computed power for each variable of interest over the range of use-specified effect sizes.
#'
#' @export
evaluate <-
  function(
    data,
    delta,
    level = 0.05,
    power = 0.8,
    what = "power",
    truth = 0
  ) {
    if(what != "bias") {
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
    }
    if(what == "power") {
      return(pwr)
    } else if(what == "mde") {
      power_level <- power
      mde <- pwr %>%
        dplyr::group_by(.data$term) %>%
        dplyr::summarize(
          mde = min(.data$delta[.data$power >= power_level]),
          power = power_level,
          .groups = "drop"
        )
      return(mde)
    } else if(what == "bias") {
      if(truth > 0) {
        if(length(truth)!=length(unique(data$term))) {
          print("True values of parameters does not match the number of parameters.")
          stop()
        }
      }
      bias <- data %>%
        dplyr::mutate(
          truth = rep(truth, len = dplyr::n())
        ) %>%
        dplyr::group_by(.data$term) %>%
        dplyr::summarize(
          average = mean(.data$estimate),
          variance = var(.data$estimate),
          std.error = mean(.data$std.error),
          bias = mean(.data$estimate - truth),
          mse = mean((.data$estimate - truth)^2),
          coverage = mean(
            ((.data$estimate - 1.96 * .data$std.error) <= truth) &
              ((.data$estimate + 1.96 * .data$std.error) >= truth)
          ),
          power = mean(.data$p.value <= level),
          .groups = "drop"
        )
      return(bias)
    }
  }
