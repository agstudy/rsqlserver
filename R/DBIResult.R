setClass("SqlServerResult", representation("DBIResult", "SqlServerObject"))

setMethod("dbClearResult", "SqlServerResult", 
          def = function(res, ...) sqlServerCloseResult(res, ...), 
          valueClass = "logical"
)

setMethod("fetch", signature(res="SqlServerResult", n="numeric"),
          def = function(res, n, ...){ 
            out <- sqlServerFetch(res, n, ...)
            if(is.null(out))
              out <- data.frame(out)
            out
          },
          valueClass = "data.frame"
)


setMethod("fetch", 
          signature(res="SqlServerResult", n="missing"),
          def = function(res, n, ...){
            out <-  sqlServerFetch(res, n=0, ...)
            if(is.null(out))
              out <- data.frame(out)
            out
          },
          valueClass = "data.frame"
)


setMethod("dbSendQuery", 
          signature(conn = "SqlServerConnection", statement = "character"),
          def = function(conn, statement,...) sqlServerExecStatement(conn, statement,...),
          valueClass = "SqlServerResult"
)

setMethod("dbGetQuery", 
          signature(conn = "SqlServerConnection", statement = "character"),
          def = function(conn, statement, ...) sqlServerExecRetrieve(conn, statement, ...)
)

setGeneric("dbGetScalar", function(conn, statement, ...) 
  standardGeneric("dbGetScalar")
)
setMethod("dbGetScalar", 
          signature(conn = "SqlServerConnection", statement = "character"),
          def = function(conn, statement, ...) sqlServerExecScalar(conn, statement, ...),
          valueClass = "character"
)


setMethod("dbGetInfo", "SqlServerResult",
          def = function(dbObj, ...) sqlServerResultInfo(dbObj, ...),
          valueClass = "list"
)


## TODO: 
setMethod("dbHasCompleted", "SqlServerResult",
          def = function(res, ...) {
            nCols <- dbGetInfo(res, "FieldCount")[[1]] 
            is.na(nCols) || (nCols == 0)
          },
          valueClass = "logical"
)

### internal implementations
### helper functions


sqlServerExecStatement <- 
  function(conn,statement,...)
  {
    if(!isIdCurrent(conn)){
      warning(paste("expired SqlServerConnection"))
      return(TRUE)
    }
    clr.conn <- rClr:::createReturnedObject(conn@Id)
    cmd <- clrNew("System.Data.SqlClient.SqlCommand",statement,clr.conn)
    if(isTransaction(conn)){
      trans <- rClr:::createReturnedObject(conn@trans)
      clrCall(cmd,'set_Transaction',trans)
    }
    dataReader <- clrCall(cmd,'ExecuteReader')
    new("SqlServerResult", Id = clrGetExtPtr(dataReader))
    
  }


sqlServerExecScalar <- 
  function(conn,statement,...)
  {
    if(!isIdCurrent(conn)){
      warning(paste("expired SqlServerConnection"))
      return(TRUE)
    }
    clr.conn <- rClr:::createReturnedObject(conn@Id)
    cmd <- clrNew("System.Data.SqlClient.SqlCommand",statement,clr.conn)
    if(isTransaction(conn)){
      trans <- rClr:::createReturnedObject(conn@trans)
      clrCall(cmd,'set_Transaction',trans)
    }
    value <- clrCall(cmd,'ExecuteScalar')
    value
    
  }

# sqlServerFetch <- 
#   function(res,n){
#     n <- as(n, "integer")
#     dataReader <- rClr:::createReturnedObject(res@Id)
#     ncols <- clrGet(dataReader,"FieldCount")
#     if(ncols==0) return(NULL)
#     cnt <- 0
#     out <- data.frame()
#     if(clrGet(dataReader,'HasRows')>0) {
#       sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper")
#       while (clrCall(dataReader,"Read"))
#       {
#         datarow <- vector(mode='list',ncols)
#         for( i in seq_len(ncols)-1)
#         {
#           datarow[i+1] <- clrCall(sqlDataHelper,"GetItem",dataReader,
#                                         as.integer(i))
#         }
#         out <- if(length(out)==0) unlist(datarow)
#                else rbind(out,unlist(datarow))
#         cnt <- cnt +1 
#         if(cnt==n) break
#       }
#      rownames(out) <- as.integer(seq_len(cnt))
#     }
#     columns = vector('list',ncols)
#     columnsTypes = vector('list',ncols)
#     for( i in seq(0,ncols-1))
#       columns[i+1] <- clrCall(dataReader,'GetName',as.integer(i))
#     for( i in seq(0,ncols-1)){
#       columnsTypes[i+1] <- clrCall(dataReader,'GetDataTypeName',as.integer(i))
#       if(columnsTypes[i+1]=="datetime"){
# 
#         out[,i+1] <- as.POSIXct(out[,i+1])
#       }
#     }
#       
#     if(length(out)==0)
#       out <- do.call(cbind,as.list(rep(NA,ncols)))
#     colnames(out) <- columns
#     attr(out,'FielsType') <- columnsTypes
#     as.data.frame(out)
#   }


