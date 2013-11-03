using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xunit;

namespace rsqlserver.net.Test
{
    public class TestSqlDataHelper
    {

        static SqlConnection myConnection = new SqlConnection("user id=collateral;" +
                                     "password=collat;server=localhost;" +
                                     "Trusted_Connection=yes;" +
                                     "connection timeout=30");

        public static void TestGetItem()
        {
            try
            {
                myConnection.Open();
                SqlDataReader myReader = null;
                SqlCommand myCommand = new SqlCommand("select * from sys.tables",
                    myConnection);
                myReader = myCommand.ExecuteReader();
                object val = 0;
                while (myReader.Read())
                {
                    for (int i = 0; i < myReader.FieldCount; i++)
                        val = (new SqlDataHelper()).GetItem(myReader, i);

                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }

            Console.ReadLine();
        }
        public static void TestGetProperty()
        {

            try
            {
                myConnection.Open();
                var helper = new SqlDataHelper();
                var state = helper.GetConnectionProperty(myConnection, "State");
                myConnection.Close();
                foreach (var prop in myConnection.GetType().GetProperties())
                    Console.WriteLine(helper.GetConnectionProperty(myConnection, prop.Name));
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }
            finally
            {
                myConnection.Close();
            }
            Console.ReadLine();
        }
        public static void TestGetReaderProperty()
        {

            try
            {
                myConnection.Open();
                var helper = new SqlDataHelper();
                SqlCommand cmd = new SqlCommand("select * from sys.tables");
                cmd.Connection = myConnection;
                var reader = cmd.ExecuteReader();
                foreach (var prop in myConnection.GetType().GetProperties())
                    Console.WriteLine(helper.GetReaderProperty(reader, prop.Name));
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }
            finally
            {
                myConnection.Close();
            }
            Console.ReadLine();
        }

        public static void TestFetch()
        {
     
                using (myConnection)
                {
                    myConnection.Open();
                    SqlDataReader myReader = null;
                    var query = "SELECT  name,object_id,create_date \n" +
                                 "FROM    sys.tables";
                    SqlCommand myCommand = new SqlCommand(query, myConnection);
                    myReader = myCommand.ExecuteReader();
                    var helper = new SqlDataHelper();
                    var ll = helper.Fetch(myReader);
                }

 
        }


        

  
        static void Main(string[] args)
        {
          
        }
    }
}