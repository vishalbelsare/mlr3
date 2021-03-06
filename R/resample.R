#' @title Resample a Learner on a Task
#'
#' @description
#' Runs a resampling (possibly in parallel).
#'
#' @param task ([Task])\cr
#'   Object of type [Task].
#' @param learner ([Learner])\cr
#'   Object of type [Learner].
#' @param resampling ([Resampling])\cr
#'   Object of type [Resampling].
#' @param measures ([`list` of [Measure])\cr
#'   List of objects of type [Measure].
#' @return [ResampleResult].
#' @export
resample = function(task, learner, resampling, measures) {
  assert_task(task)
  assert_learner(learner, task = task)
  assert_resampling(resampling)
  measures = as_measures(measures, task = task)

  if (resampling$is_instantiated) {
    instance = resampling$clone() # FIXME: clone
  } else {
    instance = resampling$instantiate(task) # FIXME: clone
  }
  n = instance$iters

  res = future.apply::future_lapply(seq_len(n), function(i, task, learner, instance, measures) {
    train_set = instance$train_set(i)
    test_set = instance$test_set(i)
    experiment_worker(task = task, learner = learner,  train_set = train_set, test_set = test_set, measures = measures)
  }, future.globals = FALSE, future.packages = "mlr3", task = task, learner = learner, instance = instance, measures = measures)


  res = combine_experiments(res)
  res[, c("task", "learner", "resampling", "iteration") := list(list(task), list(learner), list(instance), seq_len(n))]
  ResampleResult$new(res)
}


#' @title ResampleResult
#' @format [R6Class()] object
#'
#' @description
#' A [R6::R6Class()] containing data of a [resample()].
#'
#' @field aggr (`named numeric`): Aggregated performance measures.
#' @field data [`data.table`]: Data stored in a tabular format.
ResampleResult = R6Class("ResampleResult",
  cloneable = FALSE,
  public = list(
    data = NULL,

    initialize = function(data) {
      assert_data_table(data)
      slots = capabilities$experiment_slots$name
      assert_names(names(data), permutation.of = slots)
      self$data = setcolorder(data, slots)[]
    },

    print = function(...) {
      catf("ResamplingResult of learner '%s' on task '%s' with %i iterations", self$task$id, self$learner$id, nrow(self$data))
      # vapply(self$performance[, !"iteration"], function(x) c(mean(x), sd(x)))
      # ... TBC
    },

    experiment = function(iteration) {
      iteration = asInt(iteration, lower = 1L, upper = nrow(self$data))
      .mapply(Experiment$new, self$data[iteration], MoreArgs = list())[[1L]]
    },

    experiments = function(iterations) {
      iterations = asInteger(iterations, lower = 1L, upper = nrow(self$data), any.missing = FALSE)
      .mapply(Experiment$new, self$data[iterations], MoreArgs = list())
    }

  ),

  active = list(
    performance = function() {
      perf = rbindlist(lapply(self$data$performance, as.list), fill = TRUE)
      cbind(data.table(iteration = seq_row(self$data)), perf)
    },

    task = function() {
      self$data$task[[1L]]
    },

    learner = function() {
      self$data$learner[[1L]]
    },

    resampling = function() {
      self$data$resampling[[1L]]
    },

    measures = function() {
      names(self$data$performance[[1L]])
    }
  )
)
