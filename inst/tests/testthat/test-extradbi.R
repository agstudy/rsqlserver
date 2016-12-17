context('Test Extra Functions')

test_that("dbGetScalar:returns a a null",{
  on.exit(  dbDisconnect(conn))
  req <- paste0("SELECT OBJECT_ID('","NO_TABLE","','U') AS 'Object ID';")
  conn <- get_connection()
  res <- dbGetScalar(conn,req)
  expect_true(is.null(res))
})


test_that("dbGetScalar:returns a scalar",{
  on.exit(  dbDisconnect(conn))
  req <- paste0("SELECT OBJECT_ID('","sysdiagrams","','U') AS 'Object ID';")
  conn <- get_connection()
  res <- dbGetScalar(conn,req)
  expect_true(length(res)==1)
  
})

test_that("dbConnect : we can set a timeout",{
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

