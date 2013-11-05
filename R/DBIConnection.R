
##
## Class: DBITransaction
##
setClass("SqlServerTransaction", representation("SqlServerObject"))
setClass("SqlServerConnection", 
         contains=c("DBIConnection", "SqlServerObject"),
         slots=c(trans="externalptr"))


setGeneric("dbTransaction",
           function(conn,name="R.transaction",...)
             standardGeneric("dbTransaction")
)

setMethod("dbTransaction",
          signature(conn='SqlServerConnection',name='character'),
          def=function(conn,name="R.transaction",...){
            if(dbGetInfo(conn,'State')[[1]] ==1){
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
            state = dbGetInfo(conn, "State")[[1]]
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

"sqlServerNewConnection" <-
  function(drv,  username=NULL,
           password=NULL, host=NULL,
           trusted=TRUE, timeout=30)
  {
    if(!isIdCurrent(drv))
      stop("expired manager")
    
    if (!is.null(username) && !is.character(username))
      stop("Argument username must be a string or NULL")
    if (!is.null(password) && !is.character(password))
      stop("Argument password must be a string or NULL")
    if (!is.null(host) && !is.character(host))
      stop("Argument host must be a string or NULL")
    if (is.null(timeout) || !is.numeric(timeout))
      stop("Argument timeout must be an integer value")
    if (is.null(trusted) || !is.logical(trusted))
      stop("Argument client.flag must be a boolean")
    connect.string <- paste(paste0("user id=",username),
                            paste0("password=",password),paste0("server=",host),
                            paste0("Trusted_Connection=",ifelse(trusted,"yes","false")),
                            paste0("connection timeout=",timeout),
                            sep=";")
    id = clrNew("System.Data.SqlClient.SqlConnection",connect.string)
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
    obj <- rClr:::createReturnedObject(conn@Id)
    action = dbListResults(conn)$action
     if(action == "CloseAndOpenMe")  ## broken connection
       obj <- clrCall(obj,'Close')
    obj <- clrCall(obj,'Open')
  }
