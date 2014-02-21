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

test_that("dbGetRowCount : Get row count",{
  conn <- dbConnect('SqlServer',host='localhost',trusted=TRUE)
  query <- "SELECT  *
            FROM    T_MTCARS"
  res <- dbSendQuery(conn, query)
  df <- fetch(res,-1)
  expect_equal(dbGetRowCount(res), nrow(mtcars))
  dbClearResult(res)
  dbDisconnect(conn)
  
})




test_that("dbHasCompleted : check that query is completed",{
  conn <- dbConnect('SqlServer',host='localhost',trusted=TRUE)
  query <- "SELECT  *
            FROM    T_MTCARS"
  res <- dbSendQuery(conn, query)
  df1 <- fetch(res,as.integer(floor(nrow(mtcars)/2)))
  expect_false(dbHasCompleted(res))
  df2 <- fetch(res,-1)
  expect_false(dbHasCompleted(res))
  expect_equivalent(rbind(df1,df2),mtcars)
  dbClearResult(res)
  dbDisconnect(conn)
  
})

