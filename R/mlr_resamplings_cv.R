#' @include Resampling.R
ResamplingCV = R6Class("ResamplingCV", inherit = Resampling,
  public = list(
    id = "cv",
    folds = 10L,
    instantiate = function(task, ...) {
      # inner function so we can easily implement blocking here
      # -> replace ids with unique values of blocking variable
      # -> join ids using blocks
      cv = function(ids, folds) {
        data.table(
          row_id = ids,
          fold = shuffle(seq_along0(ids) %% folds + 1L),
          key = "fold"
        )
      }
      assert_task(task)
      private$instance = cv(task$row_ids(), asInt(self$folds, lower = 1L))
      self
    },

    train_set = function(i) {
      i = assert_resampling_index(self, i)
      private$instance[!.(i), "row_id", on = "fold"][[1L]]
    },

    test_set = function(i) {
      i = assert_resampling_index(self, i)
      private$instance[.(i), "row_id", on = "fold"][[1L]]
    }
  ),

  active = list(
    iters = function() {
      self$folds
    }
  )
)

mlr_resamplings$add(
  ResamplingCV$new()
)
