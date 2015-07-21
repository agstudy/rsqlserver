
context('Test Extra Functions')
SERVER_ADDRESS <- "192.168.0.10"


test_that("dbGetScalar:returns a scalar",{
  on.exit(  dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  req <- paste0("SELECT OBJECT_ID('","no_table","','U') AS 'Object ID';")
  res <- dbGetScalar(conn,req)
  expect_false(res)
})

test_that("dbConnect : we can set a timeout",{
  on.exit(  dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  query <- "select name from sys.tables"
  rs <- dbSendQuery(conn, query,timeout=90)
  df <- fetch(rs,-1)
  expect_equal(as.integer(dbGetInfo(rs,'TimeOut')),90)
  dbClearResult(rs)
})

