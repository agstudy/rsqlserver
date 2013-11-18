library(rsqlserver)
library(microbenchmark)
library(RODBC)
library(RJDBC)
library(R.utils)

LIST_DRIVERS <- c('rodbc',
                  'sqlserver',
                  'rjdbc')
TABLE_NAME = "T_BENCH_"
bench.cols <- c(10,50,100,750)
bench.rows <- c(1,10,100)
bench.types = c('NUM','CHAR','DATE')
TIMEOUT <- 1
options(stringsAsFactors=FALSE)


get.rsqlserver <- function(conn,n,name){
  qselect <- paste0("SELECT * FROM ",name)
  rs <- dbSendQuery(conn, qselect)
  res <- fetch(rs, n)
  dbClearResult(rs)
  res
}

get.rodbc <- function(conn,n,name){
  qselect <- paste0("SELECT * FROM ",name)
  sqlQuery(channel=conn, qselect,max=n)
}


get.rjdbc <- function(conn,n,name){
  qselect <- paste0("SELECT * FROM ",name)
  rs <- RJDBC::dbSendQuery(conn, qselect)
  res <- RJDBC::fetch(rs, n)
  RJDBC::dbClearResult(rs)
  res
}

gTable.character <- function(name='T_BENCH_CHAR',nrow,ncol,replic=1,nchar=10) {
  cnames <- paste0('col',seq_len(ncol))
  name = paste(name,ncol,format(nrow*replic,scientific=FALSE),sep='_')
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url) 
  rsqlserver:::dropTable(conn,name)
  rsqlserver:::dbCreateTable(conn,name,cnames,
                             rep(paste0('char(',nchar,')'),ncol))
  dbDisconnect(conn)
  step =0
  replicate(replic,{
    get.word <- function(nchar)
      paste0(sample(c(0:9, letters, LETTERS),nchar, replace=TRUE),collapse="")
    dat <- matrix(replicate(ncol*nrow,get.word(nchar)),ncol=ncol,nrow=nrow)
    colnames(dat) <- cnames 
    id.file = "d:/temp/temp_char.csv"                      
    write.csv(dat,file=id.file,row.names=FALSE,quote=FALSE)
    dbBulkCopy(conn,name,value=id.file)
    step = step +1;message(step)
    rm(dat)
  })
  
  
}

gTable.numeric <- function(name='T_BENCH_NUM',nrow,ncol,replic=1) {
  
  cnames <- paste0('col',seq_len(ncol))
  name = paste(name,ncol,format(nrow*replic,scientific=FALSE),sep='_')
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url) 
  rsqlserver:::dropTable(conn,name)
  rsqlserver:::dbCreateTable(conn,name,cnames,
                             rep('float',ncol))
  dbDisconnect(conn)
  
  step = 0
  replicate(replic,{
    dat <- matrix(round(rnorm(nrow*ncol),2),
                  nrow=nrow,
                  ncol=ncol)
    
    colnames(dat) <- cnames 
    id.file = "d:/temp/temp_num.csv"                      
    write.csv(dat,file=id.file,row.names=FALSE)
    dbBulkCopy(conn,name,value=id.file)
    step = step +1;message(step)
    rm(dat)
  })
  
  
}


gTable.datetime <- function(name='T_BENCH_DATE',nrow,ncol,replic=1) {
  
  cnames <- paste0('col',seq_len(ncol))
  name = paste(name,ncol,format(nrow*replic,scientific=FALSE),sep='_')
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn <- dbConnect('SqlServer',url=url) 
  rsqlserver:::dropTable(conn,name)
  rsqlserver:::dbCreateTable(conn,name,cnames,
                             rep('datetime',ncol))
  dbDisconnect(conn)
  i = 0
  replicate(replic,{
    dat <- vector('list',ncol)
    for (i in seq_len(ncol))
      dat[[i]] <- Sys.time()+ seq((i-1)*nrow,1,length.out=nrow)
    attr(dat, "row.names") <- c(NA_integer_, length(dat[[1]]))
    class(dat) <- "data.frame"
    colnames(dat) <- cnames 
    id.file = "d:/temp/temp_date.csv"                      
    write.csv(dat,file=id.file,row.names=FALSE)
    dbBulkCopy(conn,name,value=id.file)
    step = step +1;message(step)
    rm(dat)
  })
}



