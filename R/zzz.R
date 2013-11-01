

.onLoad <- function(libname, pkgname){
  if(.Platform$OS.type == "windows") {
    libLocation<- system.file(package=pkgname)
   libpath <- file.path(libLocation, 'libs')
   ## libpath <- file.path(libLocation)
    f <- file.path(libpath, 'rsqlserver.net.dll')
    if( !file.exists(f) ) {
      packageStartupMessage('Could not find path to rsqlserver.dll, 
                            you will have to load it manually')
    } else {
      clrLoadAssembly('System.Data') ## .net provider
      clrLoadAssembly(f)                       ## custom dll 
    }
  }
}



