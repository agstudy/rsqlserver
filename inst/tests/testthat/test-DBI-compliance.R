context("Dbi compliance")


test_that('dbListTable: get all tables',{
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  res <- dbListTables(conn)
  expect_true(length(res)>0)
  dbDisconnect(conn)
})

test_that("dbGetInfo : Get connection Info",{
  con <- dbConnect('SqlServer',host='localhost',trusted=TRUE)
  info <- dbGetInfo(con)
  desc <- paste0("Sql server ", info$ServerVersion, " [", info$WorkstationId, "@", 
                 info$DataSource, ":", info$Database, "/", 
                 ifelse(info$State[[1]]=='1','open','closed'), "]")
  dbDisconnect(con)
  
})


test_that("dbListFields : Get connection Info",{
  con <- dbConnect('SqlServer',host='localhost',trusted=TRUE)
  dbWriteTable(con,name='T_MTCARS',value=mtcars,
               row.names=FALSE,overwrite=TRUE)
  expect_equal(dbListFields(con,'T_MTCARS'), names(mtcars))
  dbDisconnect(con)
  
})
