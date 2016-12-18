context("Reading/Writing tables")

test_that("dbReadTable : return a significant message if table not found", {
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  expect_error(dbReadTable(conn,'NO_EXIST_TABLE'),"Invalid object name")
})

test_that("dbReadTable : reopen connection if connection is already closed", {
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  res <- dbReadTable(conn,'T_DATE')
  expect_is(res,class="data.frame")
})

test_that("dbGetScalar : query in a temporary table works fine", {
  on.exit(dbDisconnect(conn))
  req <- "create table #tempTable(Test int)
          insert into #tempTable
          select 2
          select * from #tempTable
          drop table #tempTable"
  conn <- get_connection()
  ress <- dbGetScalar(conn, req)
  expect_equal(ress,2)
})

test_that("dbWriteTable/dbRemoveTable : Create a table and remove it using handy functions", {
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  if(dbExistsTable(conn,'T_MTCARS'))
    dbRemoveTable(conn,'T_MTCARS')
  dbWriteTable(conn,name='T_MTCARS',mtcars)
  expect_equal(dbExistsTable(conn,'T_MTCARS'),TRUE)
  dbRemoveTable(conn,'T_MTCARS')
  expect_equal(!dbExistsTable(conn,'T_MTCARS'),TRUE)
})

test_that("dbCreateTable : Create a table having SQL keywords as columns", {
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  cnames = c('key','create','table')
  cnames = make.db.names(conn,cnames,allow.keywords=FALSE)
  if(dbExistsTable(conn,'TABLE_KEYWORDS'))
    dbRemoveTable(conn,'TABLE_KEYWORDS')
  rsqlserver:::dbCreateTable(conn,'TABLE_KEYWORDS',cnames,
                             ctypes=rep('varchar(3)',3))
})

test_that("Fetch : get n rows from a table", {
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  if(dbExistsTable(conn,'T_MTCARS'))
    dbRemoveTable(conn,'T_MTCARS')
  dbWriteTable(conn,name='T_MTCARS',mtcars)
  expect_equal(dbExistsTable(conn,'T_MTCARS'),TRUE)
  
  query <- "SELECT  mpg,cyl,wt 
               FROM    T_MTCARS"
  res <- dbSendQuery(conn, query)
  res.dat <- fetch(res,n=nrow(mtcars))
  invisible(dbClearResult(res))
  dbRemoveTable(conn,'T_MTCARS')
  expect_equal(!dbExistsTable(conn,'T_MTCARS'),TRUE)
  expect_is(res.dat,'data.frame')
  expect_equal(nrow(mtcars),nrow(res.dat))
  lapply(res.dat,function(x)expect_is(x,"numeric"))
})

test_that("dbGetQuery : get some columns from a table", {
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  if(dbExistsTable(conn,'T_MTCARS'))
    dbRemoveTable(conn,'T_MTCARS')
  dbWriteTable(conn,name='T_MTCARS',mtcars)
  expect_equal(dbExistsTable(conn,'T_MTCARS'),TRUE)
  
  query <- "SELECT  mpg,cyl,wt 
               FROM    T_MTCARS"
  res <- dbGetQuery(conn, query)
  dbRemoveTable(conn,'T_MTCARS')
  expect_equal(!dbExistsTable(conn,'T_MTCARS'),TRUE)
  expect_is(res,'data.frame')
  expect_equal(nrow(mtcars),nrow(res))
  lapply(res,function(x)expect_is(x,"numeric"))
})

test_that("dbWriteTable/BulCopy : save and read a huge data frame",{
  on.exit(dbDisconnect(conn))
  set.seed(1)
  N=1000
  table.name = paste('T_BIG',sprintf("%.9g", N) ,sep='_')
  dat <- data.frame(value=sample(1:100,N,replace=TRUE),
                    key  =sample(letters,N,replace=TRUE),
                    stringsAsFactors=FALSE)
  conn <- get_connection()
  dbWriteTable(conn,name=table.name,dat,row.names=FALSE,overwrite=TRUE)
  expect_equal(dbExistsTable(conn,table.name),TRUE)
  res <- dbReadTable(conn,name=table.name)
  expect_equal(nrow(res),N)
})

test_that("Missing values : save table with some missing values",{
  on.exit(dbDisconnect(conn))
  drv  <- dbDriver("SqlServer")
  start = Sys.time()
  value = 1:10
  value[5] <- NA_integer_
  dat <- data.frame(value=value)
  conn <- get_connection()
  dbWriteTable(conn,name='T_TABLE_MISING',value=dat,overwrite=TRUE)
  expect_true('T_TABLE_MISING' %in% dbListTables(conn))  
})

test_that("Missing values : Read/Write missing values",{
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  dat <- data.frame(txt=c('a',NA,'b',NA),
                    value =c(1L,NA,NA,2),stringsAsFactors=FALSE)
  dbWriteTable(conn,name='T_NULL',value=dat,overwrite=TRUE,row.names=FALSE)
  res <- dbSendQuery(conn, "SELECT * FROM T_NULL")
  df <- fetch(res, n = -1)
  expect_equivalent(df,dat)
})

#TODO
test_that("Bigint/bit : Read unusual data types",{
  on.exit(dbDisconnect(conn))
  conn <- get_connection()
  query <- "SELECT *  FROM [TABLE_BUG]"
  df1 <- dbGetQuery(conn, query)
})
