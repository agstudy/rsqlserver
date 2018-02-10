context("Reading & Writing tables")

test_that("dbWriteTable/dbRemoveTable: Create a table and remove it using handy functions", {
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  if(dbExistsTable(conn, "T_MTCARS")){
    dbRemoveTable(conn, "T_MTCARS")
  }
  dbWriteTable(conn, name="T_MTCARS", mtcars)
  expect_true(dbExistsTable(conn, "T_MTCARS"))
  expect_true(dbRemoveTable(conn, "T_MTCARS"))
  expect_false(dbExistsTable(conn, "T_MTCARS"))
  expect_false(dbRemoveTable(conn, "T_MTCARS"))
})

test_that("dbReadTable: Return a significant message if a table is not found", {
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  expect_error(dbReadTable(conn, "TABLE_THAT_DOESNT_EXIST"), "Invalid object name")
})

test_that("dbReadTable: Reopen a connection if the connection is already closed", {
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  dbWriteTable(conn, name = "T_MTCARS", mtcars)
  dbDisconnect(conn)
  res <- dbReadTable(conn, "T_MTCARS")
  dbRemoveTable(conn, "T_MTCARS")
  expect_is(res, class = "data.frame")
})

test_that("dbGetScalar: Querying a temporary table", {
  on.exit(dbDisconnect(con))
  req <- "CREATE TABLE #TempTable(Test int)
          INSERT INTO #TempTable
          SELECT 2
          SELECT * FROM #TempTable
          DROP TABLE #TempTable"
  con <- get_con()
  res <- dbGetScalar(con, req)
  expect_equal(res, 2)
})

test_that("dbCreateTable: Create a table having SQL keywords as columns", {
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  cnames = c("key", "create", "table")
  cnames = make.db.names(conn, cnames, allow.keywords = FALSE)
  if(dbExistsTable(conn, "T_KEYWORDS")){
    dbRemoveTable(conn, "T_KEYWORDS")
  }
  dbCreateTable(conn, "T_KEYWORDS", cnames,
                ctypes = rep("varchar(3)", 3))
  expect_true(dbExistsTable(conn, "T_KEYWORDS"))
  dbRemoveTable(conn, "T_KEYWORDS")
})

test_that("Fetch: Get n rows from a table", {
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  dbWriteTable(conn, name = "T_MTCARS", mtcars, overwrite = TRUE)
  
  res <- dbSendQuery(conn, "SELECT mpg, cyl, wt FROM T_MTCARS")
  res.dat <- fetch(res, n = nrow(mtcars))
  invisible(dbClearResult(res))
  expect_is(res.dat, "data.frame")
  expect_equal(nrow(res.dat), nrow(mtcars))
  lapply(res.dat, expect_is, "numeric")
  
  dbRemoveTable(conn, "T_MTCARS")
})

test_that("dbGetQuery: Get some data from a table", {
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  dbWriteTable(conn, name = "T_MTCARS", mtcars, overwrite = TRUE)
  
  res <- dbGetQuery(conn, "SELECT mpg, cyl, wt FROM T_MTCARS")
  expect_is(res, "data.frame")
  expect_equal(nrow(mtcars), nrow(res))
  lapply(res, expect_is, "numeric")
  
  dbRemoveTable(conn, "T_MTCARS")
})

build_large_df <- function(size){
  set.seed(1)
  dat <- data.frame(value = sample(1:100, size, replace=TRUE),
                    key   = sample(letters, size, replace=TRUE),
                    stringsAsFactors = FALSE)
}

test_that("dbWriteTable: Use INSERT INTO on a large data.frame",{
  on.exit(dbDisconnect(conn))
  N <- 999
  dat <- build_large_df(size = N)
  conn <- get_con()
  dbWriteTable(conn, name = "T_BIG", value = dat, row.names = FALSE, overwrite = TRUE)
  expect_equal(dbExistsTable(conn, "T_BIG"), TRUE)
  dbRemoveTable(conn, "T_BIG")
})

test_that("dbWriteTable: Use BULK COPY on a large data.frame",{
  on.exit(dbDisconnect(conn))
  N <- 1000
  dat <- build_large_df(size = N)
  conn <- get_con()
  dbWriteTable(conn, name = "T_BIG", value = dat, row.names = FALSE, overwrite = TRUE)
  expect_equal(dbExistsTable(conn, "T_BIG"), TRUE)
  dbRemoveTable(conn, "T_BIG")
})

#TODO
# Currently not writing text missing values correctly.
test_that("Missing values: Write missing values",{
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  dat <- data.frame(txt = c("a", NA, "b", NA),
                    value = c(1L, NA, NA, 2L),
                    stringsAsFactors = FALSE)
  conn <- get_con()
  dbWriteTable(conn, name = "T_TABLE_MISSING", value = dat, overwrite = TRUE, row.names=FALSE)
  query <- "SELECT SUM(count_null) FROM (
              SELECT
                CASE WHEN [txt]   IS NULL THEN 1 ELSE 0 END +
                CASE WHEN [value] IS NULL THEN 1 ELSE 0 END AS count_null
              FROM T_TABLE_MISSING
            ) A"
  expect_equal(dbGetScalar(conn, query), 4)
  dbRemoveTable(conn, "T_TABLE_MISSING")
})

#TODO
# Failing with Message: not a widening conversion
test_that("Missing values: Read missing values using Fetch",{
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  dat <- data.frame(txt = c("a", NA, "b", NA),
                    value = c(1L, NA, NA, 2L),
                    stringsAsFactors = FALSE)
  conn <- get_con()
  dbWriteTable(conn, name = "T_TABLE_MISSING", value = dat, overwrite = TRUE, row.names=FALSE)
  res <- dbSendQuery(conn, "SELECT * FROM T_TABLE_MISSING")
  df <- fetch(res, n = -1)
  invisible(dbClearResult(res))
  expect_equivalent(df, dat)
  dbRemoveTable(conn, "T_TABLE_MISSING")
})

#TODO
test_that("Unusual Data Types: BIGINT",{
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  query <- "SELECT *  FROM T_BIGINT"
  df1 <- dbGetQuery(conn, query)
})

#TODO
test_that("Unusual Data Types: BIT",{
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  query <- "SELECT *  FROM T_BIT"
  df1 <- dbGetQuery(conn, query)
})
