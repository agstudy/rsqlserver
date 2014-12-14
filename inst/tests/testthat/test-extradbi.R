
context('Test Extra Functions')

test_that("dbConnect : we can set a timeout",{
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  query <- "select name from sys.tables"
  rs <- dbSendQuery(conn, query,timeout=90)
  df <- fetch(rs,-1)
  expect_equal(as.integer(dbGetInfo(rs,'TimeOut')),90)
  dbClearResult(rs)
  dbDisconnect(conn)

})
