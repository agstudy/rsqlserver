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

        private static string myConnectionString = "Server=localhost;Database=rsqlserverdb;User Id=sa;Password=Password12!;";
        static SqlConnection myConnection = new SqlConnection(myConnectionString);

        private static SqlDataHelper helper;



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
                SqlCommand cmd = new SqlCommand("select * from sys.tables");
                cmd.Connection = myConnection;
                var reader = cmd.ExecuteReader();
                var helper = new SqlDataHelper(reader);

                foreach (var prop in myConnection.GetType().GetProperties())
                    Console.WriteLine(helper.GetReaderProperty(prop.Name));
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

        [Fact]
        public static void TestFetch()
        {
            using (SqlConnection myConnection = new SqlConnection(myConnectionString))
            {
                myConnection.Open();
                SqlDataReader myReader = null;
                var query = "SELECT mpg, cyl, wt FROM CS_MTCARS";
                SqlCommand myCommand = new SqlCommand(query, myConnection);
                myReader = myCommand.ExecuteReader();
                helper = new SqlDataHelper(myReader);
                var result = helper.Fetch(20);
                Assert.Equal(20, result);
                Assert.Equal(helper.ResultSet.Keys.Count, 3);
                string[] cols = new string[] { "mpg", "cyl", "wt" };
                foreach (string key in helper.ResultSet.Keys)
                    Assert.Contains(key, cols);
                myConnection.Close();
            }

            Assert.Equal(helper.ResultSet["mpg"].Length, helper.Fetched);
            Assert.Equal(helper.ResultSet.Keys.Count, helper.Cnames.Length);
        }
        [Fact]
        public static void TestSqlBulkCopy()
        {
            misc.SqlBulkCopy(myConnectionString, "../../../../inst/data/CS_BIG.csv", "dbo.CS_BIG", true);
        }
        [Fact]
        public static void TestFetch_BIG_DATE_TABLE()
        {
            using (SqlConnection myConnection = new SqlConnection(myConnectionString))
            {
                myConnection.Open();
                SqlDataReader myReader = null;
                var query = "SELECT * FROM CS_DATE";

                SqlCommand myCommand = new SqlCommand(query, myConnection);
                myReader = myCommand.ExecuteReader();
                helper = new SqlDataHelper(myReader);
                var result = helper.Fetch(5);
                Assert.Equal(5, result);
                myConnection.Close();
            }
        }
        static void Main(string[] args)
        {
            myConnection.Open();
            SqlDataReader myReader = null;
            var helper = new SqlDataHelper();

            var state = helper.GetConnectionProperty(myConnection, "State");
            var query = "SELECT  * " + "FROM    TABLE_BUG";
            SqlCommand myCommand = new SqlCommand(query, myConnection);
            myReader = myCommand.ExecuteReader();
            helper = new SqlDataHelper(myReader);
            var result = helper.Fetch(20);
            helper.GetReaderProperty("Fetched");
            Console.ReadLine();

        }
    }
}
