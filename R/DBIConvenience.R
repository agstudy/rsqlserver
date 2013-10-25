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

setMethod("dbExistsTable", 
          signature(conn="SqlServerConnection", name="character"),
          def = function(conn, name, ...){
            ## TODO: find out the appropriate query to the MySQL metadata
            avail <- dbListTables(conn)
            if(length(avail)==0) avail <- ""
            match(tolower(name), tolower(avail), nomatch=0)>0
          },
          valueClass = "logical"
)

setMethod("dbRemoveTable", 
          signature(conn="SqlServerConnection", name="character"),
          def = function(conn, name, ...){
            if(dbExistsTable(conn, name)){
              rc <- try(dbGetQuery(conn, paste("DROP TABLE", name)))
              !inherits(rc, ErrorClass)
            } 
            else FALSE
          },
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

