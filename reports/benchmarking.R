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
library(rsqlserver)
library(microbenchmark)

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


