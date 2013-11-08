context("Reading/Writing tables")

test_that("dbReadTable : return a significant message if table not found", {
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
  
  expect_error(dbReadTable(conn,'NO_EXIST_TABLE'),"Invalid object name")
  dbDisconnect(conn)
  
})

test_that("dbReadTable : reopen connection if connection is already closed", {
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
  dbDisconnect(conn)
  res <- dbReadTable(conn,'T_DATE')
  expect_is(res,class="data.frame")
})



test_that("dbGetScalar : query in a temporary table works fine ", {

  req <- "create table #tempTable(Test int)
          insert into #tempTable
          select 2
          select * from #tempTable
          drop table #tempTable"
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
  ress <- dbGetScalar(conn, req)
  dbDisconnect(conn)
  expect_equal(ress,2)
})

test_that("dbWriteTable/dbRemoveTable: Create a table and remove it using handy functions ", {
  
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
  if(dbExistsTable(conn,'T_MTCARS'))
    dbRemoveTable(conn,'T_MTCARS')
  dbWriteTable(conn,name='T_MTCARS',mtcars)
  expect_equal(dbExistsTable(conn,'T_MTCARS'),TRUE)
  dbRemoveTable(conn,'T_MTCARS')
  expect_equal(!dbExistsTable(conn,'T_MTCARS'),TRUE)
  dbDisconnect(conn)
})



test_that(":::dbCreateTable:Create a table having sql keywords as columns ", {
  
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
  cnames = c('key','create','table')
  cnames = make.db.names(conn,cnames,allow.keywords=FALSE)
  if(dbExistsTable(conn,'TABLE_KEYWORDS'))
    dbRemoveTable(conn,'TABLE_KEYWORDS')
  rsqlserver:::dbCreateTable(conn,'TABLE_KEYWORDS',cnames,
                             ctypes=rep('varchar(3)',3))
  dbDisconnect(conn)
})



test_that("fetch: get n rows from a table", {
  
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
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
  dbDisconnect(conn)
  expect_is(res.dat,'data.frame')
  expect_equal(nrow(mtcars),nrow(res.dat))
  lapply(res.dat,function(x)expect_is(x,"numeric"))
})

test_that("dbGetQuery: get some columns from a table without setting  ", {
  
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
  if(dbExistsTable(conn,'T_MTCARS'))
    dbRemoveTable(conn,'T_MTCARS')
  dbWriteTable(conn,name='T_MTCARS',mtcars)
  expect_equal(dbExistsTable(conn,'T_MTCARS'),TRUE)
  
  query <- "SELECT  mpg,cyl,wt 
               FROM    T_MTCARS"
  res <- dbGetQuery(conn, query)
  dbRemoveTable(conn,'T_MTCARS')
  expect_equal(!dbExistsTable(conn,'T_MTCARS'),TRUE)
  dbDisconnect(conn)
  expect_is(res,'data.frame')
  expect_equal(nrow(mtcars),nrow(res))
  lapply(res,function(x)expect_is(x,"numeric"))
})




test_that("dbWriteTable/BulCopy:save and read a hudge data frame",{
  set.seed(1)
  N=1000
  table.name = paste('T_BIG',sprintf("%.9g", N) ,sep='_')
  dat <- data.frame(value=sample(1:100,N,rep=TRUE),
                    key  =sample(letters,N,rep=TRUE),
                    stringsAsFactors=FALSE)
  conn <- dbConnect('SqlServer',user="collateral",password="collat",
                    host="localhost",trusted=TRUE, timeout=30)
  dbWriteTable(conn,name=table.name,dat,row.names=FALSE,overwrite=TRUE)
  expect_equal(dbExistsTable(conn,table.name),TRUE)
  res <- dbReadTable(conn,name=table.name)
  expect_equal(nrow(res),N)
  dbDisconnect(conn)
  
  
})

