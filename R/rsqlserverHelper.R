

"sqlServerInitDriver" <-
  function(max.con = 16, fetch.default.rec = 500, force.reload=FALSE,
           shared.cache=FALSE)
    ## return a manager id
  {
    config.params <- as.integer(c(max.con, fetch.default.rec))
    force <- as.logical(force.reload)
    cache <- as.logical(shared.cache)
    id <- .Call("RS_SQLite_init", config.params, force, cache, PACKAGE = .SQLitePkgName)
    new("SqlServerDriver", Id = drvId)
  }



"SqlServerNewConnection" <-
function(drv,  username=NULL,
   password=NULL, host=NULL,
         trusted=TRUE, timeout=30)
{
   if(!isIdCurrent(drv))
      stop("expired manager")

	if (!is.null(username) && !is.character(username))
         stop("Argument username must be a string or NULL")
	if (!is.null(password) && !is.character(password))
         stop("Argument password must be a string or NULL")
	if (!is.null(host) && !is.character(host))
         stop("Argument host must be a string or NULL")
	if (is.null(timeout) || !is.numeric(timeout))
         stop("Argument timeout must be an integer value")
	if (is.null(trusted) || !is.logical(trusted))
         stop("Argument client.flag must be a boolean")
   connect.string <- paste(paste0("user id=",username),
     paste0("password=",password),paste0("server=",host),
     paste0("Trusted_Connection=",ifelse(trusted,"yes","false")),
     paste0("connection timeout=",timeout),
   sep=";")
   conId = clrNew("System.Data.SqlClient.SqlConnection",connect.string)
 	 new("SqlServerConnection", Id = conId)
}