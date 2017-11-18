context("Test Extra Functions")

test_that("dbGetScalar: Returns null for NO_OBJECT",{
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  req <- "SELECT OBJECT_ID('NO_OBJECT','S') AS 'Object ID';"
  res <- dbGetScalar(conn,req)
  expect_null(res)
})

test_that("dbGetScalar: Returns a scalar",{
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  req <- "SELECT OBJECT_ID('sys.sysprivs','S') AS 'Object ID';"
  res <- dbGetScalar(conn,req)
  expect_length(res, 1)
})

test_that("dbConnect: Set a timeout",{
  skip_on_os(c("mac", "linux", "solaris"))
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  query <- "SELECT name FROM sys.tables"
  rs <- dbSendQuery(conn, query, timeout = 90)
  df <- fetch(rs, -1)
  expect_equal(as.integer(dbGetInfo(rs, "TimeOut")), 90)
  dbClearResult(rs)
})
