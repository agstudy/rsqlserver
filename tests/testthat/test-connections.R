context("Test Connections")

test_isconnected <- function(url){
  on.exit(dbDisconnect(con))
  con <- dbConnect("SqlServer", url = url)
  expect_equal(dbGetInfo(con, "State")$State, "Open")
}

test_that("dbConnect: Standard Security",{
  url <- sprintf("Server=%s;Database=%s;User Id=%s;Password=%s;",
                 server, dbname, user, password)
  test_isconnected(url)
})

test_that("dbConnect: Trusted conection",{
  skip_on_os(c("mac", "linux", "solaris"))
  url <- sprintf("Server=%s;Database=%s;Trusted_connection=True;",
                 server, dbname)
  test_isconnected(url)
})

test_that("dbConnect: Connecting using connection parameters",{
  on.exit(dbDisconnect(con))
  con <- dbConnect("SqlServer", host = server, dbname = dbname, user = user, password = password)
  expect_equal(dbGetInfo(con, "State")$State, "Open")
})

test_that("dbConnect: Trusted connection using with connection parameters",{
  skip_on_os(c("mac", "linux", "solaris"))
  on.exit(dbDisconnect(con))
  con <- dbConnect("SqlServer", host = server, dbname = dbname, trusted = TRUE)
  expect_equal(dbGetInfo(con, "State")$State, "Open")
})

test_that("dbConnect: Choose parameter if url is NULL",{
  skip_on_os(c("mac", "linux", "solaris"))
  on.exit(dbDisconnect(con))
  con <- dbConnect("SqlServer", host = server, dbname = dbname, trusted = TRUE, url = NULL)
  expect_equal(dbGetInfo(con, "State")$State, "Open")
})
