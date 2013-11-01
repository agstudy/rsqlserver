using RDotNet;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace rsqlserver.net.Test
{
    class Program
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
            try
            {
                myConnection.Open();
                SqlDataReader myReader = null;
                SqlCommand myCommand = new SqlCommand("select * from sys.tables",
                    myConnection);
                myReader = myCommand.ExecuteReader();
                var helper = new SqlDataHelper();
                var ll = helper.Fetch(myReader);

            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }

            Console.ReadLine();
        }


        //static void Main(string[] args)
        //{
        //    //TestGetProperty();
        //    // var v = (new SqlDataHelper()).perfTest(1000);
        //    //TestGetReaderProperty();
        //    //TestFetch();

        //}
        public static void SetupPath(string Rversion = "R-3.0.0" )
        {
            var oldPath = System.Environment.GetEnvironmentVariable("PATH");
            var rPath = System.Environment.Is64BitProcess ? string.Format(@"C:\Program Files\R\{0}\bin\x64", Rversion) :
                                  string.Format(@"C:\Program Files\R\{0}\bin\i386", Rversion);

            if (!Directory.Exists(rPath))
                throw new DirectoryNotFoundException(string.Format("Could not found the specified path to the directory containing R.dll: {0}", rPath));
            var newPath = string.Format("{0}{1}{2}", rPath, System.IO.Path.PathSeparator, oldPath);
            System.Environment.SetEnvironmentVariable("PATH", newPath);
        }

        static void Main(string[] args)
        {
            //REngine.SetEnvironmentVariables(); // Currently under development - coming soon
            SetupPath(); // current process, soon to be deprecated
            using (REngine engine = REngine.CreateInstance("RDotNet"))
            {
                engine.Initialize(); // required since v1.5
                CharacterVector charVec = engine.CreateCharacterVector(new[] { "Hello, R world!, .NET speaking" });
                engine.SetSymbol("greetings", charVec);
                engine.Evaluate("str(greetings)"); // print out in the console
                string[] a = engine.Evaluate("'Hi there .NET, from the R engine'").AsCharacter().ToArray();
                Console.WriteLine("R answered: '{0}'", a[0]);
                Console.WriteLine("Press any key to exit the program");
                Console.ReadKey();
            }
        }
    }
}