library(DBI)
.SQLserverPkgName <- "SQLServer"
.SQLserverPkgRCS <- "$Id$"
.SQLserver.NA.string <- "\\N"  ## on input SQLite interprets \N as NULL (NA)


setOldClass("data.frame")      ## to appease setMethod's signature warnings...

##
## Class: DBIObject
##
setClass("SqlServerObject", representation("DBIObject","dbObjectId", "VIRTUAL"))
setClass("SqlServerDriver", representation("DBIDriver", "SqlServerObject"))

SqlServer <-
  function(max.con = 200L, fetch.default.rec = 500, force.reload = FALSE,
           shared.cache=FALSE)
  {
    sqlServerInitDriver(max.con, fetch.default.rec, force.reload, shared.cache)
  }

## coerce (extract) any SqlServerObject into a SqlServerDriver
setAs("SqlServerObject", "SqlServerDriver", 
      def = function(from) {
        new("SqlServerDriver", Id = from@Id)
      }
)
      

setMethod("dbUnloadDriver", "SqlServerDriver",
          def = function(drv, ...) sqlServerCloseDriver(drv, ...),
          valueClass = "logical"
)

setMethod("dbGetInfo", "SqlServerDriver", 
          def = function(dbObj, ...) sqlServerDriverInfo(dbObj, ...)
)

setMethod("dbListConnections", "SqlServerDriver",
          def = function(drv, ...) dbGetInfo(drv, "connectionIds")[[1]]
)

setMethod("summary", "SqlServerDriver", 
          def = function(object, ...) sqlServerDescribeDriver(object, ...)
)

