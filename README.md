# seerrr <img src="inst/logo.png" align="right" height="130" />

![R-version](https://img.shields.io/badge/R%20%3E%3D-3.4.3-brightgreen)
![updated](https://img.shields.io/badge/last%20update-10--01--2021-brightgreen)
![version](https://img.shields.io/badge/version-0.0.1.2100-brightgreen)
![license](https://img.shields.io/badge/license-MIT-red)
![encoding](https://img.shields.io/badge/encoding-UTF--8-red)
[![orchid](https://img.shields.io/badge/ORCID-0000--0003--0192--5542-brightgreen)](https://orcid.org/0000-0003-0192-5542)

`seerrr` is a package that supports computational power analysis in R. 


### Updates

  - As of 10/01/2021, it has been updated to also support direct estimation of minimum detectable effects (MDEs) and for evaluating the bias, mean squared error (MSE), coverage, and power of an estimator. 
  - As of 10/15/2021, `estimate()` is now set up to pass any additional user specified commands to the selected estimator function.

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

In the latest version of `seerrr`, `evaluate()` also supports two new tasks: (1) direct computation of the MDE and (2) summary statistics of the estimator's performance. The former provides a useful shortcut for users to specify an MDE without having to directly identify one from the raw output from `evaluate()`. The latter is helpful for individuals who aren't merely interested in computing power but would like to assess the overall performance of a design, model specification, or estimator.

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
    # # A tibble: 1 x 5
    #   term        bias     mse coverage power
    #   <fct>      <dbl>   <dbl>    <dbl> <dbl>
    # 1 x     -0.0000749 0.00214    0.954     1

With `what = "bias"`, `evaluate()` now returns the average bias of the estimate for `x`, MSE, coverage (proportion of times the 95 percent CIs overlap with the true effect size), and power to detect the true effect.


# Summary

The power of a computational approach and the specific set of tools provided by `seerrr` is that it permits specifying and computing power for a diverse array of complex designs and data-generating processes without constraining the analyst to a particular set of analytical distributional assumptions as imposed by other existing approaches in `R`. Whatever one can conceive of, `seerrr` "sees all." 
