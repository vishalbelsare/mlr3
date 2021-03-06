context("TaskRegr")

test_that("Basic ops on BostonHousing task", {
  task = mlr_tasks$get("bh")
  expect_task(task)
  expect_task_supervised(task)
  expect_task_regr(task)
  expect_equal(task$target_names, "medv")

  f = task$formula
  expect_class(f, "formula")
  expect_set_equal(attr(terms(f), "term.labels"), task$feature_names)
})
