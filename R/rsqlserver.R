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

"SqlServer" <-
  function(max.con = 200L, fetch.default.rec = 500, force.reload = FALSE,
           shared.cache=FALSE)
  {
    sqlServerInitDriver(max.con, fetch.default.rec, force.reload, shared.cache)
  }

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

# ##



##
## Class: DBIConnection
##
setClass("SqlServerConnection", representation("DBIConnection", "SqlServerObject"))

setMethod("dbConnect", "SqlServerDriver",
          def = function(drv, ...) SqlServerNewConnection(drv, ...),
          valueClass = "SqlServerConnection"
)

setMethod("dbConnect", "character",
          def = function(drv, ...) SqlServerNewConnection(dbDriver(drv), ...),
          valueClass = "SqlServerConnection"
)

## clone a connection
setMethod("dbConnect", "SqlServerConnection",
          def = function(drv, ...) SqlServerCloneConnection(drv, ...),
          valueClass = "SqlServerConnection"
)

setMethod("dbDisconnect", "SqlServerConnection",
          def = function(conn, ...) SqlServerCloseConnection(conn, ...),
          valueClass = "logical"
)

setMethod("dbSendQuery", 
          signature(conn = "SqlServerConnection", statement = "character"),
          def = function(conn, statement,...) sqlServerExecStatement(conn, statement,...),
          valueClass = "MySQLResult"
)

# setMethod("dbGetQuery", 
#           signature(conn = "MySQLConnection", statement = "character"),
#           def = function(conn, statement, ...) mysqlQuickSQL(conn, statement, ...)
# )
# 
# setMethod("dbGetException", "MySQLConnection",
#           def = function(conn, ...){
#             if(!isIdCurrent(conn))
#               stop(paste("expired", class(conn)))
#             .Call("RS_MySQL_getException", as(conn, "integer"), 
#                   PACKAGE = .MySQLPkgName)
#           },
#           valueClass = "list"
# )
# 
# setMethod("dbGetInfo", "MySQLConnection",
#           def = function(dbObj, ...) mysqlConnectionInfo(dbObj, ...)
# )
# 
# setMethod("dbListResults", "MySQLConnection",
#           def = function(conn, ...) dbGetInfo(conn, "rsId")[[1]]
# )
# 
# setMethod("summary", "MySQLConnection",
#           def = function(object, ...) mysqlDescribeConnection(object, ...)
# )
# 
# ## convenience methods 
# setMethod("dbListTables", "MySQLConnection",
#           def = function(conn, ...){
#             tbls <- dbGetQuery(conn, "show tables")
#             if(length(tbls)>0) 
#               tbls <- tbls[,1]
#             else
#               tbls <- character()
#             tbls
#           },
#           valueClass = "character"
# )
# 
# setMethod("dbReadTable", signature(conn="MySQLConnection", name="character"),
#           def = function(conn, name, ...) mysqlReadTable(conn, name, ...),
#           valueClass = "data.frame"
# )
# 
# setMethod("dbWriteTable", 
#           signature(conn="MySQLConnection", name="character", value="data.frame"),
#           def = function(conn, name, value, ...){
#             mysqlWriteTable(conn, name, value, ...)
#           },
#           valueClass = "logical"
# )
# 
# ## write table from filename (TODO: connections)
# setMethod("dbWriteTable", 
#           signature(conn="MySQLConnection", name="character", value="character"),
#           def = function(conn, name, value, ...){
#             mysqlImportFile(conn, name, value, ...)
#           },
#           valueClass = "logical"
# )
# 
# setMethod("dbExistsTable", 
#           signature(conn="MySQLConnection", name="character"),
#           def = function(conn, name, ...){
#             ## TODO: find out the appropriate query to the MySQL metadata
#             avail <- dbListTables(conn)
#             if(length(avail)==0) avail <- ""
#             match(tolower(name), tolower(avail), nomatch=0)>0
#           },
#           valueClass = "logical"
# )
# 
# setMethod("dbRemoveTable", 
#           signature(conn="MySQLConnection", name="character"),
#           def = function(conn, name, ...){
#             if(dbExistsTable(conn, name)){
#               rc <- try(dbGetQuery(conn, paste("DROP TABLE", name)))
#               !inherits(rc, ErrorClass)
#             } 
#             else FALSE
#           },
#           valueClass = "logical"
# )
# 
# ## return field names (no metadata)
# setMethod("dbListFields", 
#           signature(conn="MySQLConnection", name="character"),
#           def = function(conn, name, ...){
#             flds <- dbGetQuery(conn, paste("describe", name))[,1]
#             if(length(flds)==0)
#               flds <- character()
#             flds
#           },
#           valueClass = "character"
# )
# 
# setMethod("dbCommit", "MySQLConnection",
#           def = function(conn, ...) .NotYetImplemented()
# )
# 
# setMethod("dbRollback", "MySQLConnection",
#           def = function(conn, ...) .NotYetImplemented()
# )
# 
# setMethod("dbCallProc", "MySQLConnection",
#           def = function(conn, ...) .NotYetImplemented()
# )
# 

