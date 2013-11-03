libarch <- if (nzchar(R_ARCH)) paste('libs', R_ARCH, sep='') else "libs"
dest <- file.path(R_PACKAGE_DIR, libarch)
dest.dll <- file.path(R_PACKAGE_DIR, 'libs')
src <- file.path(R_PACKAGE_SOURCE ,"src/rsqlserver.net/bin/Debug")
files <- Sys.glob(file.path(src,   "*.dll"))
print(files)
print(dest)
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
file.copy(files, dest.dll, overwrite = TRUE)