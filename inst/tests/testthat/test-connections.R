context('Test connections')

server <- "192.168.0.10"
dbname <- "TEST_RSQLSERVER"
user <- "collateral"
password <- "Kollat"


test_isConnected <- function(url){
  on.exit(dbDisconnect(conn))
  conn <- dbConnect('SqlServer',url=url)
  expect_equal(dbGetInfo(conn,"State")$State,"Open")
}

test_that("dbConnect : Standard Security",{
  url <- "Server=%s;Database=%s;User Id=%s;Password=%s;"
  url <- sprintf(url, server, dbname, user, password)
  test_isConnected(url)
})

test_that("dbConnect : Trusted Connection",{
  skip_on_os(c("mac", "linux", "solaris"))
  url <- "Server=localhost;Database=%s;Trusted_Connection=True;"
  test_isConnected(url, dbname)
})

test_that("dbConnect : Connecting using with connection parameters",{
  conn <- dbConnect('SqlServer',host=server,dbname=dbname,user=user,password=password)
  expect_equal(dbGetInfo(conn,"State")$State,"Open")
  dbDisconnect(conn)
})

test_that("dbConnect : TRUSTED Connection using with connection parameters",{
  skip_on_os(c("mac", "linux", "solaris"))
  conn <- dbConnect('SqlServer',host="localhost",dbname=dbname,trusted=TRUE)
  expect_equal(dbGetInfo(conn,"State")$State,"Open")
  dbDisconnect(conn)
})

test_that("dbConnect : choose parameter if url is NULL",{
  skip_on_os(c("mac", "linux", "solaris"))
  conn <- dbConnect('SqlServer',host="localhost",dbname=dbname,trusted=TRUE,url=NULL)
  expect_equal(dbGetInfo(conn,"State")$State,"Open")
  dbDisconnect(conn)
})
