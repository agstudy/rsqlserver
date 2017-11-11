#!/usr/bin/env bash

## docker.sh

## This file contains instructions on building a Docker container
## containing 'rsqlserver' side-by-side with an MS SQL Server database
## Author: Ruaridh Williamson
##
## If you have any problems or questions please raise an issue

# Pull the latest Docker images

## Due to the size of the Docker images, this may take some time depending
## on your internet speed however this "pull" step is a once-off and further
## updates to the images will make use of your existing local caches.
docker pull ruaridhw/rsqlserver:latest && docker pull microsoft/mssql-server-linux:latest

# Start up the server container

## Edit the database password, hostname (-h), port (-p) and container name (--name)
## parameters if required. It is possible (and advisable) to change the database
## password later once running to avoid showing it as plaintext.
##
## Your Docker instance will need to be allocated at least 3-4GB of memory in
## order for the database to successfully start up.
docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=Password12!' -h mydb -p 1433:1433 --name mssqldb -d microsoft/mssql-server-linux

# Run a query against the server
docker exec -t mssqldb /opt/mssql-tools/bin/sqlcmd \
   -S localhost -U SA -P 'Password12!' \
   -Q "CREATE DATABASE rsqlserverdb;
       GO
       USE rsqlserverdb;
       CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT);
       INSERT INTO Inventory VALUES (1, 'banana', 150), (2, 'orange', 154);
       GO
       SELECT * FROM Inventory WHERE quantity > 152;"
#> Changed database context to 'rsqlserverdb'.
#>
#> (2 rows affected)
#> id          name                                               quantity
#> ----------- -------------------------------------------------- -----------
#>          2 orange                                                     154
#>
#> (1 rows affected)


# Run a command in the rsqlserver R session container
docker run --name testrsqlserver --link=mssqldb --rm ruaridhw/rsqlserver Rscript \
   -e "library(rsqlserver)" \
   -e "con <- dbConnect('SqlServer', host = 'mydb', dbname = 'rsqlserverdb', user = 'SA', password = 'Password12!')" \
   -e "dbReadTable(con, 'Inventory')"
#> Loading required package: methods
#> Loading required package: rClr
#> Assembly '/usr/local/lib/R/site-library/rClr/libs/ClrFacade.dll' doesn't have an entry point.
#> Loading the dynamic library for Mono runtime...
#> Loaded Common Language Runtime version 4.0.30319.17020
#>   id   name quantity
#> 1  1 banana      150
#> 2  2 orange      154

## The "Assembly entry point" warning message is a bug with rClr and can be ignored

# Re-enter the R session interactively
docker run --name rsqlserver --link=mssqldb -i ruaridhw/rsqlserver
#> R version 3.4.2 (2017-09-28) -- "Short Summer"
#> Copyright (C) 2017 The R Foundation for Statistical Computing
#> Platform: x86_64-pc-linux-gnu (64-bit)
#> ...
#> >

# In order to use RStudio instead for easier interactivity over command line R,
# you can download the files located in this repository:
# https://github.com/ruaridhw/dockerfiles/tree/master/rsqlserver/rstudio
# Replace the current Dockerfile and then in this docker.sh file replace
# docker pull ruaridhw/rsqlserver:latest
# with
# docker build -t rsqlserver-rstudio .
# and replace
# ruaridhw/rsqlserver
# with
# rsqlserver-rstudio

# The RStudio server will run as a service on the container so simply open
# a local browser window pointing to http://localhost:8787 and login using
# the username and password "rstudio"

# Tested in the following environments:

## R version 3.4.1 (2017-06-30)
## Platform: x86_64-apple-darwin15.6.0 (64-bit)
## Operating System: macOS Sierra 10.12.6
