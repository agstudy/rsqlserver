# Edit as required to run tests locally
userurl <- "Server=192.168.0.10;Database=TEST_RSQLSERVER;User Id=collateral;Password=Kollat;"

get_connection <- function(){
  dbConnect("SqlServer",url=userurl)
}
