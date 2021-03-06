#' @title Base Class for Dictionaries
#' @format [R6Class()] object
#'
#' @description
#' A [R6::R6Class()] for a simple dictionary (hash map).
#' This is used to store objects like [mlr_tasks], [mlr_learners],
#' [mlr_resamplings] or [mlr_measures].
#'
#' @field ids Returns the ids of registered learners.
#' @field env Environment where all [Learner()] objects are stored.
#' @section Methods:
#' \describe{
#'  \item{`add(obj, id, overwrite)`}{Add an object to the dictionary.}
#'  \item{`contains(ids)`}{Returns a logical vector signaling if objects with the respective id are stored inside the Dictionary.}
#'  \item{...}{...}
#' }
#'
#' @return [`Dictionary`].
Dictionary = R6Class("Dictionary",
  cloneable = FALSE,

  public = list(
    items = NULL,
    contains = NULL,

    # construct, set container type (string)
    initialize = function(contains) {
      self$contains = assert_character(contains, min.len = 1L, any.missing = FALSE, min.chars = 1L)
      self$items = new.env(parent = emptyenv())
    },

    add = function(value) {
      if (!inherits(value, "LazyValue"))
        assert_class(value, class = self$contains)
      assign(x = value$id, value = value, envir = self$items)
    },

    get = function(id, ...) {
      set_values = function(x, ...) {
        if (...length()) {
          dots = list(...)
          nn = names(dots)
          for (i in seq_along(dots)) {
            x[[nn[i]]] = dots[[i]]
          }
        }
        x
      }
      assert_string(id)
      if (!hasName(self$items, id))
        stopf("%s with id '%s' not found!", self$contains, id)
      x = private$retrieve(get(id, envir = self$items, inherits = FALSE))
      set_values(x, ...)
    },

    mget = function(ids) {
      assert_character(ids, any.missing = FALSE)
      missing = !hasName(self$items, ids)
      if (any(missing))
        stopf("%s with id '%s' not found!", self$contains, ids[wf(missing)])
      lapply(mget(ids, envir = self$items, inherits = FALSE), private$retrieve)
    },

    remove = function(id) {
      assert_string(id)
      if (!hasName(self$items, id))
        stopf("%s with id '%s' not found!", self$contains, id)
      rm(list = id, envir = self$items)
      invisible(self)
    }
  ),

  active = list(
    ids = function() ls(self$items, all.names = TRUE),
    length = function() length(self$items)
  ),

  private = list(
    retrieve = function(value) {
      if (inherits(value, "LazyValue")) value$getter() else value$clone()
    }
  )
)


LazyValue = function(id, getter) {
  obj = list(id = assert_string(id), getter = assert_function(getter))
  class(obj) = "LazyValue"
  obj
}
