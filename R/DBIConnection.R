
##
## Class: DBIConnection
##
setClass("SqlServerConnection", representation("DBIConnection", "SqlServerObject"))

setMethod("dbConnect", "SqlServerDriver",
          def = function(drv, ...) sqlServerNewConnection(drv, ...),
          valueClass = "SqlServerConnection"
)

setMethod("dbConnect", "character",
          def = function(drv, ...) sqlServerNewConnection(dbDriver(drv), ...),
          valueClass = "SqlServerConnection"
)

## clone a connection
setMethod("dbConnect", "SqlServerConnection",
          def = function(drv, ...) sqlServerCloneConnection(drv, ...),
          valueClass = "SqlServerConnection"
)

setMethod("dbDisconnect", "SqlServerConnection",
          def = function(conn, ...) sqlServerCloseConnection(conn, ...),
          valueClass = "logical"
)




setMethod("dbGetInfo", "SqlServerConnection",
          def = function(dbObj, ...) sqlServerConnectionInfo(dbObj, ...)
)

setMethod("dbListResults", "SqlServerConnection",
          def = function(conn, ...) dbGetInfo(conn, "rsId")[[1]]
)

setMethod("summary", "SqlServerConnection",
          def = function(object, ...) sqlServerDescribeConnection(object, ...)
)
setMethod("dbGetException", "SqlServerConnection",
          def = function(conn, ...){
            if(!isIdCurrent(conn))
              stop(paste("expired", class(conn)))
            .Call("RS_MySQL_getException", as(conn, "integer"), 
                  PACKAGE = .MySQLPkgName)
          },
          valueClass = "list"
)
