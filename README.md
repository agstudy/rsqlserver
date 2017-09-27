# rsqlserver

A SQL Server database interface **(DBI)** driver for R.

This is a DBI-compliant SQL Server driver based on the 
.NET Framework Data Provider for SQL Server (SqlClient) `System.Data.SqlClient`. 

## Motivation 

The .NET Framework Data Provider for SQL Server (SqlClient) uses its own protocol
to communicate with SQL Server. It is lightweight and performs well because it is
optimized to access a SQL Server directly without adding an OLE DB or Open Database
Connectivity (ODBC) layer.

## Prerequisites and package dependencies 

The interoperability of R and .NET code relies on the `rClr` package. You can download
an installable R package for Windows (zip file). **Please make sure you at least skim
through the [installation instructions](http://r2clr.codeplex.com/wikipage?title=Installing%20R%20packages&referringTitle=Documentation).**
Under Windows it is better to use the zip package. First you install [Visual C++ Redistributable Packages for Visual Studio 2013](http://www.microsoft.com/en-us/download/details.aspx?id=40784à)

The `rsqlserver` package uses the .NET framework SDK to build a small C# project.
Typically if you have on your machine the file
"C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe", you can skip this paragraph.
Otherwise you need to install the [Microsoft Windows SDK for Windows 7 and .NET Framework 4](http://www.microsoft.com/en-us/download/details.aspx?id=8279).
An overview of list of Microsoft SDKs is available [here](http://msdn.microsoft.com/en-us/vstudio/hh487283.aspx)

## Installation

`rsqlserver` is currently available only on github. It is available for Windows and Linux users.

You can install it from `github` using the `devtools` package

```r
library(devtools)
install_github('agstudy/rsqlserver')  ## assuming that you have already installed rClr
```

## Features

`rsqlserver` presents many features:

* Fast and easy connection to SQL server. (See benchmarking)
* Use a Trusted connection with the server. This functionality is only available for Windows users.
* `dbSendQuery` for querying the database: low levels functions using pure SQL statements.
* Full DBI compliance: eg. Support of higher level convenient functions: `dbReadTable`,`dbWriteTable`,`dbRemoveTable`,..)
* `dbTransaction`, `dbCommit`, `dbRollback` for **Transaction** management. (TBA)
* `dbCallProc` for **Stored Procedure** calls. (TBA)
* `dbBulkCopy` using **Bulk Copy** for quickly bulk copying big data.frame/data.table
objects or large delimited files into SQL server tables or views.
* Many other DBI extensions such as `dbGetScalar` and `dbGetNoQuery`
* `dbParameter` to handle Transact-SQL named parameters. This will provide better type checking and improve performance. (TBA)

## Benchmarking

You can see `rsqlserver` [benchmarking](https://github.com/agstudy/rsqlserver/wiki/benchmarking)
performance versus two other drivers; `RODBC` and `RJDBC.`

## Acknowledgements

I want to thank Jean-Michel Perraud the author of [rClr](http://r2clr.codeplex.com/) package.

### If you like this project, give it a star or a donation :)

<a href='https://pledgie.com/campaigns/28549'><img alt='Click here to lend your support to: rsqlserver and make a donation at pledgie.com !' src='https://pledgie.com/campaigns/28549.png?skin_name=chrome' border='0' ></a>