create.all <- function(){
  nrows = 100*10^(0:2)
  ncols = c(10,50,100,750)
  res <- list()
  for(rr in nrows)
    for(cc in ncols){
      
      mb <- microbenchmark(
        gTable.datetime(nrow=rr,ncol=cc,replic=10),
        gTable.numeric(nrow=rr,ncol=cc,replic=10),
        gTable.character(nrow=rr,ncol=cc,replic=10),
        times=1)
      bench = paste('T',cc,format(rr*10,scientific=FALSE),sep='_')
      res <- c(res,setNames(list(mb),bench))
      print(bench) 
    }
}


init.bench <- function(){
  url = "Server=localhost;Database=TEST_RSQLSERVER;Trusted_Connection=True;"
  conn2 <- dbConnect('SqlServer',url=url)
  conn1 <- odbcConnect(dsn = "my-dns", uid = "collateral", pwd = "collat")
  drv = JDBC('com.microsoft.sqlserver.jdbc.SQLServerDriver',
             'd:/temp/sqljdbc_4.0/enu/sqljdbc4.jar')
  url = 'jdbc:sqlserver://localhost;user=collateral;password=collat;databasename=TEST_RSQLSERVER;'
  conn3 <- RJDBC::dbConnect(drv,url=url )
  
  tt <- dbListTables(conn2)
  tables.names <- grep('T_BENCH_.*',tt,value=TRUE)
  tables = data.frame(
    name   = tables.names,
    rsize  = as.integer(gsub('.*BENCH_(.*)_(.*)_(.*)','\\3',tables.names)),
    csize  = as.integer(gsub('.*BENCH_(.*)_(.*)_(.*)','\\2',tables.names)),
    type   = gsub('.*BENCH_(.*)_(.*)_(.*)','\\1',tables.names))
  
  list(tables=tables, crsqlserver=conn2,
       crodbc=conn1, crjdbc=conn3)
  
}


bencher.table <- function(tables,crsqlserver,crodbc,crjdbc,times=10L){
  ll <- lapply(seq_len(nrow(tables)), function(i){
    name = tables[i,'name']
    n = tables[i,'rsize']
    tm <- microbenchmark( get.rsqlserver(crsqlserver,n,name),
                          get.rodbc(crodbc,n,name),
                          get.rjdbc(crjdbc,n,name),
                          times=times)
    tm.df <- sapply(LIST_DRIVERS,
                    function(driver)
                      microbenchmark:::convert_to_unit(tm[grep(driver,tm$expr),]$time,'s'))
    if(times>1) tm.df <- colMeans(tm.df)
    data.frame(name=name,
               time= tm.df,
               method=names(tm.df))
    
  })
  
  res <- do.call(rbind,ll)
  merge(tables ,res)
}

bencher.points <- function( tables,crsqlserver,crodbc,crjdbc,
                       points = seq(1,200,50)){
  
  res <- lapply(tables$name, function(name){
    ll <- lapply(points, function(n){
      
      tm <- microbenchmark( get.rsqlserver(crsqlserver,n,name),
                            #get.rodbc(crodbc,n,name),
                            get.rjdbc(crjdbc,n,name),
                            times=1L)
      
      tm.df <- sapply(LIST_DRIVERS,
                      function(driver)
                        microbenchmark:::convert_to_unit(tm[grep(driver,tm$expr),]$time,'s'))
      data.frame(rsize=n,
                 time= tm.df,
                 method=names(tm.df))
    })
    data.frame(name=name,do.call(rbind,ll))
  })

  do.call(rbind,res)
}


engine <- function(filter,bencher,...){
  ini <- init.bench()
  e <- substitute(filter)
  r <- eval(e, ini$tables, parent.frame())
    if (!is.logical(r)) 
      stop("'subset' must be logical")
  r <- r & !is.na(r)
  tables <- ini$tables[r,]
  res <- bencher(tables,ini$crsqlserver,ini$crodbc,ini$crjdbc,...)
  res
}
