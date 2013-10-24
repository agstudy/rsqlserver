
.conflicts.OK <- TRUE

.onLoad <-
  if(.Platform$OS.type == "windows") {
    function(libname, pkgname){
#       library(rClr)
#     clrLoadAssembly('System.Data')
  } 
}else {
  function(libname, pkgname) NULL
}

