# Edit as required to run tests on an accessible SQL Server
# See docker.sh for instructions to setup a SQL Server Docker container
server <- "mydockermsdb"
dbname <- "rsqlserverdb"
user <- "SA"
password <- "Password12!"

set_url <- function(){
  if (identical(Sys.getenv("TRAVIS"), "true")) {
    "Server=mydb;Database=rsqlserverdb;User ID=sa;Password=Password12!"
  } else if (identical(Sys.getenv("APPVEYOR"), "True")) {
    "Server=(local)\\SQL2014;Database=rsqlserverdb;User ID=sa;Password=Password12!"
  } else {
    sprintf("Server=%s;Database=%s;User Id=%s;Password=%s;",
            server, dbname, user, password)
  }
}

get_con <- function(){
  dbConnect("SqlServer", url = set_url())
}