# ##
# ## Class: DBIResult
# ##

setClass("SqlServerResult", representation("DBIResult", "SqlServerObject"))

# setAs("MySQLResult", "MySQLConnection",
#       def = function(from) new("MySQLConnection", Id = as(from, "integer")[1:3])
# )
# setAs("MySQLResult", "MySQLDriver",
#       def = function(from) new("MySQLDriver", Id = as(from, "integer")[1:2])
# )
# 
# setMethod("dbClearResult", "MySQLResult", 
#           def = function(res, ...) mysqlCloseResult(res, ...), 
#           valueClass = "logical"
# )
# 
# setMethod("fetch", signature(res="MySQLResult", n="numeric"),
#           def = function(res, n, ...){ 
#             out <- mysqlFetch(res, n, ...)
#             if(is.null(out))
#               out <- data.frame(out)
#             out
#           },
#           valueClass = "data.frame"
# )
# 
# setMethod("fetch", 
#           signature(res="MySQLResult", n="missing"),
#           def = function(res, n, ...){
#             out <-  mysqlFetch(res, n=0, ...)
#             if(is.null(out))
#               out <- data.frame(out)
#             out
#           },
#           valueClass = "data.frame"
# )
# 
# setMethod("dbGetInfo", "MySQLResult",
#           def = function(dbObj, ...) mysqlResultInfo(dbObj, ...),
#           valueClass = "list"
# )
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
# setMethod("dbHasCompleted", "MySQLResult",
#           def = function(res, ...) dbGetInfo(res, "completed")[[1]] == 1,
#           valueClass = "logical"
# )
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
# setMethod("dbDataType", 
#           signature(dbObj = "MySQLObject", obj = "ANY"),
#           def = function(dbObj, obj, ...) mysqlDataType(obj, ...),
#           valueClass = "character"
# )
# 
# setMethod("make.db.names", 
#           signature(dbObj="MySQLObject", snames = "character"),
#           def = function(dbObj, snames, keywords = .MySQLKeywords,
#                          unique, allow.keywords, ...){
#             #      make.db.names.default(snames, keywords = .MySQLKeywords, unique = unique,
#             #                            allow.keywords = allow.keywords)
#             "makeUnique" <- function(x, sep = "_") {
#               if (length(x) == 0)
#                 return(x)
#               out <- x
#               lc <- make.names(tolower(x), unique = FALSE)
#               i <- duplicated(lc)
#               lc <- make.names(lc, unique = TRUE)
#               out[i] <- paste(out[i], substring(lc[i], first = nchar(out[i]) +
#                                                   1), sep = sep)
#               out
#             }
#             fc <- substring(snames, 1, 1)
#             lc <- substring(snames, nchar(snames))
#             i <- match(fc, c("'", "\"","`"), 0) > 0 & match(lc, c("'", "\"","`"),
#                                                             0) > 0
#             snames[!i] <- make.names(snames[!i], unique = FALSE)
#             if (unique)
#               snames[!i] <- makeUnique(snames[!i])
#             if (!allow.keywords) {
#               kwi <- match(keywords, toupper(snames), nomatch = 0L)
#               
#               # We could check to see if the database we are connected to is
#               # running in ANSI mode. That would allow double quoted strings
#               # as database identifiers. Until then, the backtick needs to be used.
#               snames[kwi] <- paste("`", snames[kwi], "`", sep = "")
#             }
#             gsub("\\.", "_", snames)
#           },
#           valueClass = "character"
# )
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
