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
The `seerrr` package centers on three functions:

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

After simulating the data, one can then use `estimate()` to generate a distribution of estimates for the effect of `x` on `y` based on each of the sample replicates:

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

Or, if you would like to modify any of the default settings of `lm_robust`---say you want to change the standard errors to HC1 errors rather than the default HC2---you can simply include that command in `estimate()` and it will pass that command to the estimator function. For example, to specify that we'd like `lm_robust` to report HC1 standard errors we would write:

    estimate(
        data = sims,
        y ~ x,
        vars = "x",
        se_type = "stata" # stata = HC1
      )

## Types of Evaluation
The next function in the `seerrr` workflow, `evaluate()`, can be used to return different summary information depending on the goal of the analysis.

### Power Analysis 
For instance, if power analysis is the goal, begin by simulating a distribution of estimates under the null:

      sims <- simulate(
         R = 100,
         N = 100,
         x = rnorm(N),
         y = 0 * x + rnorm(N)
       )
      
In the above, I've multiplied `x` by zero to be explicit that I'm imposing a null relationship between `x` and `y` in the data generating process (d.g.p.). It's necessary to set up the d.g.p. in this way because when we pass estimates to the `evaluate()` function it assumes that the true relationship between an explanatory variable and an outcome is zero.

The next step is to estimate:

      ests <- estimate(
        data = sims,
        y ~ x,
        vars = "x"
      )

Finally, we can compute power over a range of possible effect sizes with the `evaluate()` function. By default, the function will assume you want to do a power analysis, in which case it returns power over a range of user-specified non-zero effect sizes. This is done by supplying a vector of alternative effect sizes to the `delta` argument:

    effs <- seq(0, 1, by = 0.1) # vector of effect sizes
    pwr <- evalutate(
      data = ests, # the dataframe of estimates (assumes truth is zero)
      delta = effs # the vector of effect sizes
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

The output shows the calculated power to reject the null hypothesis when the true effect is the effect noted by `delta`. 

Since the output is a `tibble`, one can seamlessly plot these results or perform other operations on the output.

By default, `evaluate()` sets the level of the test for rejecting the null to `level = 0.05`. If you'd like to set a more restrictive, or more modest level, you could specify `level = 0.01` or `level = 0.1` respectively. The `level` option will accept any real valued number between 0 and 1.

### Getting the MDE

The above approach is useful for computing power curves but not so efficient for finding the minimum detectable effect (MDE). Thankfully, by specifying `what = "mde"` `evaluate()` will find and return the MDE at the user specified level of power for you:

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


### Monte Carlo

Sometimes a user may have a more general simulation exercise in mind. This might be related research on the behavior of a specific estimator, understanding the role of bias, or for illustration in a statistics course. 

To generally assess the performance of an estimator, we simply specify `what = "bias"` in evaluate. Say for instance we want to assess our ability to correctly identify a true positive effect of `x` on `y` where the true effect size is 1. We would simulate, estimate, and evaluate as follows:

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

Here, we've added a second predictor variable, `z`, and set its true parameter value to `2` in the d.g.p. We then tell `evaluate()` the true values of each of the parameters of interest by setting `truth = c(1, 2)`. (Note that the order of values in the truth vector matters.)


## A Hypothetical Application

To demonstrate the usefulness of `seerrr`, consider a hypothetical classroom setting where an instructor would like to illustrate the consequences of omitted variable bias. 

An example can be easily contrived by specifying a d.g.p. where `y` is a function of `x` plus some "unobserved" variable `u`. In the set-up of the d.g.p., `x` is also a function of `u`:

    sim <- simulate(
      u = rnorm(N),        # unobserved confounder
      x = u + rnorm(N),    # predictor of interest
      y = x + u + rnorm(N) # the outcome
    )
    
Since this a simulation, we can compare how including versus not including `u` in our analysis affects our ability to estimate the true relationship between `x` and `y`:

    # with 'u' omitted:
    est.1 <- estimate(
      sim,
      y ~ x,
      vars = "x",
      se_type = "stata"
    )
    
    # with 'u' controlled for:
    est.2 <- estimate(
      sim,
      y ~ x + u,
      vars = "x",
      se_type = "stata"
    )
    
We can then evaluate both sets of estimates and compare the results:
    
    evl.1 <- evaluate(
      est.1,
      what = "bias",
      truth = 1
    )
    evl.2 <- evaluate(
      est.2,
      what = "bias",
      truth = 1
    )
    tibble(
      spec = c("'u' omitted", "'u' controlled for")
    ) %>%
      bind_cols(
        bind_rows(evl.1, evl.2)
      )
    # A tibble: 2 x 10
    #  spec               term  true.value average variance std.error     bias     mse coverage power
    #  <chr>              <fct>      <dbl>   <dbl>    <dbl>     <dbl>    <dbl>   <dbl>    <dbl> <dbl>
    #1 'u' omitted        x              1   1.49   0.00172    0.0387  0.494   0.246      0         1
    #2 'u' controlled for x              1   0.997  0.00233    0.0446 -0.00291 0.00232    0.925     1

The evaluation summary for each model specification clearly shows that failing to account for `u` leads to increased bias in the estimate of `x`'s relationship with `y`.

Simple enough!

# Summary

`seerrr` is not a revolutionary package, but it is a useful one. It streamlines the process of doing a Monte Carlo or computational power analysis by outsourcing much of the programming required for such analyses to its workhorse functions. This frees the analyst to focus on the specifics of the d.g.p., model specification, and inference strategy. Whatever one can conceive of, `seerrr` will help you "see all." 
