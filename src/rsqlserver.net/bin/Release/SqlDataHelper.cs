using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Data;
using System.Collections;
using RDotNet;
namespace rsqlserver.net
{
    public class SqlDataHelper  
    {




        public Object GetItem(SqlDataReader _dataReader, int i){
            object res = _dataReader[i];
            if (res != null && res.GetType() == typeof(Byte))
                return (int)(byte)res;
            if (res != null && res.GetType() == typeof(DateTime))
                return ((DateTime)res).ToString("yyyy-MM-dd HH:mm:ss");


            return res;
        }

        public Object GetConnectionProperty(SqlConnection _conn, string prop)
        {
            if (_conn.State == ConnectionState.Closed &
                prop == "ServerVersion")
                return string.Empty;
            
            if (prop == "ClientConnectionId")
            {
                Guid guid = _conn.ClientConnectionId;
                return guid.ToString();
            }
            return _conn.GetType().GetProperty(prop).GetValue(_conn);
        }

        public Object GetReaderProperty(SqlDataReader _reader, string prop)
        {
           object val = null;
           if(String.Compare(prop ,"Item")!=0){
               val =  _reader.GetType().GetProperty(prop).GetValue(_reader);
            }
            return val;
        }

        public object Fetch(SqlDataReader dr)
        {
            ArrayList frame = new ArrayList();
           
            int cnt = 0;
            if (dr.HasRows)
            {
                while (dr.Read())
                {
                    object[] values = new object[dr.FieldCount];
                    dr.GetValues(values);
                    frame.Add(values);
                    cnt += 1;
                }
            }
            return frame; 
        }


        public object TestRdotNet()
        {
            using (REngine engine = REngine.CreateInstance("RDotNet"))
            {
                // From v1.5, REngine requires explicit initialization.
                // You can set some parameters.
                engine.Initialize();

                // .NET Framework array to R vector.
                NumericVector group1 = engine.CreateNumericVector(
                    new double[] { 30.02, 29.99, 30.11, 29.97, 30.01, 29.99 });
                return group1;
            }
        }
       
    



    }


    



}
