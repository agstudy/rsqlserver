context('Test Extra Functions')

test_that("dbGetScalar : Returns null for NO_OBJECT",{
  on.exit(  dbDisconnect(conn))
  conn <- get_connection()
  req <- "SELECT OBJECT_ID('NO_OBJECT','S') AS 'Object ID';"
  res <- dbGetScalar(conn,req)
  expect_true(is.null(res))
})

test_that("dbGetScalar : Returns a scalar",{
  on.exit(  dbDisconnect(conn))
  conn <- get_connection()
  req <- "SELECT OBJECT_ID('sys.sysprivs','S') AS 'Object ID';"
  res <- dbGetScalar(conn,req)
  expect_true(length(res)==1)
})

test_that("dbConnect : We can set a timeout",{
  on.exit(  dbDisconnect(conn))
  conn <- get_connection()
  query <- "select name from sys.tables"
  rs <- dbSendQuery(conn, query,timeout=90)
  df <- fetch(rs,-1)
  if(.Platform$OS.type =="windows"){
    expect_equal(as.integer(dbGetInfo(rs,'TimeOut')),90)
  }
  dbClearResult(rs)
})

