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
          valueClass = "MySQLResult"
)

setMethod("dbGetQuery", 
          signature(conn = "SqlServerConnection", statement = "character"),
          def = function(conn, statement, ...) sqlServerQuickSQL(conn, statement, ...)
)




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
