setMethod("dbGetInfo", "SqlServerConnection",
          def = function(dbObj, ...) 
            .sqlServerConnectionInfo(dbObj, ...)
)


# dbGetStatement(res, ...)    # statement that produced result "res"
# dbGetRowCount(res, ...)     # number of rows fetched so far
# dbGetRowsAffected(res, ...) # number of affected rows (e.g., DELETE)
# dbColumnInfo(res, ...)      # result set data types
# dbHasCompleted(res, ...)    # are there more rows to fetch on "res"?


## return -1 since it is impossible to get the number of row
## number of rows fetched so far
setMethod("dbGetRowCount", "SqlServerResult", 
          def = function(res, ...) 
            dbGetInfo(res, "Fetched"))



## TODO: 
setMethod("dbHasCompleted", 
          "SqlServerResult",
          def = function(res, ...) {
            dbGetInfo(res, "HasRows")[[1]] != "1"
          }
          ,
          valueClass = "logical"
)

.sqlServerConnectionInfo <- 
  function(dbObj,what,...){
    if(!isIdCurrent(dbObj))
      stop(paste("expired", class(dbObj), deparse(substitute(dbObj))))
    conn <- rClr:::createReturnedObject(dbObj@Id)
    info <- vector("list", length = length(clrGetProperties(conn)))
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper")
    for (prop in clrGetProperties(conn))
      info[[prop]] <- clrCall(sqlDataHelper,"GetConnectionProperty",conn,
                              prop)
    info <- as.list(unlist(info))
    if(!missing(what))
      info[what]
    else
      info
  }

.sqlServerGetProperty <- 
  function(dbObj,prop,...){
    dataReader <- rClr:::createReturnedObject(dbObj@Id)
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper",dataReader)
    clrGet(sqlDataHelper,'Fetched')
  }

