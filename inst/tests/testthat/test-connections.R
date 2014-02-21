###
context('Test connections')

test_isConnected <- function(url){
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  expect_equal(dbGetInfo(conn,"State")[[1]],"1")
  dbDisconnect(conn)
}

test_that("dbConnect : Standard Security",{
 url = "Server=localhost;Database=TEST_RSQLSERVER;User Id=collateral;
  Password=Kollat;"
 test_isConnected(url)
})

###           
test_that("dbConnect : Trusted Connection",{
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  test_isConnected(url)
  
})

test_that("dbConnect : Connecting using with connection parameters",{
  host="localhost"
  dbname="TEST_RSQLSERVER"
  user="collateral"
  password="Kollat"
  conn <- dbConnect('SqlServer',host=host,dbname=dbname,user=user,password=password)
  expect_equal(dbGetInfo(conn,"State")[[1]],"1")
  dbDisconnect(conn)
})


test_that("dbConnect : TRUSTED Connection using with connection parameters ",{
  host="localhost"
  dbname="TEST_RSQLSERVER"
  conn <- dbConnect('SqlServer',host=host,dbname=dbname,trusted=TRUE)
  expect_equal(dbGetInfo(conn,"State")[[1]],"1")
  dbDisconnect(conn)
})

test_that("dbConnect : choose parameter if url is NULL ",{
  host="localhost"
  dbname="TEST_RSQLSERVER"
  conn <- dbConnect('SqlServer',host=host,dbname=dbname,trusted=TRUE,url=NULL)
  expect_equal(dbGetInfo(conn,"State")[[1]],"1")
  dbDisconnect(conn)
})