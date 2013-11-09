# rsqlserver
==========

Sql Server driver  database interface **(DBI)** driver for R. 
This is a DBI-compliant Sql Server driver based on the 
The .NET Framework Data Provider for SQL Server (SqlClient) `System.Data.SqlClient`. 

## Motivation 

The .NET Framework Data Provider for SQL Server (SqlClient) uses its own protocol to communicate with SQL Server. It is lightweight and performs well because it is optimized to access a SQL Server directly without adding an OLE DB or Open Database Connectivity (ODBC) layer.


## Prerequisites and package dependencies 


The `rsqlserver` package uses the .NET framework SDK to build some a small C# project. Typically if you have on your machine the file "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe", you can skip this paragraph. Otherwise you need to install the [Microsoft Windows SDK for Windows 7 and .NET Framework 4](http://www.microsoft.com/en-us/download/details.aspx?id=8279). An overview of list of Microsoft SDKs is available [here](http://msdn.microsoft.com/en-us/vstudio/hh487283.aspx)

The interoperability of R and .NET code relies on the [rClr](http://r2clr.codeplex.com/) R package. You can download an installable R package for windows (zip file). Make sure to at least skim through the [installation instructions](http://r2clr.codeplex.com/wikipage?title=Installing%20R%20packages&referringTitle=Documentation).


## Installation

`rsqlserver` is currently available only on github. It is also only available for windows user. A linux version using mono is planned.

You can install it from `github` using the `devtools` package

```coffee
require(devtools)
install_github('rsqlserver', 'agstudy')
```

## Features

`rsqlserver` presentes many features:

* fast and easy connection to Sql server.
* `dbSendQuery` Querying the data base : low levels functions using sql statement.
* Full DBI compliant: for example Support of Higher level convenient functions :`dbReadTable`,`dbWriteTable`,`dbRemoveTable`,..)
* `dbTransaction`, `dbCommit`, `dbRollback` for **Transaction** management
* `dbCallProc` (in development)  for **Stored procedure** call.
* `dbBulkCopy` using **Bulk Copy** for quickly bulk copying Big data.frame or large files into SQL server tables or views.
* Many DBI extension like `dbGetScalar` , `dbGetNoQuery` , `dbBulkCopy`
* `dbParameter`(coming soon) to handle Transact-SQL named parameters. This will provide better type checking and imporve performance. 

## Benchmarking

TODO performance tests :Comparaison with `RODBC`.

## Acknowledgements

I want to thank Jean-Michel Perraud the author of [rClr](http://r2clr.codeplex.com/) package.




[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/agstudy/rsqlserver/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

