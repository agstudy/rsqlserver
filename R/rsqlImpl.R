

"sqlServerInitDriver" <-
  function(max.con = 16, fetch.default.rec = 500, force.reload=FALSE,
           shared.cache=FALSE)
    ## return a manager id
  {
    config.params <- as.integer(c(max.con, fetch.default.rec))
    force <- as.logical(force.reload)
    cache <- as.logical(shared.cache)
    clrLoadAssembly('System.Data')
    new("SqlServerDriver", Id = clrGetExtPtr(clrNew('System.Object')))
  }


"sqlServerDriverInfo" <-
  function(obj, what="", ...)
  {
    if(!isIdCurrent(obj))
      stop(paste("expired", class(obj)))
#     drvId <- as(obj, "integer")
#     info <- .Call("RS_MySQL_managerInfo", drvId, PACKAGE = .MySQLPkgName)  
#     ## replace drv/connection id w. actual drv/connection objects
#     conObjs <- vector("list", length = info$"num_con")
#     ids <- info$connectionIds
#     for(i in seq(along = ids))
#       conObjs[[i]] <- new("MySQLConnection", Id = c(drvId, ids[i]))
#     info$connectionIds <- conObjs
#     info$managerId <- new("MySQLDriver", Id = drvId)
#     if(!missing(what))
#       info[what]
#     else
#       info
    TRUE
  }




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
   clrCall(id,'Open')
 	 new("SqlServerConnection", Id = clrGetExtPtr(id))
}


"sqlServerCloseConnection" <-
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


"sqlServerExecStatement" <- 
  function(conn,statement,...)
  {
    if(!isIdCurrent(conn)){
      warning(paste("expired SqlServerConnection"))
      return(TRUE)
    }
    connection <- rClr:::createReturnedObject(conn@Id)
    cmd <- clrNew("System.Data.SqlClient.SqlCommand",statement,connection)
    dataReader <- clrCall(cmd,'ExecuteReader')
    new("SqlServerResult", Id = clrGetExtPtr(dataReader))
    
  }

"sqlServerFetch" <- 
function(res,n){
  n <- as(n, "integer")
  dataReader <- rClr:::createReturnedObject(res@Id)
  if(clrGet(dataReader,'HasRows')==0) 
    return(NULL)
  ncols <- clrGet(dataReader,"FieldCount")
  if(ncols==0) return(NULL)
  cnt <- 0
  res <- data.frame()
  datarow <- vector(mode='list',ncols)
  while (clrCall(dataReader,"Read"))
  {
    for( i in seq_len(ncols)-1)
    {
      datarow[i+1] <- tryCatch(clrCall(dataReader,'get_Item',as.integer(i)),
               error=function(e)NULL)
    }
    if(length(res)==0) res <- datarow else res <- rbind(res,datarow)
    cnt <- cnt +1 
  }
  rownames(res) <- as.integer(seq_len(cnt))
  as.data.frame(res)
}

"sqlServerCloseResult" <- 
  function(res,...){
    dataReader <- rClr:::createReturnedObject(res@Id)
    clrCall(dataReader,"Close")
    TRUE
  }




## helper function: it exec's *and* retrieves a statement. It should
## be named somehting else.
"sqlServerQuickSQL" <-
  function(con, statement)
  {
    if(!isIdCurrent(con))
      stop(paste("expired", class(con)))
    nr <- length(dbListResults(con))
    if(nr>0){                     ## are there resultSets pending on con?
      new.con <- dbConnect(con)   ## yep, create a clone connection
      on.exit(dbDisconnect(new.con))
      rs <- dbSendQuery(new.con, statement)
    } else rs <- dbSendQuery(con, statement)
    if(dbHasCompleted(rs)){
      dbClearResult(rs)            ## no records to fetch, we're done
      invisible()
      return(NULL)
    }
    res <- fetch(rs, n = -1)
    if(dbHasCompleted(rs))
      dbClearResult(rs)
    else 
      warning("pending rows")
    res
  }


    