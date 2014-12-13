

setClass("dbObjectId", representation(Id = "externalptr", "VIRTUAL"),
         prototype=list(Id=NULL))


isIdCurrent <- 
  function(obj)
    ## verify that obj refers to a currently open/loaded database
  { 
    id <- .NetObjFromPtr(obj@Id)
    canCoerce(id, "cobjRef")
  }

isTransaction <- function(conn)
{ 
  trans <- .NetObjFromPtr(conn@trans)
  grepl('Transaction',clrTypename(trans))
}

  