sqlServerFetch <- 
  function(res,n){
    n <- as(n, "integer")
    dataReader <- rClr:::createReturnedObject(res@Id)
    ncols <- clrGet(dataReader,"FieldCount")
    if(ncols==0) return(NULL)
    cnt <- 0
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper")
    out <-clrCall(sqlDataHelper,'Fetch',dataReader)
    columns = vector('list',ncols)
    columnsTypes = vector('list',ncols)
    for( i in seq(0,ncols-1))
      columns[i+1] <- clrCall(dataReader,'GetName',as.integer(i))
    browser()
    vals <- clrCall(sqlDataHelper,'TestRdotNet')
    for( i in seq(0,ncols-1)){
      columnsTypes[i+1] <- clrCall(dataReader,'GetDataTypeName',as.integer(i))
      if(columnsTypes[i+1]=="datetime"){
        
        out[,i+1] <- as.POSIXct(out[,i+1])
      }
    }
    
    if(length(out)==0)
      out <- do.call(cbind,as.list(rep(NA,ncols)))
    colnames(out) <- columns
    attr(out,'FielsType') <- columnsTypes
    as.data.frame(out)
  }




sqlServerCloseResult <- 
  function(res,...){
    dataReader <- rClr:::createReturnedObject(res@Id)
    clrCall(dataReader,"Close")
    TRUE
  }




## helper function: it exec's *and* retrieves a statement. It should
## be named somehting else.
sqlServerExecRetrieve <-
  function(con, statement)
  {
    state <- dbGetInfo(con,"State")
    if(state==0){                   ## conn is closed
      new.con <- dbConnect(con)     ## yep, create a clone connection
      on.exit(dbDisconnect(new.con))
      rs <- dbSendQuery(new.con, statement)
    } else rs <- dbSendQuery(con, statement)
    res <- fetch(rs, n = -1)
    dbClearResult(rs)
    res
  }


sqlServerResultInfo <- 
  function(dbObj,what,...){
    if(!isIdCurrent(dbObj))
      stop(paste("expired", class(dbObj), deparse(substitute(dbObj))))
    res <- rClr:::createReturnedObject(dbObj@Id)
    info <- vector("list", length = length(clrGetProperties(res)))
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper")
    for (prop in clrGetProperties(res))
      info[[prop]] <- clrCall(sqlDataHelper,"GetReaderProperty",res,
                              prop)
    info <- as.list(unlist(info))
    if(!missing(what))
      info[what]
    else
      info
  }


# 
# setMethod("dbGetStatement", "MySQLResult",
#           def = function(res, ...){
#             st <-  dbGetInfo(res, "statement")[[1]]
#             if(is.null(st))
#               st <- character()
#             st
#           },
#           valueClass = "character"
# )
# 
# setMethod("dbListFields", 
#           signature(conn="MySQLResult", name="missing"),
#           def = function(conn, name, ...){
#             flds <- dbGetInfo(conn, "fields")$fields$name
#             if(is.null(flds))
#               flds <- character()
#             flds
#           },
#           valueClass = "character"
# )
# 
# setMethod("dbColumnInfo", "MySQLResult", 
#           def = function(res, ...) mysqlDescribeFields(res, ...),
#           valueClass = "data.frame"
# )
# 
# ## NOTE: The following is experimental (as suggested by Greg Warnes)
# setMethod("dbColumnInfo", "MySQLConnection",
#           def = function(res, ...){
#             dots <- list(...) 
#             if(length(dots) == 0)
#               stop("must specify one MySQL object (table) name")
#             if(length(dots) > 1)
#               warning("dbColumnInfo: only one MySQL object name (table) may be specified", call.=FALSE)
#             dbGetQuery(res, paste("describe", dots[[1]]))
#           },
#           valueClass = "data.frame"
# )
# setMethod("dbGetRowsAffected", "MySQLResult",
#           def = function(res, ...) dbGetInfo(res, "rowsAffected")[[1]],
#           valueClass = "numeric"
# )
# 
# setMethod("dbGetRowCount", "MySQLResult",
#           def = function(res, ...) dbGetInfo(res, "rowCount")[[1]],
#           valueClass = "numeric"
# )
# 

# 
# setMethod("dbGetException", "MySQLResult",
#           def = function(conn, ...){
#             id <- as(conn, "integer")[1:2]
#             .Call("RS_MySQL_getException", id, PACKAGE = .MySQLPkgName)
#           },
#           valueClass = "list"    ## TODO: should be a DBIException?
# )
# 
# setMethod("summary", "MySQLResult", 
#           def = function(object, ...) mysqlDescribeResult(object, ...)
# )
# 
setMethod("dbDataType", 
          signature(dbObj = "SqlServerObject", obj = "ANY"),
          def = function(dbObj, obj, ...) sqlServerDbType(obj, ...),
          valueClass = "character"
)

