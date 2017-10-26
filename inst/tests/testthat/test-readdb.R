context("Reading/Writing tables")
SERVER_ADDRESS <- "192.168.0.10"
test_that("dbReadTable : return a significant message if table not found", {
  on.exit(dbDisconnect(conn))
  
   url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,
                 SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  expect_error(dbReadTable(conn,'NO_EXIST_TABLE'),"Invalid object name")
})

test_that("dbReadTable : reopen connection if connection is already closed", {
  on.exit(dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,
                SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  res <- dbReadTable(conn,'T_DATE')
  expect_is(res,class="data.frame")
})



test_that("dbGetScalar : query in a temporary table works fine ", {

  on.exit(dbDisconnect(conn))
  req <- "create table #tempTable(Test int)
          insert into #tempTable
          select 2
          select * from #tempTable
          drop table #tempTable"
   url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,
                 SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  ress <- dbGetScalar(conn, req)
  expect_equal(ress,2)
})

test_that("dbWriteTable/dbRemoveTable: Create a table and remove it using handy functions ", {
  
  on.exit(dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,
                SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  if(dbExistsTable(conn,'T_MTCARS'))
    dbRemoveTable(conn,'T_MTCARS')
  dbWriteTable(conn,name='T_MTCARS',mtcars)
  expect_equal(dbExistsTable(conn,'T_MTCARS'),TRUE)
  dbRemoveTable(conn,'T_MTCARS')
  expect_equal(!dbExistsTable(conn,'T_MTCARS'),TRUE)
})



test_that(":::dbCreateTable:Create a table having sql keywords as columns ", {
  
  on.exit(dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  cnames = c('key','create','table')
  cnames = make.db.names(conn,cnames,allow.keywords=FALSE)
  if(dbExistsTable(conn,'TABLE_KEYWORDS'))
    dbRemoveTable(conn,'TABLE_KEYWORDS')
  rsqlserver:::dbCreateTable(conn,'TABLE_KEYWORDS',cnames,
                             ctypes=rep('varchar(3)',3))
})



test_that("fetch: get n rows from a table", {
  on.exit(dbDisconnect(conn))
   url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
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

test_that("dbGetQuery: get some columns from a table without setting  ", {
  
  on.exit(dbDisconnect(conn))
  url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
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




test_that("dbWriteTable/BulCopy:save and read a hudge data frame",{
  on.exit(dbDisconnect(conn))
  set.seed(1)
  N=1000
  table.name = paste('T_BIG',sprintf("%.9g", N) ,sep='_')
  dat <- data.frame(value=sample(1:100,N,rep=TRUE),
                    key  =sample(letters,N,rep=TRUE),
                    stringsAsFactors=FALSE)
   url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  dbWriteTable(conn,name=table.name,dat,row.names=FALSE,overwrite=TRUE)
  expect_equal(dbExistsTable(conn,table.name),TRUE)
  res <- dbReadTable(conn,name=table.name)
  expect_equal(nrow(res),N)
  
  
})

test_that("dbWriteTable/dbBulkWrite : Import a large data frame and unload to text",{
  on.exit(dbDisconnect(conn))
  set.seed(1)
  N=1000
  table.name = paste('T_BIG',sprintf("%.9g", N) ,sep='_')
  dat <- data.frame(value=sample(1:100,N,replace=TRUE),
                    key  =sample(letters,N,replace=TRUE),
                    stringsAsFactors=FALSE)
  conn <- get_connection()
  dbWriteTable(conn,name=table.name,dat,row.names=FALSE,overwrite=TRUE)
  expect_true(dbExistsTable(conn,table.name))
  dbBulkWrite(conn,name=table.name,value="t_big.csv",headers = T,delim = "\t")
  res <- read.csv("t_big.csv")
  expect_equal(nrow(res),N)
  file.remove("t_big.csv")
})

test_that("dbBulkWrite : Read bit, bigint, decimal/numeric columns from SQL Server",{
  on.exit(dbDisconnect(conn))
  set.seed(1)
  table.name <- "T_EXOTIC"
  dat <- data.frame(
    # Standard columns
    col_varchar = sample(state.name, 100, replace=TRUE),
    col_int = sample(1000,100,replace=T),
    # Exotic columns
    col_bigint = sample(2^50,100,replace=T),
    col_bit = sample(c(NA,0,1),100,replace=T),
    col_numeric = sample(10^7,100,replace=T)/10.0^6,
    col_decimal = sample(10^8,100,replace=T)/10.0^6
  )
  conn <- get_connection()
  field.types <- c("varchar(100)","int","bigint","bit","numeric(10,6)","decimal(10,6)")
  names(field.types) <- names(dat)
  dbWriteTable(conn,name=table.name,dat,field.types=field.types,row.names=FALSE,overwrite=TRUE)
  expect_true(dbExistsTable(conn,table.name))
  dbBulkWrite(conn,name=table.name,value="t_exotic.csv")
  res <- read.csv("t_exotic.csv")
  expect_equal(nrow(res),nrow(dat))
  file.remove("t_exotic.csv")
})


test_that("Misigns values :save  table with some missing values",{
  on.exit(dbDisconnect(conn))
  drv  <- dbDriver("SqlServer")
  start = Sys.time()
  value = 1:10
  value[5] <- NA_integer_
  dat <- data.frame(value=value)
   url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  dbWriteTable(conn,name='T_TABLE_MISING',value=dat,overwrite=TRUE)
  expect_true('T_TABLE_MISING' %in% dbListTables(conn))  
  
})

test_that("read/write missing values",{
  on.exit(dbDisconnect(conn))
  drv  <- dbDriver("SqlServer")
   url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  dat <- data.frame(txt=c('a',NA,'b',NA),
                    value =c(1L,NA,NA,2),stringsAsFactors=FALSE)
  dbWriteTable(conn,name='T_NULL',value=dat,overwrite=TRUE,row.names=FALSE)
  res <- dbSendQuery(conn, "SELECT * FROM T_NULL")
  df <- fetch(res, n = -1)
  expect_equivalent(df,dat)
  
})


test_that('read some data types: big/int bit',{
  
  on.exit(dbDisconnect(conn))
  drv  <- dbDriver("SqlServer")
   url = sprintf("Server=%s;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;" ,SERVER_ADDRESS)
  conn <- dbConnect('SqlServer',url=url)
  query <- "SELECT *  FROM [TABLE_BUG]"
  df1 <- dbGetQuery(conn, query)
  
})
