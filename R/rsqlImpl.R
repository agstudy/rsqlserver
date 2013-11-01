

sqlServerInitDriver <-
  function(max.con = 100L, fetch.default.rec = 500, force.reload=FALSE,
           shared.cache=FALSE)
    ## return a manager id
  {

    config.params <- as.integer(c(max.con, fetch.default.rec))
    force <- as.logical(force.reload)
    cache <- as.logical(shared.cache)
    new("SqlServerDriver", Id = clrGetExtPtr(clrNew('System.Object')))
  }


sqlServerDriverInfo <-
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





## Tsql 2012 keywords scraped from 
##  "http://technet.microsoft.com/en-us/library/ms189822(v=sql.110).aspx"
## using this smart helper function !
# scrape.keywords <- function(){
#   ## require(XML) should uncomment this and install the packagee
#   url <- "http://technet.microsoft.com/en-us/library/ms189822(v=sql.110).aspx"
#   doc <- htmlParse(url)
#   ll <- xpathSApply(doc, '//*[@class="tableSection"]/*/tr/td/p',xmlValue)
#   ll <- ll[seq(min(grep('\n',ll))-1)]
#   cat(paste0('"',paste0(ll,collapse='","'),'"'))
# }


.SqlServersKeywords <-
  c("ADD","EXTERNAL","PROCEDURE","ALL","FETCH","PUBLIC","ALTER","FILE",
    "RAISERROR","AND","FILLFACTOR","READ","ANY","FOR","READTEXT","AS",
    "FOREIGN","RECONFIGURE","ASC","FREETEXT","REFERENCES","AUTHORIZATION",
    "FREETEXTTABLE","REPLICATION","BACKUP","FROM","RESTORE","BEGIN","FULL",
    "RESTRICT","BETWEEN","FUNCTION","RETURN","BREAK","GOTO","REVERT","BROWSE",
    "GRANT","REVOKE","BULK","GROUP","RIGHT","BY","HAVING","ROLLBACK","CASCADE",
    "HOLDLOCK","ROWCOUNT","CASE","IDENTITY","ROWGUIDCOL","CHECK","IDENTITY_INSERT",
    "RULE","CHECKPOINT","IDENTITYCOL","SAVE","CLOSE","IF","SCHEMA","CLUSTERED",
    "IN","SECURITYAUDIT","COALESCE","INDEX","SELECT","COLLATE","INNER",
    "SEMANTICKEYPHRASETABLE","COLUMN","INSERT","SEMANTICSIMILARITYDETAILSTABLE",
    "COMMIT","INTERSECT","SEMANTICSIMILARITYTABLE","COMPUTE","INTO","SESSION_USER",
    "CONSTRAINT","IS","SET","CONTAINS","JOIN","SETUSER","CONTAINSTABLE","KEY","SHUTDOWN",
    "CONTINUE","KILL","SOME","CONVERT","LEFT","STATISTICS","CREATE","LIKE","SYSTEM_USER",
    "CROSS","LINENO","TABLE","CURRENT","LOAD","TABLESAMPLE","CURRENT_DATE","MERGE",
    "TEXTSIZE","CURRENT_TIME","NATIONAL","THEN","CURRENT_TIMESTAMP","NOCHECK","TO",
    "CURRENT_USER","NONCLUSTERED","TOP","CURSOR","NOT","TRAN","DATABASE","NULL",
    "TRANSACTION","DBCC","NULLIF","TRIGGER","DEALLOCATE","OF","TRUNCATE","DECLARE",
    "OFF","TRY_CONVERT","DEFAULT","OFFSETS","TSEQUAL","DELETE","ON","UNION","DENY",
    "OPEN","UNIQUE","DESC","OPENDATASOURCE","UNPIVOT","DISK","OPENQUERY","UPDATE",
    "DISTINCT","OPENROWSET","UPDATETEXT","DISTRIBUTED","OPENXML","USE","DOUBLE",
    "OPTION","USER","DROP","OR","VALUES","DUMP","ORDER","VARYING","ELSE","OUTER",
    "VIEW","END","OVER","WAITFOR","ERRLVL","PERCENT","WHEN","ESCAPE","PIVOT","WHERE",
    "EXCEPT","PLAN","WHILE","EXEC","PRECISION","WITH","EXECUTE","PRIMARY","WITHIN GROUP",
    "EXISTS","PRINT","WRITETEXT","EXIT","PROC")


    