sqlServerDbType <- function(obj,...)
{
  
  switch(typeof(obj),
         logical   = "TINYINT",
         integer   = "INTEGER",
         double  = if (inherits(obj, "POSIXct"))
           "DATETIME"
         else
           "REAL",
         character = "VARCHAR(128)",
         list      = "varbinary(2000)",
         stop(gettextf("rsqlserver internal error [%s, %d, %s]",
                       "sqlServerDbType", 1L, class(obj))))    
  
}
sqlServerToRType <- function(obj,...)
{
  
  switch(typeof(obj),
         datetime   = "TINYINT",
         integer   = "INTEGER",
         double  = if (inherits(obj, "POSIXct"))
           "DATETIME"
         else
           "REAL",
         character = "VARCHAR(128)",
         list      = "varbinary(2000)",
         stop(gettextf("rsqlserver internal error [%s, %d, %s]",
                       "sqlServerDbType", 1L, class(obj))))    
  
}



setMethod("make.db.names", 
          signature(dbObj="SqlServerObject", snames = "character"),
          def = function(dbObj, snames, keywords = .SqlServersKeywords,
                         unique, allow.keywords, ...){
            #      make.db.names.default(snames, keywords = .MySQLKeywords, unique = unique,
            #                            allow.keywords = allow.keywords)
            "makeUnique" <- function(x, sep = "_") {
              if (length(x) == 0)
                return(x)
              out <- x
              lc <- make.names(tolower(x), unique = FALSE)
              i <- duplicated(lc)
              lc <- make.names(lc, unique = TRUE)
              out[i] <- paste(out[i], substring(lc[i], first = nchar(out[i]) +
                                                  1), sep = sep)
              out
            }
            fc <- substring(snames, 1, 1)
            lc <- substring(snames, nchar(snames))
            i <- match(fc, c("'", "\"","`"), 0) > 0 & match(lc, c("'", "\"","`"),
                                                            0) > 0
            snames[!i] <- make.names(snames[!i], unique = FALSE)
            if (unique)
              snames[!i] <- makeUnique(snames[!i])
            if (!allow.keywords) {
              kwi <- match(keywords, toupper(snames), nomatch = 0L)
              
              # We could check to see if the database we are connected to is
              # running in ANSI mode. That would allow double quoted strings
              # as database identifiers. Until then, the backtick needs to be used.
              snames[kwi] <- paste("`", snames[kwi], "`", sep = "")
            }
            gsub("\\.", "_", snames)
          },
          valueClass = "character"
)
# 
# setMethod("SQLKeywords", "MySQLObject",
#           def = function(dbObj, ...) .MySQLKeywords,
#           valueClass = "character"
# )
# 
# setMethod("isSQLKeyword",
#           signature(dbObj="MySQLObject", name="character"),
#           def = function(dbObj, name, keywords = .MySQLKeywords, case, ...){
#             isSQLKeyword.default(name, keywords = .MySQLKeywords, case = case)
#           },
#           valueClass = "character"
# )
# 
# ## extension to the DBI 0.1-4
# 
# setGeneric("dbEscapeStrings", 
#            def = function(con, strings, ...) standardGeneric("dbEscapeStrings"))
# setMethod("dbEscapeStrings",
#           sig = signature(con = "MySQLConnection", strings = "character"),
#           def = mysqlEscapeStrings,
#           valueClass = "character"
# )
# setMethod("dbEscapeStrings",
#           sig = signature(con = "MySQLResult", strings = "character"),
#           def = function(con, strings, ...) 
#             mysqlEscapeStrings(as(con, "MySQLConnection"), strings),
#           valueClass = "character"
# )
# 
# setGeneric("dbApply", def = function(res, ...) standardGeneric("dbApply"))
# setMethod("dbApply", "MySQLResult",
#           def = function(res, ...)  mysqlDBApply(res, ...),
# )
# 
# setGeneric("dbMoreResults",
#            def = function(con, ...) standardGeneric("dbMoreResults"),
#            valueClass = "logical"
# )
# 
# setMethod("dbMoreResults", 
#           signature(con = "MySQLConnection"),
#           def = function(con, ...) 
#             .Call("RS_MySQL_moreResultSets", as(con, "integer"), 
#                   PACKAGE=.MySQLPkgName)
# )
# 
# setGeneric("dbNextResult",
#            def = function(con, ...) standardGeneric("dbNextResult")
#            #valueClass = "DBIResult" or NULL
# )
# 
# setMethod("dbNextResult", 
#           signature(con = "MySQLConnection"),
#           def = function(con, ...){
#             for(rs in dbListResults(con)){
#               dbClearResult(rs)
#             }
#             id = .Call("RS_MySQL_nextResultSet", as(con, "integer"),
#                        PACKAGE=.MySQLPkgName)
#             new("MySQLResult", Id = id)
#           }
# )
