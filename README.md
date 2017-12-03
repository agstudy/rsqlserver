# rsqlserver

[![Build Status](https://travis-ci.org/agstudy/rsqlserver.svg?branch=master)](https://travis-ci.org/agstudy/rsqlserver)
[![Build status](https://ci.appveyor.com/api/projects/status/g30c0roi0ywenvau/branch/master?svg=true)](https://ci.appveyor.com/project/agstudy/rsqlserver/branch/master)

SQL Server database interface **(DBI)** driver for R.

This is a DBI-compliant SQL Server driver based on the
.NET Framework Data Provider for SQL Server; `System.Data.SqlClient`.

## Motivation

The .NET Framework Data Provider for SQL Server (SqlClient) uses its own protocol
to communicate with SQL Server. It's lightweight and performs well because it's
optimized to access a SQL Server directly without adding an OLE DB or Open Database
Connectivity (ODBC) layer. For this reason, *rsqlserver* [outperforms](https://github.com/agstudy/rsqlserver/wiki/benchmarking) other R packages that rely on ODBC or JDBC layers. If you're using R to interact with SQL Server using large volumes of data and speed matters then *rsqlserver* is the answer!

## Installation

*rsqlserver* is currently available on GitHub for Windows, Linux and macOS users. That said, Linux and macOS users are only able to make use of the package with some workarounds to the usual setup procedure.

The package's interoperability of R and .NET code is provided by the [rClr](https://github.com/jmp75/rClr) package and unfortunately this package is currently only building on Windows and Mono 3.x (which is several years old) and therefore causing problems for macOS and Linux users.

Due to the cross-platform functionality of Docker containers, it is now possible to install the package in a container on any system.

### Local Installation

*Available for Windows and Linux (with patched rClr)*

**Windows** users can install a pre-compiled binary of *rClr* and **Linux** users will be able to install a patched source of *rClr* by using an out-dated version of Mono.

1. Install *rClr* ([See below](#installing-rclr))

6. Install *rsqlserver* from GitHub

```r
devtools::install_github('agstudy/rsqlserver')
```

For **macOS** users, Mono 3.12.1 is able to be installed on newer OS X releases however the rClr build is not functioning properly. At the time of writing, the author of rClr is working on refreshing the package to work on newer versions of Mono which may hopefully resolve this issue.

### Docker

*Available for Windows, Linux and macOS*

The package can be installed on Windows, Linux and macOS via a provided Docker container which also includes an installation of SQL Server 2017. This is the best option for creating a reproducible environment for using the package that is accessible on all platforms and functions the same way regardless of the underlying system.

1. Install Docker for [Mac](https://docs.docker.com/docker-for-mac/install/) or [Windows](https://docs.docker.com/docker-for-windows/install/)

2. Go to Docker > Preferences and increase the supplied memory to at least 4GB
and "Apply & Restart". This is in order to run the SQL Server container
otherwise it won't even start up.

3. Open a Terminal with the repository as the working directory and follow [the instructions](UsingDocker.md)

The **bcp** and **sqlcmd** tools are also [now available](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools#macos)
for macOS and Docker.

If you just want to connect to a Docker instance of SQL Server from your local
Mac without *rsqlserver* then follow [these instructions](https://medium.com/@reverentgeek/sql-server-running-on-a-mac-3efafda48861).

To install the necessary ODBC drivers without *rsqlserver* and connect with the
*RODBC* package then follow [this wiki](https://github.com/mkleehammer/pyodbc/wiki/Connecting-to-SQL-Server-from-Mac-OSX).

### Installing rClr

**Windows**

The easiest option is to download a pre-compiled binary rather than try and install from source.

1. Install [Microsoft Windows SDK for Windows 7 and .NET Framework 4](https://www.microsoft.com/en-gb/download/details.aspx?id=8279). *rsqlserver* uses the .NET framework SDK to build a small C# project.
Typically if your machine has the program "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe", you can skip this step.

2. Install [Visual C++ Redistributable Packages for Visual Studio](https://go.microsoft.com/fwlink/?LinkId=746572).

3. Download [rClr 0.7-4](https://github.com/jmp75/rClr/archive/0.7-4.zip).  (New binary versions will appear in the [GitHub releases](https://github.com/jmp75/rClr/releases). CodePlex is being decommissioned so the rClr 0.7-4 binary is available [here](https://github.com/ruaridhw/rClr/tree/windows-binary) if the source version won't install).


```r
install.packages("path/to/rClr_0.7-4.zip", repos = NULL, type = "source")
```

**Linux**

A workaround for installing the package on Linux is to downgrade the installed version of Mono to 3.12.1 using [this script](https://gist.github.com/ruaridhw/b00e75647c8e96c2f44044c970f19c7f) prior to building rClr as the package currently doesn't work on Mono 4.x or later.

Once you have done this, test that the version of Mono is correct. If you see a version number other than 3.12.1 then the installation was unsuccessful.

```bash
$ mono -V
# Mono JIT compiler version 3.12.1 (tarball Fri Mar  6 19:12:47 UTC 2015)
# Copyright (C) 2002-2014 Novell, Inc, Xamarin Inc and Contributors. www.mono-project.com
# 	TLS:           __thread
# 	SIGSEGV:       altstack
# 	Notifications: epoll
# 	Architecture:  amd64
# 	Disabled:      none
# 	Misc:          softdebug
# 	LLVM:          supported, not enabled.
# 	GC:            sgen
```

You can now install rClr from GitHub:

```r
devtools::install_github('jmp75/rClr')
```

Depending on your distribution this may throw errors with the compilation of the C++ code. If you run into a similar issue as listed [here](https://github.com/jmp75/rClr/issues/27) then try this patched fork:

```r
devtools::install_github('serhatcevikel/rClr@03f65ef')
```

## Features

*rsqlserver* presents many features:

* Easy connection to SQL server using DBI-compliant drivers.
* Fastest method for loading large delimited text files (>1million rows) and R objects into SQL Server tables or views using `dbBulkCopy` and pulling data back down into R data.frames (See benchmarking below)
* Use a Trusted Connection with the server. (Windows only).
* `dbSendQuery` for querying the database; low level functions using pure SQL statements.
* Full DBI compliance via support of higher level convenience functions such as `dbReadTable`, `dbWriteTable` and `dbRemoveTable`.
* `dbTransaction`, `dbCommit` and `dbRollback` for **Transaction** management. (TBA)
* `dbCallProc` for **Stored Procedure** calls. (TBA)
* Many other DBI extensions such as `dbGetScalar` and `dbGetNoQuery`
* `dbParameter` to handle Transact-SQL named parameters. This will provide better type checking and improve performance. (TBA)

## Benchmarking

See the *rsqlserver* wiki page on [benchmarking](https://github.com/agstudy/rsqlserver/wiki/benchmarking) performance versus two other drivers; `RODBC` and `RJDBC.`

## Acknowledgements

I want to thank Jean-Michel Perraud the author of [rClr](http://r2clr.codeplex.com/) package.
