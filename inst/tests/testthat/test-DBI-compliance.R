context("DBI Compliance")

test_that('dbListTable : Get list of all tables',{
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  res <- dbListTables(conn)
  expect_gte(length(res),0)
})

test_that("dbGetInfo : Get connection Info",{
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  dbinfo <- dbGetInfo(conn)
  desc <- paste0("Sql server ", dbinfo$ServerVersion, " [", dbinfo$WorkstationId, "@", 
                 dbinfo$DataSource, ":", dbinfo$Database, "/", dbinfo$State, "]")
  expect_named(dbinfo)
})

test_that("dbListFields: Get connection Info",{
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  dbWriteTable(conn, name = "T_MTCARS", value = mtcars,
               row.names = FALSE, overwrite = TRUE)
  expect_equal(dbListFields(conn, "T_MTCARS"), names(mtcars))
  dbRemoveTable(conn, "T_MTCARS")
})

#TODO
test_that("dbGetRowCount: Get row count",{
  skip("dbGetRowCount not yet implemented")
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  query <- "SELECT * FROM T_DATE"
  rs <- dbSendQuery(conn, query)
  df <- fetch(rs, -1)
  expect_equal(dbGetRowCount(rs), nrow(df))
  dbClearResult(rs)
})

#TODO
test_that("dbHasCompleted: Check that query is completed",{
  skip("dbHasCompleted not yet implemented")
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  query <- "SELECT * FROM T_MTCARS"
  res <- dbSendQuery(conn, query)
  df1 <- fetch(res, as.integer(floor(nrow(mtcars)/2)))
  expect_false(dbHasCompleted(res))
  df2 <- fetch(res, -1)
  expect_false(dbHasCompleted(res))
  expect_equivalent(rbind(df1,df2),mtcars)
  dbClearResult(res)
  dbRemoveTable(conn, "T_MTCARS")
})
