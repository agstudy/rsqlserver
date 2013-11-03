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
        private Dictionary<Type, DbType> NetToDbType{
            get
            {
                var typeMap = new Dictionary<Type, DbType>();
                typeMap[typeof(byte)] = DbType.Byte;
                typeMap[typeof(sbyte)] = DbType.SByte;
                typeMap[typeof(short)] = DbType.Int16;
                typeMap[typeof(ushort)] = DbType.UInt16;
                typeMap[typeof(int)] = DbType.Int32;
                typeMap[typeof(uint)] = DbType.UInt32;
                typeMap[typeof(long)] = DbType.Int64;
                typeMap[typeof(ulong)] = DbType.UInt64;
                typeMap[typeof(float)] = DbType.Single;
                typeMap[typeof(double)] = DbType.Double;
                typeMap[typeof(decimal)] = DbType.Decimal;
                typeMap[typeof(bool)] = DbType.Boolean;
                typeMap[typeof(string)] = DbType.String;
                typeMap[typeof(char)] = DbType.StringFixedLength;
                typeMap[typeof(Guid)] = DbType.Guid;
                typeMap[typeof(DateTime)] = DbType.DateTime;
                typeMap[typeof(DateTimeOffset)] = DbType.DateTimeOffset;
                typeMap[typeof(byte[])] = DbType.Binary;
                return typeMap;
            }
        }
        private Dictionary<string,Type> dbToNetType
        {
           get{
            var typeMap = new Dictionary<string, Type>();
            typeMap[DbType.Byte.ToString()] = typeof(byte);
            typeMap[DbType.SByte.ToString()] = typeof(sbyte);
            typeMap[DbType.Int16.ToString()] = typeof(short);
            typeMap[DbType.UInt16.ToString()] = typeof(ushort);
            typeMap[DbType.Int32.ToString()] = typeof(int);
            typeMap[DbType.UInt32.ToString()] = typeof(uint);
            typeMap[DbType.Int64.ToString()] = typeof(long);
            typeMap[DbType.UInt64.ToString()] = typeof(ulong);
            typeMap[DbType.Single.ToString()] = typeof(float);
            typeMap[DbType.Double.ToString()] = typeof(double);
            typeMap[DbType.Decimal.ToString()] = typeof(decimal);
            typeMap[DbType.Boolean.ToString()] = typeof(bool);
            typeMap[DbType.String.ToString()] = typeof(string);
            typeMap[DbType.StringFixedLength.ToString()] = typeof(char);
            typeMap[DbType.Guid.ToString()] = typeof(Guid);
            typeMap[DbType.DateTime.ToString()] = typeof(DateTime);
            typeMap[DbType.DateTimeOffset.ToString()] = typeof(DateTimeOffset);
            typeMap[DbType.Binary.ToString()] = typeof(byte[]); 
            return typeMap;
           }
        }
        #endregion
        # region fields 
        private const int MAX_ROWS = 100;
        private int _nrows=0;
        private string[] _cnames;
        private string[] _cdbtypes;
        private Type[] _ctypes;
        Dictionary<string, Array> _frame;
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
        #endregion 
        #region global methods 
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
            int cnt = 0;
            while (dr.Read() && cnt < MAX_ROWS)
            {
                // init cnames and ctypes
                if (_cnames == null)
                {
                    _cnames = new string[dr.FieldCount];
                    _cdbtypes = new string[dr.FieldCount];
                    _ctypes = new Type[dr.FieldCount];
                    _frame = new Dictionary<string, Array>();
                }

                // fetch rows and strore data by column
                for (int i = 0; i < dr.FieldCount; i++)
                {
                    // allocates structures memory the first row reached
                    if (cnt == 0)
                    {
                        string dbType = dr.GetDataTypeName(i);
                        _frame[_cnames[i]] = allocColumn(dbType, i);
                        _cnames[i] = dr.GetName(i);
                        _cdbtypes[i] = dbType;
                    }
                    // 
                    _frame[_cnames[i]].SetValue(dr.GetValue(i), cnt);
                }
                cnt += 1;
            }

            // trim array 
            if (cnt < MAX_ROWS)
                for (int i = 0; i < dr.FieldCount; i++)
                    _frame[_cnames[i]] = TrimArray(_frame[_cnames[i]], cnt, i);
            return _frame;
        }
        #endregion 
        #region tools
        private Array allocColumn(string dbType,int curr){
            _ctypes[curr] = dbToNetType[dbType];
            return Array.CreateInstance(_ctypes[curr], MAX_ROWS);
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
