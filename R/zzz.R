

.onLoad <- function(libname, pkgname){
    libLocation <- system.file(package=pkgname)
    libpath <- file.path(libLocation, 'libs')
    f <- file.path(libpath, 'rsqlserver.net.dll')
    if( !file.exists(f) ) {
      packageStartupMessage('Could not find path to rsqlserver.dll, 
                            you will have to load it manually')
    } else {
      clrLoadAssembly('System.Data') ## .net provider
      clrLoadAssembly(f)                       ## custom dll 
    }
}



