## convenience methods 




setMethod("dbListTables", "SqlServerConnection",
          def = function(conn, ...){
            tbls <- dbGetQuery(conn, "select * from sys.tables")
            if(length(tbls)>0) 
              tbls <- tbls[,1]
            else
              tbls <- character()
            tbls
          },
          valueClass = "character"
)

setMethod("dbReadTable", signature(conn="SqlServerConnection", name="character"),
          def = function(conn, name, ...) sqlServerReadTable(conn, name, ...),
          valueClass = "data.frame"
)

setMethod("dbWriteTable", 
          signature(conn="SqlServerConnection", name="character", value="data.frame"),
          def = function(conn, name, value, ...){
            sqlServerWriteTable(conn, name, value, ...)
          },
          valueClass = "logical"
)

## write table from filename (TODO: connections)
setMethod("dbWriteTable", 
          signature(conn="SqlServerConnection", name="character", value="character"),
          def = function(conn, name, value, ...){
            sqlServerImportFile(conn, name, value, ...)
          },
          valueClass = "logical"
)
## TODO : manage case here
setMethod("dbExistsTable", 
          signature(conn="SqlServerConnection", name="character"),
          def = function(conn, name, ...){
            req <- paste0("SELECT OBJECT_ID('",name,"','U') AS 'Object ID';")
            val <- dbGetScalar(conn, req)
            !is.null(val)
          },
          valueClass = "logical"
)



setMethod("dbRemoveTable", 
          signature(conn="SqlServerConnection", name="character"),
          def = function(conn,name,...)dropTable(conn,name,...) ,
          valueClass = "logical"
)





## return field names (no metadata)
setMethod("dbListFields", 
          signature(conn="SqlServerConnection", name="character"),
          def = function(conn, name, ...){
            flds <- dbGetQuery(conn, paste("describe", name))[,1]
            if(length(flds)==0)
              flds <- character()
            flds
          },
          valueClass = "character"
)

##############################################################
### implementations
##############################################################

sqlServerReadTable <- 
  function(con, name, row.names = "row_names", check.names = TRUE, ...)
    ## Use NULL, "", or 0 as row.names to prevent using any field as row.names.
  {
    out <- dbGetQuery(con, paste("SELECT * from", name))
    if(check.names)
      names(out) <- make.names(names(out), unique = TRUE)
    ## should we set the row.names of the output data.frame?
    nms <- names(out)
    j <- switch(mode(row.names),
                "character" = if(row.names=="") 0 else
                  match(tolower(row.names), tolower(nms), 
                        nomatch = if(missing(row.names)) 0 else -1),
                "numeric" = row.names,
                "NULL" = 0,
                0)
    if(j==0) 
      return(out)
    if(j<0 || j>ncol(out)){
      warning("row.names not set on output data.frame (non-existing field)")
      return(out)
    }
    rnms <- as.character(out[,j])
    if(all(!duplicated(rnms))){
      out <- out[,-j, drop = FALSE]
      row.names(out) <- rnms
    } else warning("row.names not set on output (duplicate elements in field)")
    out
  } 

## the following is almost exactly from the RMysql driver 

sqlServerWriteTable <-
  function(con, name, value, field.types, row.names = TRUE, 
           overwrite = FALSE, append = FALSE, ..., allow.keywords = FALSE)
  {
    
    if(overwrite && append)
      stop("overwrite and append cannot both be TRUE")
    # validate name
    name <- as.character(name)
    if (length(name) != 1L)
      stop("'name' must be a single string")
    
    #
    
    if(row.names){
      value <- cbind(row.names(value), value)  ## can't use row.names= here
      names(value)[1] <- "row.names"
    }
    
    value <- sqlServer.data.frame(value)
    if(missing(field.types) || is.null(field.types)){
      field.types <- lapply(value, sqlServerDbType)
    } 
    
    
#     i <- match("row.names", names(field.types), nomatch=0)
#     if(i>0) field.types[i] <- sqlServerDbType(obj=field.types$row.names)
    names(field.types) <- make.db.names(con, names(field.types), 
                                        allow.keywords = allow.keywords)

    ## Do we need to clone the connection (ie., if it is in use)?
    if(length(dbListResults(con))!=0){ 
      new.con <- dbConnect(con)
      on.exit(dbDisconnect(new.con))
    } else {
      new.con <- con
    }
    con <- dbTransaction(new.con,name='newTableTranst')
    cnames <- names(field.types)
    ctypes <- field.types
    
    if (dbExistsTable(con, name)){
      if (overwrite)
      {
        dbRemoveTable(con, name)
        dbCreateTable(con, name, cnames, ctypes)
      }
      else if (append)
        drop <- FALSE
      else
        stop("table or view already exists")
    }
    else
      dbCreateTable(con, name, cnames, ctypes)
    
    res <- tryCatch({
      ## INSERT INTO MyTable (col, col2) 
      ##   VALUES (1, 'Bob'), (2, 'Peter'), (3, 'Joe');
      stmt <- sprintf('INSERT INTO %s (%s)', name, 
                          paste(cnames,collapse=','))
      values <- paste0('VALUES (',do.call(paste, c(value, sep=",",collapse='),(')),')')
      stmt = paste(stmt,values,sep='\n')
      browser()      
      dbGetScalar(con, stmt, data = value)
      dbCommit(con)}, 
            error = function(e) {
              browser()
              dbRollback(con)
            }
    )



  }


sqlServer.dbTypeCheck <- function(obj)
{
  (inherits(obj, c("logical", "integer", "numeric", "character",
                   "POSIXct")) ||
     (is.list(obj) && all(unlist(lapply(obj, is.raw), use.names = FALSE))))
}

sqlServer.data.frame <- function(obj)
{
  if (!is.data.frame(obj))
    obj <- as.data.frame(obj)
  for (i in seq_len(ncol(obj)))
  {
    col <- obj[[i]]
    if (!sqlServer.dbTypeCheck(col))
    {
      if (inherits(col, "Date"))
        obj[[i]] <- as.POSIXct(as.POSIXlt(col), tz = "")  # use local time zone
      else
        obj[[i]] <- as.character(col)
    }
    col <- obj[[i]]
    if(inherits(col,'character')){
      obj[[i]] <- paste0("'",gsub("'","''",col),"'")
    }
  }
  obj
}

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


dbCreateTable <- function(con, name, cnames, ctypes)
{
  stmt <- sprintf('CREATE TABLE "%s" (%s)', name,
                  paste(cnames, ctypes, collapse = ","))
  dbGetQuery(con, stmt)
}

dropTable <- function(con, name,...)
{
  # validate name
  name <- as.character(name)
  if (length(name) != 1L)
    stop("'name' must be a single string")
  if(dbExistsTable(conn, name)){
    rc <- try( {stmt <- sprintf('DROP TABLE "%s"', name)
                dbGetScalar(con, stmt)})
    !inherits(rc, "try-error")
  }else FALSE
}


