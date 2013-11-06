setClass("SqlServerResult", representation("DBIResult", "SqlServerObject"))

setMethod("dbClearResult", "SqlServerResult", 
          def = function(res, ...) sqlServerCloseResult(res, ...), 
          valueClass = "logical"
)

setMethod("fetch", signature(res="SqlServerResult", n="numeric"),
            out <- sqlServerFetch(res, n, ...)
            if(is.null(out))
              out <- data.frame(out)
            out
          },
          valueClass = "data.frame"
)


setMethod("fetch", 
          signature(res="SqlServerResult", n="missing"),
          def = function(res, ...){
            out <-  sqlServerFetch(res, n =-1, ...)
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



sqlServerFetch <- 
  function(res,n){
    n <- as(n, "integer")
    dataReader <- rClr:::createReturnedObject(res@Id)
    ncols <- clrGet(dataReader,"FieldCount")
    if(ncols==0) return(NULL)
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper",dataReader)
    
    Cnames <- clrGet(sqlDataHelper,'Cnames')
    CDbtypes <- clrGet(sqlDataHelper,'CDbtypes')
    
    out <- if (n < 0L) { ## infinite pull
      out <- lapply(CDbtypes, function(x)
        vector(db2RType(x),length=0L))
      stride <- 32768L  ## start fairly small to support tiny queries and increase later
      while ((nrec <- clrCall(sqlDataHelper,'Fetch',stride)) > 0L) {
        res.Dict <- clrGet(sqlDataHelper,"ResultSet")
        for (i in seq.int(Cnames)){
          out[[i]] <- c(out[[i]], clrCall(res.Dict,'get_Item',Cnames[i]))
        }
        if (nrec < stride) break
        stride <- 524288L # 512k
      }
      out
    } else {
      clrCall(sqlDataHelper,'Fetch',as.integer(n))
      res.Dict <- clrGet(sqlDataHelper,"ResultSet")
      out <- lapply(CDbtypes, function(x)
        vector(db2RType(x),length=n))
      for (i in seq.int(Cnames))
        out[[i]] <- clrCall(res.Dict,'get_Item',Cnames[i])    
      out
    }
    ## set names and convert list to a data.frame
    names(out) <- Cnames
    attr(out, "row.names") <- c(NA_integer_, length(out[[1]]))
    class(out) <- "data.frame"
    out
    
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
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper",res)
    for (prop in clrGetProperties(res))
      info[[prop]] <- clrCall(sqlDataHelper,"GetReaderProperty",
                              prop)
    info <- as.list(unlist(info))
    if(!missing(what))
      info[what]
    else
      info
  }



# setMethod("dbDataType", 
#           signature(dbObj = "SqlServerObject", obj = "ANY"),
#           def = function(dbObj, obj, ...) sqlServerDbType(obj, ...),
#           valueClass = "character"
# )

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
netToRType <- function(obj,...)
{
  switch(obj,
         System.String   = "character",
         System.Int32  = "integer",
         System.Double  = "numeric",
         System.DateTime  = "character",
         "character")
}



setMethod("make.db.names", 
          signature(dbObj="SqlServerObject", snames = "character"),
          def = function(dbObj, snames, keywords = .SqlServersKeywords,
                         unique, allow.keywords, ...){
            makeUnique <- function(x, sep = "_") {
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
              snames[kwi] <- paste("[", snames[kwi], "]", sep = "")
            }
            gsub("\\.", "_", snames)
          },
          valueClass = "character"
)

## TODO complete this function 
## maybe should I create some new R class to handle sql data type
db2RType <- function(obj,...)
{
  switch(obj ,
         "bigint"="numeric",                                                       
         "binary"="integer",                                                       
         "bit"="integer",                                                         
         "char"=  "character",                                                      
         "date"= "Date",                  ##2008++       
         "datetime"="POSIXct",                                                     
         "datetime2"=  "POSIXct",         ##2008++   
         "datetimeoffset"=  "POSIXct",    ##2008++
         "decimal"="numeric",                                                      
         "FILESTREAM attribute (varbinary(max))"= "TODO",                      
         "float"="numeric",                                                        
         "image"=  "TODO",                                                     
         "int"="integer",                                                         
         "money"="character",                                                       
         "nchar"=   "character",                                                     
         "ntext"=   "character",                                                     
         "numeric"="numeric",                                                      
         "nvarchar"=   "character",                                                  
         "real"= "numeric",                                                        
         "rowversion"= "TODO",                                                 
         "smalldatetime"= "POSIXct",                                               
         "smallint"="integer",                                                    
         "smallmoney"= "character",                                                 
         "sql_variant"= "TODO",                                                
         "text"=   "character",                                                      
         "time"= "POSIXct",             ##2008++
         "timestamp"=  "TODO",                                                 
         "tinyint"="integer",                                                     
         "uniqueidentifier"=  "TODO",                                           
         "varbinary"=   "TODO",                                                
         "varchar"=  "character",                                                    
         "xml"= "TODO")  
}

