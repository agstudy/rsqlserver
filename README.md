# rsqlserver
==========

Sql Server driver  database interface **(DBI)** driver for R. 
This is a DBI-compliant Sql Server driver based on the 
The .NET Framework Data Provider for SQL Server (SqlClient) `System.Data.SqlClient`. 

## Motivation 

The .NET Framework Data Provider for SQL Server (SqlClient) uses its own protocol to communicate with SQL Server. It is lightweight and performs well because it is optimized to access a SQL Server directly without adding an OLE DB or Open Database Connectivity (ODBC) layer.


## Requirement

`rsqlserver` is using  using thee [Rclr package](https://rclr.codeplex.com/) package which requires: 

* .NET 4.0
* MS Visual C++ 2012 runtime

## Installation

`rsqlserver` is currently available only on github. It is also only available for windows user. A linux version using mono is planned.

You can install it from `github` using the `devtools` package

```coffee
require(devtools)
install_github('rClr', 'agstudy')
install_github('rsqlserver', 'agstudy')
```

## Features

`rsqlserver` presentes many features:

* fast and easy connection to Sql server.
* Querying the data base : low levels functions using sql statement.
* Full DBI compliant. Support of Higher level convenient functions( dbReadTable,dbWriteTable,dbRemoveTable,..) that support read, save, copy, and manipulation of data between R data.frame objects and database tables.
* Easy **Transaction** management to commit and rollback
* **Stored procedure** call.
* Uses named parameters in the format @parametername to pass values to SQL statements or stored procedures. This will provide better type checking and imporve performance. (not yet implemented)
* **Bulk Copy** for quickly bulk copying large files into tables or views in SQL Server databases.
* DBI extension like `dbGetScalar` and `dbGetNoQuery`

## Benchmarking

i am preparing some benchmarking with `RODBC`.

## Acknowledgements

I thank the author of `rClr` package.


