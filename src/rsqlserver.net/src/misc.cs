using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace rsqlserver.net
{
    public class misc
    {
        public static Single[] GetSingleArray()
        {
            Single[] r = new Single[2] { Single.MaxValue, Single.MinValue };
            return r;
        }

        public static double[] FromSingle2DoubleArray()
        {
            var r = GetSingleArray();
            double[] dar = new double[r.Length];
            for(int i =0;i < r.Length; i++)
                dar[i] = (double)r[i];
            return dar;
        }

    }
}
