using log4net;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Transactions;
using LumenWorks.Framework.IO.Csv;

namespace rsqlserver.net
{
    public class misc
    {
        private static readonly ILog _Logger = LogManager.GetLogger(typeof(misc));

        static misc() {
            InitLog();
        }

        private static void InitLog()
        {
            string asmFile = System.Reflection.Assembly.GetExecutingAssembly().Location;
            Configuration dllConfig = ConfigurationManager.OpenExeConfiguration(asmFile);
            string fileName = Path.GetDirectoryName(asmFile) + "/log4net.config";
            if (!dllConfig.HasFile && File.Exists(fileName))
            {
                System.IO.FileInfo configFileInfo = new System.IO.FileInfo(fileName);
                log4net.Config.XmlConfigurator.Configure(configFileInfo);
            }
            _Logger.Info("I am rsqlserver logger");
        }

        public static Single[] GetSingleArray()
        {
            Single[] r = new Single[2] { Single.MaxValue, Single.MinValue };
            return r;
        }

        public static double[] FromSingle2DoubleArray()
        {
            var r = GetSingleArray();
            double[] dar = new double[r.Length];
            for (int i = 0; i < r.Length; i++)
                dar[i] = (double)r[i];
            return dar;
        }

        public static DataTable fileToDataTable(string CSVFilePathName)
        {
            DataTable dt = new DataTable();
            try
            {
                string[] Lines = File.ReadAllLines(CSVFilePathName);
                string[] Fields;
                Fields = Lines[0].Split(new char[] { ',' });
                int Cols = Fields.GetLength(0);
                //1st row must be column names; force lower case to ensure matching later on.
                for (int i = 0; i < Cols; i++)
                    dt.Columns.Add(Fields[i].ToLower(), typeof(string));
                DataRow Row;
                for (int i = 1; i < Lines.GetLength(0); i++)
                {
                    Fields = Lines[i].Split(new char[] { ',' });
                    Row = dt.NewRow();
                    for (int f = 0; f < Cols; f++)
                        Row[f] = Fields[f];
                    dt.Rows.Add(Row);
                }
            }
            catch (FileNotFoundException exception)
            {
                _Logger.DebugFormat("Error {0}", exception.Message);
                dt = null;
            }
            catch (Exception ex)
            {
                _Logger.DebugFormat("Error {0}", ex.Message);
                dt = null;
            }
            return dt;

        }



        public static void SqlBulkCopy(String connectionString, string sourcePath, string destTableName, Boolean hasHeaders = true, String delimiter = ",")
        {
            using (var reader = new CsvReader(new StreamReader(sourcePath), hasHeaders, System.Convert.ToChar(delimiter)))
            {

                using (SqlConnection destConnection =
                           new SqlConnection(connectionString))
                {
                    destConnection.Open();
                    try
                    {
                        using (SqlBulkCopy bulkCopy =
                                   new SqlBulkCopy(destConnection))
                        {
                            bulkCopy.DestinationTableName = destTableName;
                            _Logger.InfoFormat("copying table {0} ....", destTableName);
                            bulkCopy.BulkCopyTimeout = 60;
                            bulkCopy.WriteToServer(reader);
                            _Logger.InfoFormat("Success loading table {0} having {1} rows in database", destTableName, reader.CurrentRecordIndex);
                            _Logger.Info("Success copy");
                        }
                    }
                    catch (Exception ex)
                    {
                        _Logger.DebugFormat("Failure to copy : {0}", ex.Message);
                        throw ex;
                    }
                }
            }
        }

        private static void writerHelper(StreamWriter writer, SqlDataReader reader, String delimiter, bool headerrow)
        {
            String row = "";
            for (int i = 0; i < reader.FieldCount; i++)
            {
                if (headerrow)
                {
                    row += delimiter + "\"" + reader.GetName(i).ToString() + "\"";
                }
                else
                {
                    row += delimiter + "\"" + reader[i].ToString() + "\"";
                }
            }
            writer.WriteLine(row.Substring(1));
        }

        public static void SqlBulkWrite(String connectionString, string destFilePath, string sourceTableName, Boolean withHeaders = true, String delimiter = ",")
        {
            using (SqlConnection destConnection = new SqlConnection(connectionString))
            using (SqlCommand cmd = destConnection.CreateCommand())
            {
                destConnection.Open();

                String sql = @"SELECT * FROM " + sourceTableName;
                cmd.CommandText = sql;

                using (SqlDataReader reader = cmd.ExecuteReader())
                using (StreamWriter writer = new StreamWriter(destFilePath))
                {
                    //TODO rewrite block below / writerHelper more effectively
                    if (withHeaders)
                    {
                        writerHelper(writer, reader, delimiter, true);
                    }

                    while (reader.Read())
                    {
                        writerHelper(writer, reader, delimiter, false);
                    }
                }
            }
        }
    }
}
       
