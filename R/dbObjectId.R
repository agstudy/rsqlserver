

setClass("dbObjectId", representation(Id = "externalptr", "VIRTUAL"))


"isIdCurrent" <- 
  function(obj)
    ## verify that obj refers to a currently open/loaded database
  { 
    id <- rClr:::createReturnedObject(obj@Id)
    canCoerce(id, "cobjRef")
   
  }
