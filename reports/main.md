rsqlserver documentation
========================================================
The rsqlserver package is an implementation of the R DBI package to access SQL server data base, that
uses the.NET Framework Data Provider for high preformance and scalability with SQL Server data base.
In fact , using thee [Rclr package](https://rclr.codeplex.com/), rsqlserver access to System.Data.SqlClient namespace.

It requires:

* R 3.0 or above. May work with earlier version
* .NET 4.0
* MS Visual C++ 2012 runtime


It presentes:

* Connection to Sql server
* Querying the data base : low levels functions using sql statement.
* Higher level convenient functions that support read, save, copy, and manipulation of data between R data.frame objects and database tables.
* Transaction management to commit and rollback
* Stored procedure call ( not yet implemented)
* Uses named parameters in the format @parametername to pass values to SQL statements or stored procedures. 
This will provide better type checking and imporve performance. (not yet implemented)




```r
library(rsqlserver)
```

## Typical scenario

A typical use of the rsqlserver package is :

* Open a connection 
* Execute a query 
* Extract the query result in a data.frame
* Close the query result
* Close the connection



```r
drv <- dbDriver("SqlServer")
conn <- dbConnect(drv, user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
query <- "SELECT  name,object_id,create_date \n          FROM    sys.tables"
res <- dbSendQuery(conn, query)
res.dat <- fetch(res)
invisible(dbClearResult(res))
invisible(dbDisconnect(conn))
head(res.dat)
```

```
##                       name object_id         create_date
## 1 BM_INDICE_COMPOSITION_ID   7671075 2010-12-08 01:55:03
## 2    BM_INDICE_COMPOSITION  39671189 2010-12-08 01:55:03
## 3                BM_INDICE  71671303 2010-12-08 01:55:03
## 4           BM_GERANT_USER 103671417 2010-12-08 01:55:03
## 5          spt_fallback_db 117575457 2003-04-08 07:18:01
## 6         spt_fallback_dev 133575514 2003-04-08 07:18:02
```


In practice , we don't fetch results manullay and we use the handy function `dbGetQuery`
To simplify the previous example to : 



```r
query <- "SELECT  name,object_id,create_date \n          FROM    sys.tables"
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
res <- dbGetQuery(conn, query)
invisible(dbDisconnect(conn))
head(res)
```

```
##                       name object_id         create_date
## 1 BM_INDICE_COMPOSITION_ID   7671075 2010-12-08 01:55:03
## 2    BM_INDICE_COMPOSITION  39671189 2010-12-08 01:55:03
## 3                BM_INDICE  71671303 2010-12-08 01:55:03
## 4           BM_GERANT_USER 103671417 2010-12-08 01:55:03
## 5          spt_fallback_db 117575457 2003-04-08 07:18:01
## 6         spt_fallback_dev 133575514 2003-04-08 07:18:02
```


## Connections
To create a connection, you should call dbConnect. Here some example:


```r
drv <- dbDriver("SqlServer")
conn <- dbConnect(drv, user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
dbDisconnect(conn)
```

```
## [1] TRUE
```

```r
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
dbDisconnect(conn)
```

```
## [1] TRUE
```


to retrieve information about the connection , you can do this :

```r
drv <- dbDriver("SqlServer")

conn <- dbConnect(drv, user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
dbGetInfo(conn)
```

```
## $ClientConnectionId
## [1] "efbe861e-4ad8-46df-8362-3a1263130f6a"
## 
## $ConnectionString
## [1] "user id=collateral;server=localhost;Trusted_Connection=yes;connection timeout=30"
## 
## $ConnectionTimeout
## [1] "30"
## 
## $Database
## [1] "master"
## 
## $DataSource
## [1] "localhost"
## 
## $FireInfoMessageEventOnUserErrors
## [1] "FALSE"
## 
## $PacketSize
## [1] "8000"
## 
## $ServerVersion
## [1] "10.00.1600"
## 
## $State
## [1] "1"
## 
## $StatisticsEnabled
## [1] "FALSE"
## 
## $WorkstationId
## [1] "AGBRANDING-PC"
```

```r
dbGetInfo(conn, "State")
```

```
## $State
## [1] "1"
```

```r
dbDisconnect(conn)
```

```
## [1] TRUE
```

```r
dbGetInfo(conn, "State")
```

```
## $State
## [1] "0"
```



## SQL Results

Use dbGetInfo to retrieve the result state. 


```r
drv <- dbDriver("SqlServer")
conn <- dbConnect(drv, user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
res <- dbSendQuery(conn, "select * from sys.tables")
dbGetInfo(res, "HasRows")
```

```
## $HasRows
## [1] 1
```

```r
dbHasCompleted(res)
```

```
## [1] FALSE
```

```r
dbClearResult(res)
```

```
## [1] TRUE
```

```r
dbHasCompleted(res)
```

```
## Error: Type:    System.InvalidOperationException
## Message: Tentative d'appel de Depth non valide lorsque le lecteur est fermé.
## Method:  Int32 get_Depth()
## Stack trace:
##    à System.Data.SqlClient.SqlDataReader.get_Depth()
```

```r
dbDisconnect(conn)
```

```
## [1] TRUE
```

```r

```


then you can fetch the result.



```r

drv <- dbDriver("SqlServer")
conn <- dbConnect(drv, user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
res <- dbSendQuery(conn, "select * from sys.tables")
if (!dbHasCompleted(res)) res.dat <- fetch(res, 4)  ## retrieve only 4 rows
```

```
## Error: Type:    System.InvalidCastException
## Message: Impossible de stocker l'objet dans un tableau de ce type.
## Method:  Void InternalSetValue(Void*, System.Object)
## Stack trace:
##    à System.Array.InternalSetValue(Void* target, Object value)
##    à System.Array.SetValue(Object value, Int32 index)
##    à rsqlserver.net.SqlDataHelper.Fetch(SqlDataReader dr)
```

```r

dbClearResult(res)
```

```
## [1] TRUE
```

```r
dbDisconnect(conn)
```

```
## [1] TRUE
```



## Convenience functions for Importing/Exporting DBMS tables

These functions mimic their R/Splus counterpart get, assign, exists, remove, and objects, except that they generate code that gets remotely executed in a database engine.

*  `dbReadTable(conn, name, ...)`
*  `dbWriteTable(conn, name, value, ...)`
*  `dbExistsTable(conn, name, ...)`
*  `dbRemoveTable(conn, name, ...)`

To check if a table already exist:


```r

conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
res <- dbExistsTable(conn, "BM_INDICE")
dbDisconnect(conn)
```

```
## [1] TRUE
```



to read a sql server table as a data.frame


```r
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)

rs <- dbSendQuery(conn, "SELECT * FROM BM_INDICE")
dat.rs <- fetch(rs, n = -1)
```

```
## Error: Type:    System.NullReferenceException
## Message: La référence d'objet n'est pas définie à une instance d'un objet.
## Method:  System.Collections.Generic.Dictionary`2[System.String,System.Array] Fetch(System.Data.SqlClient.SqlDataReader)
## Stack trace:
##    à rsqlserver.net.SqlDataHelper.Fetch(SqlDataReader dr)
```

```r
dbClearResult(rs)
```

```
## [1] TRUE
```

```r
dbDisconnect(conn)
```

```
## [1] TRUE
```

Or sipmly use the convenient function dbReadTable


```r
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
res <- dbReadTable(conn, "BM_INDICE")
```

```
## Error: Type:    System.NullReferenceException
## Message: La référence d'objet n'est pas définie à une instance d'un objet.
## Method:  System.Collections.Generic.Dictionary`2[System.String,System.Array] Fetch(System.Data.SqlClient.SqlDataReader)
## Stack trace:
##    à rsqlserver.net.SqlDataHelper.Fetch(SqlDataReader dr)
```

```r

dbDisconnect(conn)
```

```
## [1] TRUE
```



you have 2 methods to create a new table 



```r
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
if (!dbExistsTable(conn, "MYTABLE")) {
    rs <- dbSendQuery(conn, "CREATE TABLE MYTABLE ( myvar varchar(1) )")
    dbClearResult(rs)
}
dbReadTable(conn, "MYTABLE")
```

```
## Error: Type:    System.NullReferenceException
## Message: La référence d'objet n'est pas définie à une instance d'un objet.
## Method:  System.Collections.Generic.Dictionary`2[System.String,System.Array] Fetch(System.Data.SqlClient.SqlDataReader)
## Stack trace:
##    à rsqlserver.net.SqlDataHelper.Fetch(SqlDataReader dr)
```

```r
dbDisconnect(conn)
```

```
## [1] TRUE
```


Since the creation of a table does not retuen a result, it is better to 
use dbGetScalar.

```r
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
if (!dbExistsTable(conn, "MYTABLE1")) dbGetScalar(conn, "CREATE TABLE MYTABLE1 ( myvar varchar(1) )")
dbReadTable(conn, "MYTABLE1")
```

```
## Error: Type:    System.NullReferenceException
## Message: La référence d'objet n'est pas définie à une instance d'un objet.
## Method:  System.Collections.Generic.Dictionary`2[System.String,System.Array] Fetch(System.Data.SqlClient.SqlDataReader)
## Stack trace:
##    à rsqlserver.net.SqlDataHelper.Fetch(SqlDataReader dr)
```

```r
dbDisconnect(conn)
```

```
## [1] TRUE
```


To remove a table :

```r

conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
if (dbExistsTable(conn, "MYTABLE2")) dbRemoveTable(conn, "MYTABLE2")
dbDisconnect(conn)
```

```
## [1] TRUE
```


To create a new table :


```r
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)

if (dbExistsTable(conn, "MYTABLE2")) dbWriteTable(conn, "T_MTCARS", mtcars)
dbDisconnect(conn)
```

```
## [1] TRUE
```

```r

```


## Transactions


```r
conn <- dbConnect("SqlServer", user = "collateral", password = "collat", host = "localhost", 
    trusted = TRUE, timeout = 30)
conn <- dbTransaction(conn, name = "newTableTranst")
tryCatch({
    dbGetScalar(conn, "CREATE TABLE MYTABLE3 \n                        ( myvar varchar(1) )")
    dbGetScalar(conn, "CREATE TABLE MYTABLE2 \n                         ( myvar varchar(1) )")
    dbCommit(conn)
}, error = function(e) {
    dbRollback(conn)
}, finally = dbDisconnect(conn))
```

```
## [1] TRUE
```

```r

```










