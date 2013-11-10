context("Dbi compliance")


test_that('dbListTable: get all tables',{
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  res <- dbListTables(conn)
  expect_is(res,"data.frame")
  dbDisconnect(conn)
})