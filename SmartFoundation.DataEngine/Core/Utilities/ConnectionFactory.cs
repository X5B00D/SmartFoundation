// كلاس: ينشئ اتصال SQL جديد باستخدام ConnectionStrings:Default.
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace SmartFoundation.DataEngine.Core.Utilities
{
    public class ConnectionFactory(IConfiguration config)
    {
        private readonly string _cs = config.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Missing ConnectionStrings:Default.");

        public SqlConnection Create() => new(_cs);
    }
}