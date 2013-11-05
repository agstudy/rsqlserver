
context("conversion of types and db naming conventions")

test_that("mapping is good between R and sql server types",
{
  
  expect_equal(rsqlserver:::db2RType("char"),"character")
  expect_equal(rsqlserver:::db2RType("varchar"),"character")
  expect_equal(rsqlserver:::db2RType("int"),"integer")
  
})

test_that("the names are valid db names",{
  
  drv <- dbDriver("SqlServer")
  expect_equal(make.db.names(drv,"a mine"),"a_mine") ## space 
  ## keywords 
  expect_equal(make.db.names(drv,"create",allow.keywords=TRUE),"create")     
  expect_equal(make.db.names(drv,"create",allow.keywords=FALSE),"[create]")  
  
})
        