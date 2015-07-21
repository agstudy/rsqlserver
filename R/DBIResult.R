setClass("SqlServerResult", 
         contains=c("DBIResult", "SqlServerObject"),
         slots=c(.fetched="numeric"))
# setMethod("initialize", signature(.Object = "SqlServerResult"),
#           function(.Object, ...){ 
#             .Object@fetched = 0
#           } 

setMethod("dbClearResult", "SqlServerResult", 
          def = function(res, ...) sqlServerCloseResult(res, ...), 
          valueClass = "logical"
)

setMethod("fetch", signature(res="SqlServerResult", n="numeric"),
          def = function(res, n , ...){ 
            out <- .sqlServerFetch(res, n, ...)
            if(is.null(out))
              out <- data.frame(out)
            out
          },
          valueClass = "data.frame"
)


setMethod("fetch", 
          signature(res="SqlServerResult", n="missing"),
          def = function(res, ...){
            out <-  .sqlServerFetch(res, n =-1, ...)
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

setGeneric("dbGetScalar", function(conn, statement, ...){
  value <- standardGeneric("dbGetScalar")
  if (!is.atomic(value) || length(value) > 1L) ## valuecan be NULL 
    stop("not a scalar atomic vector")
  value
})
setMethod("dbGetScalar", 
          signature(conn = "SqlServerConnection", statement = "character"),
          def = function(conn, statement, ...) sqlServerExecScalar(conn, statement, ...),
)


setGeneric("dbNonQuery", function(conn, statement, ...) 
  standardGeneric("dbNonQuery")
)
setMethod("dbNonQuery", 
          signature(conn = "SqlServerConnection", statement = "character"),
          def = function(conn, statement, ...) sqlServerNonQuery(conn, statement, ...)
)



setMethod("dbGetInfo", "SqlServerResult",
          def = function(dbObj, ...) sqlServerResultInfo(dbObj, ...),
          valueClass = "list"
)

setGeneric("dbBulkCopy", function(conn,name,value,...) 
  standardGeneric("dbBulkCopy")
)

setMethod("dbBulkCopy",
          signature(conn ="SqlServerConnection",value="data.frame",name="character"),
          def = function(conn,name,value,...)   bulk.copy(conn,name,value,...)
)
setMethod("dbBulkCopy",
          signature(conn ="SqlServerConnection",value="character",name="character"),
          def = function(conn,name,value,...)   bulk.copy.file(conn,name,value,...)
)


setGeneric("dbCallProcedure",
           function(conn,name,...)
             standardGeneric("dbCallProcedure"))

setMethod("dbCallProcedure",
          signature(conn="SqlServerConnection",name="character"),
          def =function(conn,name,...) .sqlExecuteProc(conn,name,...)
)


.sqlExecuteProc <- 
  function(con,name,...){
    .NotYetImplemented()
  }




### internal implementations
### helper functions

get.command <- function(conn,stmt,...){
  if(!isIdCurrent(conn)){
    warning(paste("expired SqlServerConnection"))
    return(TRUE)
  }
  clr.conn <- .NetObjFromPtr(conn@Id)
  cmd <- clrNew("System.Data.SqlClient.SqlCommand",stmt,clr.conn)
  ll <- as.list(match.call()[-1])
  if(("timeout") %in% names(ll))
    clrSet(cmd,"CommandTimeout",as.integer(ll[["timeout"]]))
  if(isTransaction(conn)){
    trans <- .NetObjFromPtr(conn@trans)
    clrCall(cmd,'set_Transaction',trans)
  }
  cmd
}


sqlServerExecStatement <- 
  function(conn,statement,...)
  {
    cmd <- get.command(conn,statement,...)
    res <- try(clrCall(cmd,'ExecuteReader'),silent=TRUE)
    if (inherits(res, "try-error")){
      stop(sqlException.Message(res))
    }
    new("SqlServerResult", Id = clrGetExtPtr(res),.fetched=0)
  }

sqlServerExecScalar <- 
  function(conn,statement,...)
  {
    cmd <- get.command(conn,statement,...)
    res <- try(clrCall(cmd,'ExecuteScalar'),silent=TRUE)
    
    if (inherits(res, "try-error")){
      stop(sqlException.Message(res))
    }
    res
    
  }

sqlServerNonQuery <- 
  function(conn,statement,...)
  {
    cmd <- get.command(conn,statement,...)
    res <- try(clrCall(cmd,'ExecuteNonQuery'),silent=TRUE)
    if (inherits(res, "try-error")){
      stop(sqlException.Message(res))
    }
  }





sqlException.Message <- 
  function(exception){
    message <- 
      if(inherits(exception,'simpleError'))
        message(exception)
    else conditionMessage(attr(exception,"condition"))
    readLines(textConnection(message),n=2)[2]
  }


.sqlServerFetch <- 
  function(res,n){
    n <- as(n, "integer")
    dataReader <- .NetObjFromPtr(res@Id)
    ncols <- clrGet(dataReader,"FieldCount")
    if(ncols==0) return(NULL)
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper",dataReader)
    Cnames <- clrGet(sqlDataHelper,'Cnames')
    out <- vector('list',ncols)
    out <- if (n < 0L) { ## infinite pull
      stride <- 32768L  ## start fairly small to support tiny queries and increase later
      while ((nrec <- clrCall(sqlDataHelper,'Fetch',stride)) > 0L) {
        res.Dict <- clrGet(sqlDataHelper,"ResultSet")
        for (i in seq.int(Cnames)){
          out[[i]] <- if(is.null(out[[i]]))
            clrCall(res.Dict,'get_Item',Cnames[i])
          else 
            c(out[[i]], clrCall(res.Dict,'get_Item',Cnames[i]))
        }
        res@.fetched <- res@.fetched + nrec
        if (nrec < stride) break
        stride <- 524288L # 512k
      }
      out
    } 
    else { 
      nrec <- clrCall(sqlDataHelper,'Fetch',as.integer(n))
      res@.fetched <- res@.fetched +nrec
      res.Dict <- clrGet(sqlDataHelper,"ResultSet")
      for (i in seq.int(Cnames))
        out[[i]] <- clrCall(res.Dict,'get_Item',Cnames[i])    
      out
    }
    ## process missing values
    CDbtypes <- clrGet(sqlDataHelper,'CDbtypes')
    char.cols <- grep('char',CDbtypes)
    
    out[char.cols] <- lapply(out[char.cols],
                             function(x) ifelse(nchar(x)==0,NA_character_,x))
    ## process date type 
    rtypes <- tolower(sapply(CDbtypes,db2RType))
    ## POSIXct 
    date.cols <- grep('date',rtypes)
    out[date.cols] <- lapply(out[date.cols],as.Date,tz=Sys.timezone())
    
    ## set names and convert list to a data.frame
    names(out) <- Cnames
    attr(out, "row.names") <- c(NA_integer_, length(out[[1]]))
    class(out) <- "data.frame"
    out
    
  }




sqlServerCloseResult <- 
  function(res,...){
    dataReader <- .NetObjFromPtr(res@Id)
    clrCall(dataReader,"Close")
    TRUE
  }




## helper function: it exec's *and* retrieves a statement. It should
## be named somehting else.
sqlServerExecRetrieve <-
  function(con, statement,...)
  {
    state <- dbGetInfo(con,"State")
    if(state=="Closed"){                   ## conn is closed
      new.con <- dbConnect(con)     ## yep, create a clone connection
      on.exit(dbDisconnect(new.con))
      rs <- dbSendQuery(new.con, statement,...)
    } else rs <- dbSendQuery(con, statement,...)
    res <- fetch(rs, n = -1)
    dbClearResult(rs)
    res
  }





sqlServerResultInfo <- 
  function(dbObj,what,...){
    if(!isIdCurrent(dbObj))
      stop(paste("expired", class(dbObj), deparse(substitute(dbObj))))
    res <- .NetObjFromPtr(dbObj@Id)
    info <- vector("list", length = length(clrGetProperties(res)))
    sqlDataHelper <- clrNew("rsqlserver.net.SqlDataHelper",res)
    for (prop in c(clrGetProperties(sqlDataHelper),'Fetched'))
      info[[prop]] <- clrCall(sqlDataHelper,paste0("get_",prop))
    info <- as.list(unlist(info))
    if(!missing(what))
      info[[what]]
    else
      info
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
         "char"=  "factor",                                                      
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

R2DbType <- function(obj,...)
{
  class.obj <- ifelse(length(class(obj))==1,
                      tolower(class(obj)),
                      tolower(class(obj)[1]))
  
  switch(class.obj,
         integer   = "int",
         factor    = "char(12)" ,
         numeric   = "float",
         posixct   = "datetime2",   ## not datatime to manage fractional seconds
         posixlt   = "datetime2",   ## not datatime to manage fractional seconds
         date      = "date",
         character = "varchar(128)",
         list      = "varbinary(2000)",
         stop(gettextf("rsqlserver internal error [%s, %d, %s]",
                       "R2DbType", 1L, class(obj))))    
  
}

sqlServer.data.frame <- function(obj,field.types)
{
  out <- lapply(seq_along(field.types),function(x){
    dbtype <- field.types[[x]]
    col <- obj[[x]]
    DATE_TYPES <- c("datetime","datetime2","datetimeoffset","date")
    col <- {
      if(dbtype %in% DATE_TYPES) 
        paste0("'",col,"'")
      else if(grepl("char",dbtype))  {
        col[is.na(col)] <- ''
        paste0("'",gsub("'","''",col),"'")
      }
      else col
    }
  })
  
  attr(out, "row.names") <- c(NA_integer_, length(out[[1]]))
  attr(out, "names") <- names(field.types)
  class(out) <- "data.frame"
  out
}


