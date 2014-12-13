
context("conversion of types and db naming conventions")

test_that("db2RType: mapping fom sql server types to R types works",
{
  
  expect_equal(rsqlserver:::db2RType("char"),"factor")
  expect_equal(rsqlserver:::db2RType("varchar"),"character")
  expect_equal(rsqlserver:::db2RType("int"),"integer")
  
})

test_that("make.db.names:the names are valid db names",{
  
  drv <- dbDriver("SqlServer")
  expect_equal(make.db.names(drv,"a mine"),"a_mine") ## space 
  ## keywords 
  expect_equal(make.db.names(drv,"create",allow.keywords=TRUE),"create")     
  expect_equal(make.db.names(drv,"create",allow.keywords=FALSE),"[create]")  
  
})


test_that("R2DbType:Automatic Conversion from R to data base",{
  
  value <- list(x.int=1L,
                x.num=1,
                x.fact=factor(1),
                x.char="x",
                x.list=list(1),
                x.date= Sys.Date(),
                x.posixct= Sys.time())
  expected <- list("int","float","char(12)","varchar(128)",
                   "varbinary(2000)","date","datetime2")
  effective <- lapply(value, rsqlserver:::R2DbType)
  names(expected) <- names(value)
  expect_identical(expected,effective)
  
})



test_that("sqlServer.data.frame:data is well quoted before insert",{
  
  options(stringsAsFactors = FALSE) 
  
  value <- data.frame(a=as.POSIXct("2013-11-07 01:47:33"),
                      b="value ' alol",
                      c="aa jujs",
                      d=1,
                      e=as.Date("2013-11-07"))
  
  expected = data.frame(a="'2013-11-07 01:47:33'",  ## tz=""
                        b="'value '' alol'",
                        c="'aa jujs'",
                        d=1,
                        e="'2013-11-07'")
  field.types <- lapply(value, rsqlserver:::R2DbType)
  names(field.types) <- names(value)
  value.db <- rsqlserver:::sqlServer.data.frame(
    value,field.types)
  expect_equal(expected,value.db)
  
  
})




test_that("dbReadTable: read rownames in the exact type",
{
  drv  <- dbDriver("SqlServer")
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  dat_int  <- data.frame(x=1:10)
  dat_char <- data.frame(x=1:10)
  dat_date <- data.frame(x=1:10)
  rownames(dat_char) <- paste0("row",seq(nrow(dat_char)))
  start = Sys.time()
  rownames(dat_date) <- as.POSIXct(seq.POSIXt(from=start,by=1,
                                              length.out=nrow(dat_date)))
  invisible(lapply(ls(pattern="dat_"),
                   function(x){
                     dbWriteTable(conn,name=x,value=get(x),overwrite=TRUE)
                     res <- dbReadTable(conn,name=x)
                     expect_identical(rownames(get(x)),
                                      rownames(res))
                   }))
  
  dbDisconnect(conn)
  
  
  
})

test_that("dbWriteTable/dbReadTable :save POSIXct , read it again as POSIXct",{
  
  drv  <- dbDriver("SqlServer")
  start = Sys.time()
  dat <- data.frame(cdate = as.POSIXct(seq.POSIXt(from=start,by=1,length.out=100)))
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  
  dbWriteTable(conn,name='T_DATE',value=dat,overwrite=TRUE)
  res <- dbReadTable(conn,'T_DATE')
  expect_is (res$cdate,'POSIXct')
  dbDisconnect(conn)
  
})

test_that("dbBulkCopy :save POSIXct , read it again as POSIXct",{
  
  drv  <- dbDriver("SqlServer")
  N = 100000
  start = Sys.time()
  dat <- data.frame(cdate = as.POSIXct(seq.POSIXt(from=start,by=1,length.out=N)))
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  rsqlserver:::dbCreateTable(conn,'T_BULKCOPY', 
                             c('cdate'),'datetime2')
  dbBulkCopy(conn,name='T_BULKCOPY',value=dat,overwrite=TRUE)
  res <- dbReadTable(conn,'T_BULKCOPY')
  expect_is (res$cdate,'POSIXct')
  dbDisconnect(conn)
  
})



## see issue https://github.com/agstudy/rsqlserver/issues/11
test_that("dbWriteTable/dbReadTable :save Date , read the same Date again",{
  drv  <- dbDriver("SqlServer")
  start = Sys.Date()
  dat <- data.frame(cdate = seq.Date(from=start,by=1,length.out=5))
  #dat$cdate <- as.Date(dat$cdate,tz=Sys.timezone())
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  dbWriteTable(conn,name='T_DATE',value=dat,overwrite=TRUE)
  res <- dbReadTable(conn,'T_DATE')
  expect_equal(res$cdate,dat$cdate)
  dbDisconnect(conn)
  
})

test_that("dbWriteTable/dbReadTable :save POSIXct , read the same POSIXct again",{
  drv  <- dbDriver("SqlServer")
  start = Sys.time()
  dat <- data.frame(cdate = seq.POSIXt(from=start,by=1,length.out=5))
  #dat$cdate <- as.Date(dat$cdate,tz=Sys.timezone())
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url)
  dbWriteTable(conn,name='T_DATE',value=dat,overwrite=TRUE)
  res <- dbReadTable(conn,'T_DATE')
  expect_equal(res$cdate,dat$cdate)
  dbDisconnect(conn)
  
})




