###
context('Test connections')

SERVER_ADDRESS <- "192.168.0.10"



test_isConnected <- function(url){
  on.exit(dbDisconnect(conn))
  conn <- dbConnect('SqlServer',url=url)
  expect_equal(dbGetInfo(conn,"State")$State,"Open")

}

test_that("dbConnect : Standard Security",{
  url = "Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;"
  url <- sprintf(url,SERVER_ADDRESS)
  test_isConnected(url)
})

###           
test_that("dbConnect : Trusted Connection",{
  if(.Platform$OS.type =="windows"){
    url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
    test_isConnected(url)
  }
  
})

test_that("dbConnect : Connecting using with connection parameters",{
  host=SERVER_ADDRESS
  dbname="TEST_RSQLSERVER"
  user="collateral"
  password="Kollat"
  conn <- dbConnect('SqlServer',host=host,dbname=dbname,user=user,password=password)
  expect_equal(dbGetInfo(conn,"State")$State,"Open")
  dbDisconnect(conn)
})





test_that("dbConnect : TRUSTED Connection using with connection parameters ",{
  if(.Platform$OS.type =="windows"){
    host="localhost"
    dbname="TEST_RSQLSERVER"
    conn <- dbConnect('SqlServer',host=host,dbname=dbname,trusted=TRUE)
    expect_equal(dbGetInfo(conn,"State")$State,"Open")
    dbDisconnect(conn)
  }
})

test_that("dbConnect : choose parameter if url is NULL ",{
  if(.Platform$OS.type =="windows"){
    
    host="localhost"
    dbname="TEST_RSQLSERVER"
    conn <- dbConnect('SqlServer',host=host,dbname=dbname,trusted=TRUE,url=NULL)
    expect_equal(dbGetInfo(conn,"State")$State,"Open")
    dbDisconnect(conn)
  }
})

