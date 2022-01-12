# seerrr <img src="inst/logo.png" align="right" height="130" />

![R-version](https://img.shields.io/badge/R%20%3E%3D-3.4.3-brightgreen)
![updated](https://img.shields.io/badge/last%20update-01--12--2022-brightgreen)
![version](https://img.shields.io/badge/version-0.0.1.2100-brightgreen)
![license](https://img.shields.io/badge/license-MIT-red)
![encoding](https://img.shields.io/badge/encoding-UTF--8-red)
[![orchid](https://img.shields.io/badge/ORCID-0000--0003--0192--5542-brightgreen)](https://orcid.org/0000-0003-0192-5542)

`seerrr` is a package that supports Monte Carlo and computational power analysis in R. 


### Updates

  - As of 10/01/2021, it has been updated to also support direct estimation of minimum detectable effects (MDEs) and for evaluating the bias, mean squared error (MSE), coverage, and power of an estimator. 
  - As of 10/15/2021, `estimate()` is now set up to pass any additional user specified commands to the selected estimator function.
  - As of 01/12/2022, `evaluate()` returns a richer variety of diagnostics when `what = "bias"`, and it allows for different user-specified true parameter values per each parameter of interest.
  
# Introduction

The package is constructed around a simple work-flow:

  1. Simulate
  2. Estimate
  3. Evaluate

Hence, the same *see*rrr. 

# Installation
There is currently only a development version of `seerrr` available. To install and attach the package, simply write:

    devtools::install_github("milesdwilliams15/seerrr")
    library(seerrr)

# Usage
To perform power analysis with `seerrr`, the package provides users with three functions:

  - `simulate()`[^1]
  - `estimate()`
  - `evaluate()`
  
[^1]: Note that `simulate()` was previously `simdata()`.

The first, `simulate()`, generates a list of dataset replicates. It is a wrapper for the `fabricate()` function in the `fabricatr` package, which is part of the `DeclareDesign` universe of R packages. To use `simulate()`, simply specify the number of replicates of a dataset you would like to produce, the sample size, and the variables you'd like to include. For example,

    sims <-
      simulate(
        R = 100,
        N = 100,
        y = rnorm(n = N, mean = 0, sd = 1),
        x = rbinom(n = N, size = 1, prob = 0.5)
      )
    sims # print results
    #   [[1]]
    #     ID            y x
    #     1  1 -0.8591237 1
    #     2  2  0.9053669 1
    #     3  3  0.1507227 1
    #     4  4 -1.3261642 1
    #     5  5 -0.8358375 1
    #  
    #  [[2]]
    #    ID           y x
    #    1  1 0.9431161 0
    #    2  2 2.1052679 1
    #    3  3 1.2492730 1
    #    4  4 1.5075754 0
    #    5  5 0.7769822 1

The object `sims` is just a list of `R = 100` datasets.

After simulating the data, one can then use `estimate()` to generate a distribution of estimates for the effect of `x` on `y`. Since by design there is no relationship (both are just random variables), `estimate()` provides us with a distribution of effects under the null hypothesis of no effect. 

    ests <-
      estimate(
        data = sims,
        y ~ x,
        vars = "x"
      )
    head(ests) # view first 6 rows of results
    #   term estimate std.error statistic p.value conf.low conf.high df outcome sim
    # 1    x  0.23793     0.195    1.2215   0.225   -0.149     0.624 98       y   1
    # 2    x -0.11482     0.201   -0.5707   0.570   -0.514     0.284 98       y   2
    # 3    x -0.00492     0.185   -0.0266   0.979   -0.372     0.362 98       y   3
    # 4    x  0.11835     0.194    0.6103   0.543   -0.266     0.503 98       y   4
    # 5    x -0.03118     0.169   -0.1849   0.854   -0.366     0.303 98       y   5
    # 6    x -0.10802     0.200   -0.5410   0.590   -0.504     0.288 98       y   6

By default, `estimate()` relies on `lm_robust()` from the `estimatr` package. An alternative estimation technique can be specified by the user if desired. For example, if you'd just like to use `lm`, you would specify:

    estimate(
        data = sims,
        y ~ x,
        vars = "x",
        estimator = lm
      )

Or, if you would like to modify any of the default settings of `lm_robust`---say you want to change the standard errors to HC1 errors rather than the default HC2---you can simply include that command in `estimate()` and it will pass that command to the estimator function. In `lm_robust` to get HC1 standard errors we simply set `se_type = "stata"`. By specifying this in `estimate` this command gets passed to `lm_robust` "under the hood":

    estimate(
        data = sims,
        y ~ x,
        vars = "x",
        se_type = "stata"
      )

With a distribution of estimates under the null now estimated, we can compute power over a range of possible effect sizes with the `evaluate()` function. This is done by supplying a vector of alternative effect sizes to the `delta` argument:

    effs <- seq(0, 1, by = 0.1)
    pwr <- evalutate(
      data = ests,
      delta = effs
    )
    pwr # look at output
    # # A tibble: 11 x 3
    #    term  delta power
    #    <fct> <dbl> <dbl>
    #  1 x       0    0.05
    #  2 x       0.1  0.06
    #  3 x       0.2  0.23
    #  4 x       0.3  0.38
    #  5 x       0.4  0.52
    #  6 x       0.5  0.69
    #  7 x       0.6  0.8
    #  8 x       0.7  0.93
    #  9 x       0.8  0.99
    # 10 x       0.9  1   
    # 11 x       1    1   

The output denotes the calculated power to reject the null hypotheses when the true effect is the effect noted by `delta`. These results can then be easily plotted, used to compute minimum detectable effects, etc. By default, `evaluate()` sets the level of the test for rejecting the null to `level = 0.05`. If you'd like to set a more restrictive, or more modest level, simply specify `level = 0.01` or `level = 0.1` respectively.

In the latest version of `seerrr`, `evaluate()` also supports two new tasks: (1) direct computation of the MDE and (2) summary statistics of the estimator's performance. The former provides a useful shortcut for users to specify an MDE without having to directly identify one from the raw output of `evaluate()`. The latter is helpful for individuals who aren't merely interested in computing power but would like to assess the overall performance of a design, model specification, or estimator---or generally have an interest in doing a Monte Carlo analysis.

## Getting the MDE

To identify the MDE simply specify `what = "mde"`. `evaluate()` will then return the MDE at the user specified level of power for each relevant term:

    evaluate(
      est,
      delta = seq(0, 1, 0.05), # range and granularity over which to search
      what = "mde"
    )
    # # A tibble: 1 x 3
    #   term    mde power
    #   <fct> <dbl> <dbl>
    # 1 x      0.15   0.8

This is basically a brute force search over the parameter space of `delta`. How wide or granular the search is determined by the range of values specified for `delta`.

## Monte Carlo

To assess the performance of an estimator, we simply specify `what = "bias"` in evaluate. Say for instance we wanted to assess our ability to correctly identify a true positive effect of `x` on `y` where the true effect size is 1. We would simulate, estimate, and evaluate as follows:

    sim <- simulate(
      x = rnorm(N),
      y = x + rnorm(N)
    )
    est <- estimate(
      sim,
      y ~ x,
      "x"
    )
    evl <- evaluate(
      est,
      what = "bias",
      truth = 1
    )
    evl # print
    # A tibble: 2 x 9
    #  term  true.value  average variance std.error     bias     mse coverage power
    #  <fct>      <dbl>    <dbl>    <dbl>     <dbl>    <dbl>   <dbl>    <dbl> <dbl>
    #1 x              1  0.998    0.00174    0.0448 -0.00250 0.00174     0.97  1   

With `what = "bias"`, `evaluate()` will return:

  1. The user-supplied truth value of the parameter of interest;
  2. The average of parameter estimates produced from the simulation;
  3. The variance of the simulated parameter estimates;
  4. The average standard error of the parameter estimate across simulations;
  5. The average bias of the parameter relative to its true value;
  6. The mean squared error of the parameter relative to its true value;
  7. The coverage of the 95 percent confidence intervals with the true parameter value;
  8. The power, or proportion of times the null is rejected.

A convenient addition to the `"bias"` option in `evaluate()` is that it is now possible to specify a different truth value for multiple parameters if more than one is of interest. For example:

    sim <- simulate(
      x = rnorm(N),
      z = rnorm(N),
      y = x + 2 * z + rnorm(N)
    )
    est <- estimate(
      sim,
      y ~ x + z,
      "x"
    )
    evl <- evaluate(
      est,
      what = "bias",
      truth = c(1, 2)
    )
    evl # print
    # A tibble: 2 x 9
    #  term  true.value average variance std.error     bias     mse coverage power
    #  <fct>      <dbl>   <dbl>    <dbl>     <dbl>    <dbl>   <dbl>    <dbl> <dbl>
    #1 x              1   0.998  0.00201    0.0451 -0.00236 0.00201    0.96      1
    #2 z              2   2.00   0.00251    0.0450 -0.00181 0.00250    0.915     1

Here, we've added a second predictor variable, `z`, and set its true parameter value to `2`. We can return summary statistics for both `x` and `z` given their true values, `truth = c(1, 2)`.

# Summary

`seerrr` is not a revolutionary package, but it is a useful one. It streamlines the process of doing a Monte Carlo or computational power analysis by outsourcing much of the programming required for such analyses to its workhorse functions. This frees the analyst to focus on the specifics of the d.g.p., model specification, and inference strategy. Whatever one can conceive of, `seerrr` will help you "see all." 
