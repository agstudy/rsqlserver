
context("conversion of types and db naming conventions")

test_that("mapping fom sql server types to R types",
{
  
  expect_equal(rsqlserver:::db2RType("char"),"factor")
  expect_equal(rsqlserver:::db2RType("varchar"),"character")
  expect_equal(rsqlserver:::db2RType("int"),"integer")
  
})

test_that("the names are valid db names",{
  
  drv <- dbDriver("SqlServer")
  expect_equal(make.db.names(drv,"a mine"),"a_mine") ## space 
  ## keywords 
  expect_equal(make.db.names(drv,"create",allow.keywords=TRUE),"create")     
  expect_equal(make.db.names(drv,"create",allow.keywords=FALSE),"[create]")  
  
})


test_that("Automatic Conversion from R to data base",{
  
  value <- list(x.int=1L,
                x.num=1,
                x.fact=factor(1),
                x.char="x",
                x.list=list(1),
                x.date= Sys.Date(),
                x.posixct= Sys.time())
  expected <- list("int","float","char(12)","varchar(128)",
       "varbinary(2000)","date","datetime")
  effective <- lapply(value, rsqlserver:::R2DbType)
  names(expected) <- names(value)
  expect_identical(expected,effective)
  
})


# 
# test_that("save POSIXct , read it POSIXct",{
# 	
# 	drv  <- dbDriver("SqlServer")
# 	start <- Sys.time()
# 	dat <- data.frame(cdate = as.POSIXct(seq.POSIXt(from=start,by=1,length.out=100)))
# 	conn <- dbConnect('SqlServer',user="collateral",password="collat",
# 	                  host="localhost",trusted=TRUE, timeout=30)
#   
#   dbWriteTable(conn,name='T_DATE',value=dat,overwrite=TRUE)
#   res <- dbReadTable(conn,'T_DATE')
#   expect_is (res$cdate,'POSIXct')
# 	dbDisconnect(conn)
# 	
# })


        