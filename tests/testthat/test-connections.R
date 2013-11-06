# 
context('test connections')

test_isConnected <- function(url){
  conn <- dbConnect('SqlServer',url=url)
  expect_equal(dbGetInfo(conn,"State")[[1]],"1")
  dbDisconnect(conn)
}

test_that("Standard Security",{
 url = "Server=localhost;Database=COLLATERAL;User Id=collateral;
  Password=collat;"
 test_isConnected(url)
})

###           
test_that("Trusted Connection",{
  url = "Server=localhost;Database=COLLATERAL;Trusted_Connection=True;"
  test_isConnected(url)
  
})
# 
# 
# test_that("Connection to a SQL Server instance",{
#   url = "Server=myServerName/myInstanceName;Database=myDataBase;User Id=myUsername;
#   Password=myPassword;"
#   con <- dbConnect('SqlServer',url=url)
#   expect_equal(dbGetInfo(conn,"State"),0)
#   dbDisconnect(url)
#   
# })
# 
# test_that("Trusted Connection from a CE device",{
#  url = "Data Source=myServerAddress;Initial Catalog=myDataBase;Integrated Security=SSPI;
#   User ID=myDomain/myUsername;Password=myPassword;"
#  con <- dbConnect('SqlServer',url=url)
#  expect_equal(dbGetInfo(conn,"State"),0)
#  dbDisconnect(url)
# })
# 
# test_that("Connect via an IP address",{
#   url = "Data Source=190.190.200.100,1433;Network Library=DBMSSOCN;
#   Initial Catalog=myDataBase;User ID=myUsername;Password=myPassword;"
#   con <- dbConnect('SqlServer',url=url)
#   expect_equal(dbGetInfo(conn,"State"),0)
#   dbDisconnect(url)
#   
#   
# })
# 
# test_that("Enable MARS",{
#   url = "Server=myServerAddress;Database=myDataBase;Trusted_Connection=True;
#   MultipleActiveResultSets=true;"
#   con <- dbConnect('SqlServer',url=url)
#   expect_equal(dbGetInfo(conn,"State"),0)
#   dbDisconnect(url)
# })
# 
# 
# test_that("Attach a database file on connect to a local SQL Server Express instance",{
#   url = "Server=./SQLExpress;AttachDbFilename=C:/MyFolder/MyDataFile.mdf;Database=dbname;
# Trusted_Connection=Yes;"
#   con <- dbConnect('SqlServer',url=url)
#   expect_equal(dbGetInfo(conn,"State"),0)
#   dbDisconnect(url)
# })
# 
# 
# 
# 
# 
#           
#           