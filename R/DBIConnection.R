##
## Class: DBITransaction
##

setClass("SqlServerTransaction", contains=c("SqlServerObject"))
setClass("SqlServerConnection", 
         contains=c("DBIConnection", "SqlServerObject"),
         slots=c(trans="externalptr")
)


setGeneric("dbTransaction",
           function(conn,name="R.transaction",...)
             standardGeneric("dbTransaction")
)

setMethod("dbTransaction",
          signature(conn='SqlServerConnection',name='character'),
          def=function(conn,name="R.transaction",...){
            if(dbGetInfo(conn,'State')$State ==1){
              clr.conn <- rClr:::createReturnedObject(conn@Id)
              trans <- clrCall(clr.conn,"BeginTransaction",name)
              Id = clrGetExtPtr(trans)
              return(new("SqlServerConnection", 
                         Id = conn@Id,
                         trans=clrGetExtPtr(trans)))
              
            }
            return(NULL)
          },
          valueClass = "SqlServerConnection"
)


setMethod("dbCommit",
          signature(conn="SqlServerConnection"),
          function(conn, ...) {
            transaction <- rClr:::createReturnedObject(conn@trans)
            clrCall(transaction,'Commit')
            TRUE
          }
)

setMethod("dbRollback",
          signature(conn = "SqlServerConnection"),
          function(conn, ...) {
            transaction <- rClr:::createReturnedObject(conn@trans)
            clrCall(transaction,'Rollback')
            TRUE
          }
)


##
## Class: DBIConnection
##



setMethod("dbConnect", "SqlServerDriver",
          def = function(drv, ...) {
            args <- list(...)
            if ("url" %in% names(args) && !is.null(args$url))
              sqlServerConnectionUrl(args$url)
            else
              sqlServerNewConnection(drv, ...)
          },
          valueClass = "SqlServerConnection"
)

setMethod("dbConnect", "character",
          def = function(drv, ...) dbConnect(dbDriver(drv), ...),
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





# the sql server connection is managed by 
# enum ConnectionState
#   Closed = 0,
#   Open = 1,
#   Connecting = 2,
#   Executing = 4,
#   Fetching = 8,
#   Broken = 16,
setMethod("dbListResults", "SqlServerConnection",
          def = function(conn, ...) {
            state = dbGetInfo(conn, "State")$State
            switch(state ,
                   "1"  = NULL,
                   "0"  = list(action='OpenMe'),
                   "16" = list(action='CloseAndOpenMe'))
          }
)

setMethod("summary", "SqlServerConnection",
          def = function(object, ...) sqlServerDescribeConnection(object, ...)
)
setMethod("dbGetException", "SqlServerConnection",
          def = function(conn, ...){
            if(!isIdCurrent(conn))
              stop(paste("expired", class(conn)))
          },
          valueClass = "list"
)


## TODO use SqlConnectionStringBuilder Class (.net 4.5) 
## http://msdn.microsoft.com/en-us/library/system.data.sqlclient.sqlconnectionstringbuilder.aspx

sqlServerNewConnection <-
  function(drv, user=NULL,
           password=NULL, host=NULL,
           trusted=FALSE, 
           dbname='TEST_RSQLSERVER',
           timeout=30,...)
  {
    if(!isIdCurrent(drv))
      stop("expired manager")
    if (!is.null(host) && !is.character(host))
      stop("Argument host must be a string or NULL")
    if (is.null(timeout) || !is.numeric(timeout))
      stop("Argument timeout must be an integer value")
    if (is.null(trusted) || !is.logical(trusted))
      stop("Argument trusted must be a boolean")
    url <- {
      url <- paste(paste0("server=",host),
                   paste0("connection timeout=",timeout),
                   sep=";")
      
      if(!trusted){
        if (!is.null(password) && !is.character(password))
          stop("Argument password must be a string or NULL")
        if (!is.null(user) && !is.character(user))
          stop("Argument username must be a string or NULL")
        url <- paste(url,paste0("user id=",user),
                     paste0("password=",password),sep=';')    
      }else
        url <- paste(url , "Trusted_Connection=yes",sep=';')
      if (!is.null(dbname) && is.character(dbname))
        url <- paste(url,paste0("Database=",dbname),sep=";")
      url
    }
    sqlServerConnectionUrl(url)
  }

sqlServerConnectionUrl <- 
  function(url){
    if (is.null(url) || !is.character(url))
      stop("Argument url must be a not NULL string ")
    
    id = clrNew("System.Data.SqlClient.SqlConnection",url)
    trans = clrNew('System.Object')
    clrCall(id,'Open')
    new("SqlServerConnection", 
        Id = clrGetExtPtr(id),
        trans = clrGetExtPtr(trans))
  }


sqlServerCloseConnection <-
  function(conn,...)
  {
    if(!isIdCurrent(conn)){
      warning(paste("expired SqlServerConnection"))
      return(TRUE)
    }
    obj <- rClr:::createReturnedObject(conn@Id)
    clrCall(obj,'Close')
    TRUE
  }


sqlServerConnectionInfo <- 
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


sqlServerCloneConnection <-
  function(conn,...){
    strConnection = dbGetInfo(conn)$ConnectionString
    sqlServerConnectionUrl(strConnection)
  }
