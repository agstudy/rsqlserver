context("Conversion of types and DB naming conventions")

test_that("db2RType: Mapping fom SQL Server types to R types",{
  expect_equal(rsqlserver:::db2RType("char"), "factor")
  expect_equal(rsqlserver:::db2RType("varchar"), "character")
  expect_equal(rsqlserver:::db2RType("int"), "integer")
  expect_equal(rsqlserver:::db2RType("datetime"), "POSIXct")
  expect_equal(rsqlserver:::db2RType("float"), "numeric")
  expect_equal(rsqlserver:::db2RType("decimal"), "numeric")
})

test_that("make.db.names: Names are valid DB names",{
  drv <- dbDriver("SqlServer")
  expect_equal(make.db.names(drv, "a mine"), "a_mine") ## space
  ## keywords
  expect_equal(make.db.names(drv, "create", allow.keywords = TRUE), "create")
  expect_equal(make.db.names(drv, "create", allow.keywords = FALSE), "[create]")
})

test_that("R2DbType: Automatic Conversion from R to DB",{
  value <- list(x.int     = 1L,
                x.num     = 1,
                x.fact    = factor(1),
                x.char    = "x",
                x.list    = list(1),
                x.date    = Sys.Date(),
                x.posixct = Sys.time())
  expected <- list(x.int     = "int",
                   x.num     = "float",
                   x.fact    = "char(12)",
                   x.char    = "varchar(128)",
                   x.list    = "varbinary(2000)",
                   x.date    = "date",
                   x.posixct = "datetime2")
  effective <- lapply(value, rsqlserver:::R2DbType)
  expect_identical(expected, effective)
})

test_that("sqlServer.data.frame: Data is well quoted before insert",{
  options(stringsAsFactors = FALSE) 
  value <- data.frame(a = as.POSIXct("2013-11-07 01:47:33"),
                      b = "value ' alol",
                      c = "aa jujs",
                      d = 1,
                      e = as.Date("2013-11-07"))
  expected = data.frame(a = "'2013-11-07 01:47:33'",
                        b = "'value '' alol'",
                        c = "'aa jujs'",
                        d = 1,
                        e = "'2013-11-07'")
  field.types <- lapply(value, rsqlserver:::R2DbType)
  value.db <- rsqlserver:::sqlServer.data.frame(value, field.types)
  expect_equal(expected, value.db)
})

test_that("dbReadTable: Read rownames in the exact type",{
  on.exit(dbDisconnect(conn))
  conn <- get_con()
  dat_int  <- data.frame(x = 1:10)
  dat_char <- data.frame(x = 1:10)
  dat_date <- data.frame(x = 1:10)
  rownames(dat_char) <- paste0("row", seq(nrow(dat_char)))
  rownames(dat_date) <- seq.POSIXt(from = Sys.time(),
                                   by=1,
                                   length.out = nrow(dat_date))
  invisible(lapply(ls(pattern = "dat_"),
                   function(x){
                     dbWriteTable(conn, name = x, value = get(x), overwrite=TRUE)
                     res <- dbReadTable(conn, name = x)
                     dbRemoveTable(conn, name = x)
                     expect_identical(rownames(get(x)),
                                      rownames(res))
                   }))
})

test_that("dbWriteTable: Save POSIXct as DATETIME",{
  on.exit(dbDisconnect(conn))
  dat <- data.frame(cdate = seq.POSIXt(from = Sys.time(),
                                       by = 1,
                                       length.out = 100)
  )
  conn <- get_con()
  dbWriteTable(conn, name = "T_DATE", value = dat, overwrite = TRUE)
  res <- dbGetScalar(conn,
                     "SELECT DATA_TYPE
                      FROM INFORMATION_SCHEMA.COLUMNS
                      WHERE TABLE_NAME = 'T_DATE' AND COLUMN_NAME = 'cdate'")
  expect_identical(res, "datetime2")
  dbRemoveTable(conn, "T_DATE")
})

#TODO
test_that("dbReadTable: Read DATETIME as POSIXct",{
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  dat <- data.frame(cdate = seq.POSIXt(from = Sys.time(),
                                       by = 1,
                                       length.out = 100)
                    )
  conn <- get_con()
  dbWriteTable(conn, name = "T_DATE", value = dat, overwrite = TRUE)
  res <- dbReadTable(conn, "T_DATE")
  expect_is(res$cdate, "POSIXct")
  dbRemoveTable(conn, "T_DATE")
})

#TODO
test_that("dbBulkCopy: Insert POSIXct into DATETIME",{
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  N <- 100000
  dat <- data.frame(cdate = seq.POSIXt(from = Sys.time(),
                                       by = 1,
                                       length.out = N))
  conn <- get_con()
  rsqlserver:::dbCreateTable(conn, "T_BULKCOPY",
                             "cdate", "datetime2")
  dbBulkCopy(conn, value = dat, name = "T_BULKCOPY")
  res <- dbGetScalar(conn,
                     "SELECT DATA_TYPE
                      FROM INFORMATION_SCHEMA.COLUMNS
                      WHERE TABLE_NAME = 'T_BULKCOPY' AND COLUMN_NAME = 'cdate'")
  expect_identical(res, "datetime2")
  dbRemoveTable(conn, "T_BULKCOPY")
})

test_that("dbWriteTable: Save Date as DATE (#11)",{
  on.exit(dbDisconnect(conn))
  dat <- data.frame(cdate = seq.Date(from = Sys.Date(),
                                     by = 1,
                                     length.out = 5))
  conn <- get_con()
  dbWriteTable(conn, name = "T_DATE", value = dat, overwrite = TRUE)
  res <- dbGetScalar(conn,
                     "SELECT DATA_TYPE
                     FROM INFORMATION_SCHEMA.COLUMNS
                     WHERE TABLE_NAME = 'T_DATE' AND COLUMN_NAME = 'cdate'")
  expect_identical(res, "date")
  dbRemoveTable(conn, "T_DATE")
})

#TODO
test_that("dbReadTable: Read DATE as Date (#11)",{
  skip("Not yet implemented")
  on.exit(dbDisconnect(conn))
  dat <- data.frame(cdate = seq.Date(from = Sys.Date(),
                                     by = 1,
                                     length.out = 5))
  conn <- get_con()
  dbWriteTable(conn, name = "T_DATE", value = dat, overwrite = TRUE)
  res <- dbReadTable(conn, "T_DATE")
  expect_is(res$cdate, "Date")
  dbRemoveTable(conn, "T_DATE")
})
