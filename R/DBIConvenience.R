## convenience methods 




setMethod("dbListTables", "SqlServerConnection",
          def = function(conn, ...){
            tbls <- dbGetQuery(conn, "select name from sys.tables")
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

describe.query <- 
   "SELECT 
    c.name Column_Name,
    t.Name Data_type,
    CAST(c.max_length as int)Max_Length,
    CAST(c.precision as int) precision,
    CAST(c.scale as int) scale,
    CAST( c.is_nullable as int), 
    CAST(ISNULL(i.is_primary_key, 0) as int)  isKey
    FROM    
    sys.columns c
    INNER JOIN 
    sys.types t ON c.system_type_id = t.system_type_id
    LEFT OUTER JOIN 
    sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    LEFT OUTER JOIN 
    sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE
    c.object_id = OBJECT_ID('%s')"



## return field names (no metadata)
setMethod("dbListFields", 
          signature(conn="SqlServerConnection", name="character"),
          def = function(conn, name, ...){
            flds <- dbGetQuery(conn, sprintf(describe.query, name))[,1]
            if(length(flds)==0)
              flds <- character()
            flds
          },
          valueClass = "character"
)


# implementations ---------------------------------------------------------



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
    rnms <- out[,j]
    if(all(!duplicated(rnms))){
      out <- out[,-j, drop = FALSE]
      attr(out, "row.names") <- rnms
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
    if(row.names)
    {
      row_names = attr(value,"row.names")
      value <- cbind(row_names=row_names, value)  
      attr(value$row_names,"class") <- attr(row_names,"class")
    }
    
    if(missing(field.types) || is.null(field.types)){
      field.types <- lapply(value, R2DbType)
    }
    names(field.types) <- make.db.names(con, names(field.types), 
                                        allow.keywords = allow.keywords)
    
    
    value <- sqlServer.data.frame(value,field.types)
    
    ## Do we need to clone the connection (ie., if it is in use)?
    if(length(dbListResults(con))!=0){ 
      new.con <- dbConnect(con)
      on.exit(dbDisconnect(new.con))
    } else {
      new.con <- con
    }
    ## con <- dbTransaction(new.con,name='sqlServerWriteTable')
    cnames <- names(field.types)
    ctypes <- field.types
    res <- tryCatch({
      (function(con,name,cnames,ctypes){
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
      })(con,name,cnames,ctypes)
      insert.into(con,name,cnames,value,row.names)
      TRUE
      ##   dbCommit(con)
    },error = function(e) {
      stop(sqlException.Message(e))
    })
  }




insert.into <- function(con,name,cnames,value,row.names){
  
  if(nrow(value)<1000) {
    stmt.header <- sprintf('INSERT INTO %s (%s)', name, 
                    paste(cnames,collapse=','))
    is.char <- sapply(value,is.character)
    replace.missings <- 
      function(x)ifelse(is.na(x),'',x)
    value[is.char] <- vapply(value[is.char],replace.missings,
           rep('character',nrow(value)))
    stmt.body <- paste0('VALUES (',do.call(paste, 
                              c(value, sep=",",collapse='),(')),')')
    ## numeric missing values replaced by NULL
    if(any(is.na(value)))
      stmt.body <- gsub('NA','NULL',stmt.body)
    stmt = paste(stmt.header,stmt.body,sep='\n')
    dbNonQuery(con, stmt, data = value)
  }else{
    ##dbCommit(con)
    bulk.copy(con,name,value)
  }
}


bulk.copy <- function(con,name,value,...){
  if(is.data.frame(value)){
    id = tempfile()                    
    on.exit(unlink(id))
    write.csv(value,file=id,row.names=FALSE,na="",...)
    bulk.copy.file(con,name,id)
  }
}

bulk.copy.file <- function(con,name,value,headers=TRUE,delim=","){
  con.string = dbGetInfo(con)$ConnectionString
  if (!dbExistsTable(con,name))
    stop("bulk copy table does not exist")
  if (!is.null(value) && file.exists(value))
    lapply(value, function(x) clrCallStatic("rsqlserver.net.misc","SqlBulkCopy",con.string,x,name,headers,delim))
  else
    stop("one or more files are null or do not exist")
  
}

bulk.write.file <- function(con,name,value,headers=TRUE,delim=","){
  con.string = dbGetInfo(con)$ConnectionString
  if (!dbExistsTable(con, name))
    stop("table does not exist")
  else if (file.exists(value))
    file.remove(value)
  clrCallStatic("rsqlserver.net.misc","SqlBulkWrite",con.string,value,name,headers,delim)
  
}




dbCreateTable <- function(con, name, cnames, ctypes)
{
    stmt <- sprintf('CREATE TABLE "%s" (%s)', name,
                    paste(cnames, ctypes, collapse = ","))
    if(!dbExistsTable(con, name)){
      rc <- try(dbNonQuery(con, stmt),silent=TRUE)
      !inherits(rc, "try-error")
    }else FALSE
}

dropTable <- function(con, name,...)
{
  # validate name
  name <- as.character(name)
  if (length(name) != 1L)
    stop("'name' must be a single string")
  if(dbExistsTable(con, name)){
    rc <- try({stmt <- sprintf('DROP TABLE "%s"', name)
               dbNonQuery(con, stmt)})
    !inherits(rc, "try-error")
  }else FALSE
}

dropProc  <- function(con,sp.name){
  line1 <- paste0("IF NOT EXISTS (SELECT * FROM sys.objects",
         " WHERE object_id = OBJECT_ID(N'[",
         sp.name,"]') AND type in (N'P', N'PC'))")
  line2 <- paste0("DROP PROCEDURE [",sp.name,"]")
  stmt = paste(line1,line2,sep='\n')
  rc <- try(dbNonQuery(con, stmt))
  !inherits(rc, "try-error")
}

