# # .net method to call a transaction
# # // Start a local transaction.
# # transaction = connection.BeginTransaction("SampleTransaction");
# # command.Connection = connection;
# # command.Transaction = transaction;
# # command.ExecuteNonQuery();
# # transaction.Commit();
# # transaction.Rollabck();
# 
# setClass("SqlServerTransaction", representation("SqlServerObject"))
# 
# setGeneric("beginTransaction",
#             function(conn,name="R.transaction",...)
#               standardGeneric("beginTransaction")
# )
# 
# setMethod("beginTransaction",
#           signature(conn='SqlServerConnection',name='character'),
#           def=function(conn,name="R.transaction",...){
#             connection <- rClr:::createReturnedObject(conn@Id)
#             if(dbGetInfo(conn,'State')[[1]] ==1){
#               trans <- clrCall(connection,"BeginTransaction",name)
#               Id = clrGetExtPtr(trans)
#               return(trans)
#             }
#             return(NULL)
#           },
#           valueClass = "SqlServerTransaction")
# 
# 
# setMethod("dbCommit",
#           signature(conn="SqlServerConnection"),
#           function(conn,trans, ...) {
#             transaction <- rClr:::createReturnedObject(trans@Id)
#             clrCall(transaction,'Commit')
#             TRUE
#           }
# )
# 
# # setMethod("dbRollback",
# #           signature(trans = "SqlServerTransaction"),
# #           function(trans, ...) {
# #             transaction <- rClr:::createReturnedObject(trans@Id)
# #             clrCall(transaction,'bRollback')
# #             TRUE
# #           }
# # )
# # 
