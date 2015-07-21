
context('Test Extra Functions')
SERVER_ADDRESS <- "192.168.0.10"


test_that("dbGetScalar:returns a a null",{
  on.exit(  dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  req <- paste0("SELECT OBJECT_ID('","NO_TABLE","','U') AS 'Object ID';")
  res <- dbGetScalar(conn,req)
  expect_true(is.null(res))
})


test_that("dbGetScalar:returns a scalar",{
  on.exit(  dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  req <- paste0("SELECT OBJECT_ID('","sysdiagrams","','U') AS 'Object ID';")
  res <- dbGetScalar(conn,req)
  expect_true(length(res)==1)
  
})

test_that("dbConnect : we can set a timeout",{
  on.exit(  dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  query <- "select name from sys.tables"
  rs <- dbSendQuery(conn, query,timeout=90)
  df <- fetch(rs,-1)
  if(.Platform$OS.type =="windows"){
    expect_equal(as.integer(dbGetInfo(rs,'TimeOut')),90)
  }
  
  dbClearResult(rs)
})

