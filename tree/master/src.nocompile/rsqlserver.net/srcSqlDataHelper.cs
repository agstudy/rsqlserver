using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Data;
using System.Collections;
using System.Reflection;
namespace rsqlserver.net
{

    public static class SqlClientExtensions
    {
#if __MonoCS__
		private static Dictionary<int, string> _connIds = new Dictionary<int, string>();
#endif

        public static string GetClientConnectionId(this SqlConnection conn)
        {
            if (conn == null)
            {
                return Guid.Empty.ToString();
            }

#if __MonoCS__
			if(!connIds.ContainsKey(conn.GetHashCode())) {
			connIds.Add(conn.GetHashCode(), Guid.NewGuid().ToString());
			}

			return connIds[conn.GetHashCode()];
#else
            return conn.ClientConnectionId.ToString();
#endif
        }
    }
    public class SqlDataHelper
    {
        #region map types
        private Dictionary<Type, Type> NetToRType
        {
            get
            {
                var typeMap = new Dictionary<Type, Type>();
                typeMap[typeof(Single)] = typeof(Double);
                return typeMap;
            }
        }
        #endregion
        # region fields 
        private int _nrows=0;
        private string[] _cnames;
        private string[] _cdbtypes;
        private Type[] _ctypes;
        private SqlDataReader _reader;
        Dictionary<string, Array> _resultSet;
        int _capacity = -1;

        #region 
        public SqlDataHelper()
        {
         }
    
        public SqlDataHelper (SqlDataReader reader){
            _reader=reader;
            if (_cnames == null)
            {
                _cnames = new string[_reader.FieldCount];
                _cdbtypes = new string[_reader.FieldCount];
                _ctypes = new Type[_reader.FieldCount];
                for (int i = 0; i < _reader.FieldCount; i++)
                {
                    _cdbtypes[i] = _reader.GetDataTypeName(i);
                    _ctypes[i] = _reader.GetFieldType(i);
                    if (_ctypes[i] == typeof(System.Decimal))
                        _ctypes[i] = typeof(System.Double);
                    _cnames[i] = _reader.GetName(i);
                }
            }
	    }
        #endregion 
        #endregion
        #region props
        public int Fetched
        {
            get { return _nrows; }
        }
        public string[] Cnames
        {
            get { return _cnames; }
        }
        public string[] CDbtypes
        {
            get { return _cdbtypes; }
        }

        public Dictionary<string, Array> ResultSet
        {
            get { return _resultSet; }
        }
        public object TimeOut {
            get
            {
                PropertyInfo prop = _reader.GetType().GetProperty("Command",
                    BindingFlags.NonPublic | BindingFlags.Instance);

                SqlCommand cmd = (SqlCommand)prop.GetValue(_reader);
                return cmd.CommandTimeout;
            }
        }
        #endregion 
        #region global methods 
        public Object GetItem(SqlDataReader _reader, int i)
        {
            object value = _reader.GetValue(i);
            var fieldType = _reader.GetFieldType(i);
            //if (res != null && res.GetType() == typeof(DateTime))
            //    return ((DateTime)res).ToString("yyyy-MM-dd HH:mm:ss");
            if (value == DBNull.Value)
            {
                if (fieldType== typeof(String))
                    return string.Empty;
                else
                    return Single.NaN;
            }
            else  if (fieldType == typeof(long))
                return Convert.ToInt32(value);
            else if (fieldType == typeof(System.Decimal))
                return Convert.ToDouble(value);
            else
               return value;
        }

        public Object GetConnectionProperty(SqlConnection _conn, string prop)
        {
            if (_conn.State == ConnectionState.Closed &
                prop == "ServerVersion")
                return string.Empty;

            if (prop == "ClientConnectionId")
            {
                return _conn.GetClientConnectionId();
            }

            if (prop == "State")
            {
                return _conn.State.ToString();
            }
            return _conn.GetType().GetProperty(prop).GetValue(_conn);
        }

        public Object GetReaderProperty(string prop)
        {
           object val = null;
           if (String.Compare(prop ,"Fetched")==0)
               val = _nrows;
           else if(String.Compare(prop ,"Item")!=0){
               val =  _reader.GetType().GetProperty(prop).GetValue(_reader);
            }
            return val;
        }
        public int Fetch(int capacity)
        {
            int cnt = 0;
            if (_reader == null) return -1;
            setCapacity(capacity);
            while (_reader.Read())
            {
                // fetch rows and store data by column
                for (int i = 0; i < _reader.FieldCount; i++)
                {
                    var value = GetItem(_reader, i);
                    System.Type the_type = value.GetType();
                    if (the_type == typeof(System.Single))
                        ; //skip this or set to null
                    else if (the_type == typeof(System.Decimal))
                    {
                        //problem is that value can be NaN
                        object v = System.Convert.ToDouble(value);
                        _resultSet[_cnames[i]].SetValue(v, cnt);
                    }
                    else
                        //problem is that value can be NaN
                        _resultSet[_cnames[i]].SetValue(value, cnt);
                }
             
                cnt += 1;
                _nrows += 1;
                if (cnt >= capacity) return cnt;

            }
            // trim array 
            if (cnt < capacity)
                for (int i = 0; i < _reader.FieldCount; i++)
                    _resultSet[_cnames[i]] = TrimArray(_resultSet[_cnames[i]], cnt, i);
            // set nrows
            return cnt;
        }
        #endregion  
        #region tools
        private void setCapacity(int capacity){
            _capacity = capacity;
            _resultSet = new Dictionary<string, Array>();
            for (int i = 0; i < _reader.FieldCount; i++)
            {
                _ctypes[i]  = NetToRType.Keys.Contains(_ctypes[i]) ? NetToRType[_ctypes[i]] : _ctypes[i];
                _resultSet[_cnames[i]] = Array.CreateInstance(_ctypes[i], capacity);
            }
           
        }
        private Array TrimArray(Array source, int length,int curr)
        {
            Array destfoo = Array.CreateInstance(_ctypes[curr],length);
            Array.Copy(source, 0, destfoo, 0, length);
            return destfoo;
        }
        #endregion 

    }
}
