using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Data;
using System.Collections;
namespace rsqlserver.net
{
    public class SqlDataHelper
    {
        #region map types
        //private Dictionary<Type, DbType> NetToDbType{
        //    get
        //    {
        //        var typeMap = new Dictionary<Type, DbType>();
        //        typeMap[typeof(byte)] = DbType.Byte;
        //        typeMap[typeof(sbyte)] = DbType.SByte;
        //        typeMap[typeof(short)] = DbType.Int16;
        //        typeMap[typeof(ushort)] = DbType.UInt16;
        //        typeMap[typeof(int)] = DbType.Int32;
        //        typeMap[typeof(uint)] = DbType.UInt32;
        //        typeMap[typeof(long)] = DbType.Int64;
        //        typeMap[typeof(ulong)] = DbType.UInt64;
        //        typeMap[typeof(float)] = DbType.Single;
        //        typeMap[typeof(double)] = DbType.Double;
        //        typeMap[typeof(decimal)] = DbType.Decimal;
        //        typeMap[typeof(bool)] = DbType.Boolean;
        //        typeMap[typeof(string)] = DbType.String;
        //        typeMap[typeof(char)] = DbType.StringFixedLength;
        //        typeMap[typeof(Guid)] = DbType.Guid;
        //        typeMap[typeof(DateTime)] = DbType.DateTime;
        //        typeMap[typeof(DateTimeOffset)] = DbType.DateTimeOffset;
        //        typeMap[typeof(byte[])] = DbType.Binary;
        //        return typeMap;
        //    }
        //}
        //private Dictionary<string,Type> dbToNetType
        //{
        //   get{
        //    var typeMap = new Dictionary<string, Type>();
        //    typeMap[DbType.Byte.ToString()] = typeof(byte);
        //    typeMap[DbType.SByte.ToString()] = typeof(sbyte);
        //    typeMap[DbType.Int16.ToString()] = typeof(short);
        //    typeMap[DbType.UInt16.ToString()] = typeof(ushort);
        //    typeMap[DbType.Int32.ToString()] = typeof(int);
        //    typeMap[DbType.UInt32.ToString()] = typeof(uint);
        //    typeMap[DbType.Int64.ToString()] = typeof(long);
        //    typeMap[DbType.UInt64.ToString()] = typeof(ulong);
        //    typeMap[DbType.Single.ToString()] = typeof(float);
        //    typeMap[DbType.Double.ToString()] = typeof(double);
        //    typeMap[DbType.Decimal.ToString()] = typeof(decimal);
        //    typeMap[DbType.Boolean.ToString()] = typeof(bool);
        //    typeMap[DbType.String.ToString()] = typeof(string);
        //    typeMap[DbType.StringFixedLength.ToString()] = typeof(char);
        //    typeMap[DbType.Guid.ToString()] = typeof(Guid);
        //    typeMap[DbType.DateTime.ToString()] = typeof(DateTime);
        //    typeMap[DbType.DateTimeOffset.ToString()] = typeof(DateTimeOffset);
        //    typeMap[DbType.Binary.ToString()] = typeof(byte[]); 
        //    return typeMap;
        //   }
        //}

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
                    _cnames[i] = _reader.GetName(i);
                }
            }
	    }
        #endregion 
        #endregion
        #region props
        public int Nrows
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
        #endregion 
        #region global methods 
        //public Object GetItem(SqlDataReader _dataReader, int i){
        //    object res = _dataReader[i];
        //    if (res != null && res.GetType() == typeof(Byte))
        //        return (int)(byte)res;
        //    if (res != null && res.GetType() == typeof(DateTime))
        //        return ((DateTime)res).ToString("yyyy-MM-dd HH:mm:ss");


        //    return res;
        //}
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
        public Object GetReaderProperty(string prop)
        {
           object val = null;
           if(String.Compare(prop ,"Item")!=0){
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
                    _resultSet[_cnames[i]].SetValue(_reader.GetValue(i), cnt);
                }
                cnt += 1;
                if (cnt >= capacity) return cnt;
            }
            // trim array 
            if (cnt < capacity)
                for (int i = 0; i < _reader.FieldCount; i++)
                    _resultSet[_cnames[i]] = TrimArray(_resultSet[_cnames[i]], cnt, i);
            // set nrows
            _nrows = cnt;
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
