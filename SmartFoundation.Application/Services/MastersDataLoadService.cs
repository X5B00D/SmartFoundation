using Microsoft.Extensions.Logging;
using SmartFoundation.Application.Mapping;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using System.Data;
using System.Text.Json;


namespace SmartFoundation.Application.Services
{
    public class MastersDataLoadService : BaseService
    {

        public MastersDataLoadService(
     ISmartComponentService dataEngine,
     ILogger<EmployeeService> logger)
     : base(dataEngine, logger)
        {

        }


        public async Task<DataSet> GetDataLoadDataSetAsync(params object?[] args)
        {
            // الترتيب:
            // [0] pageName, [1] idaraID, [2] entryData, [3] hostName,
            // [4..] parameter_01..parameter_10 (فقط إلى 10 كما طلبت)

            string pageName = args.Length > 0 ? args[0]?.ToString() ?? "" : "";
            int? idaraID = args.Length > 1 ? (args[1] == null ? (int?)null : Convert.ToInt32(args[1])) : (int?)null;
            int? entryData = args.Length > 2 ? (args[2] == null ? (int?)null : Convert.ToInt32(args[2])) : (int?)null;
            string? hostName = args.Length > 3 ? args[3]?.ToString() : null;

            var extraParams = args.Skip(4).ToArray();

            // دالة مساعدة: تضيف المفتاح فقط إذا القيمة ليست null وليست DBNull
            void AddIfHasValue(IDictionary<string, object?> d, string key, object? val)
            {
                if (val == null || val == DBNull.Value) return;
                d[key] = val;
            }

            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);

            // القيم الأساسية
            // pageName غالبًا إجباري – نرسله حتى لو كان فاضي
            dict["pageName_"] = pageName;

            // البقية نضيفها فقط عند وجود قيمة
            AddIfHasValue(dict, "idaraID", idaraID);
            AddIfHasValue(dict, "entrydata", entryData);
            AddIfHasValue(dict, "hostname", hostName);

            // parameter_01 .. parameter_10 حسب ما تم تمريره فقط
            int take = Math.Min(extraParams.Length, 10);
            for (int i = 1; i <= take; i++)
            {
                var val = extraParams[i - 1];
                if (val == DBNull.Value) val = null; // أمان إضافي
                AddIfHasValue(dict, $"parameter_{i:00}", val);
            }

            // الآن استدعِ النسخة التي تقبل Dictionary (كما لديك)
            return await GetDataLoadDataSetAsync(dict);
        }


        //public async Task<DataSet> GetDataLoadDataSetAsync(params object?[] args)
        //    {


        //        string pageName = args.Length > 0 ? args[0]?.ToString() ?? "" : "";
        //        int? idaraID = args.Length > 1 ? Convert.ToInt32(args[1]) : (int?)null;
        //        int? entryData = args.Length > 2 ? Convert.ToInt32(args[2]) : (int?)null;
        //        string? hostName = args.Length > 3 ? args[3]?.ToString() : null;

        //        var extraParams = args.Skip(4).ToArray();

        //        object? Normalize(object? val) => val == DBNull.Value ? null : val;

        //        var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        //        {
        //            ["pageName_"] = pageName,
        //            ["idaraID"] = idaraID,
        //            ["entrydata"] = entryData,
        //            ["hostname"] = hostName,

        //            ["parameter_01"] = extraParams.ElementAtOrDefault(0),
        //            ["parameter_02"] = extraParams.ElementAtOrDefault(1),
        //            ["parameter_03"] = extraParams.ElementAtOrDefault(2),
        //            ["parameter_04"] = extraParams.ElementAtOrDefault(3),
        //            ["parameter_05"] = extraParams.ElementAtOrDefault(4),
        //            ["parameter_06"] = extraParams.ElementAtOrDefault(5),
        //            ["parameter_07"] = extraParams.ElementAtOrDefault(6),
        //            ["parameter_08"] = extraParams.ElementAtOrDefault(7),
        //            ["parameter_09"] = extraParams.ElementAtOrDefault(8),
        //            ["parameter_10"] = extraParams.ElementAtOrDefault(9)
        //        };

        //        // استدعاء الدالة الأصلية التي تستخدم Dictionary
        //        return await GetDataLoadDataSetAsync(dict);
        //    }




        public async Task<DataSet> GetDataLoadDataSetAsync(Dictionary<string, object?> parameters)
        {
            _logger.LogInformation("GetDataLoadDataSetAsync called with parameters: {Params}", JsonSerializer.Serialize(parameters));

            // Resolve SP name via ProcedureMapper (no hard-coded SP name)
            var spName = ProcedureMapper.GetProcedureName("MastersDataLoad", "getData");

            var request = new SmartRequest
            {
                Operation = "sp",
                SpName = spName,
                Params = parameters ?? new Dictionary<string, object?>()
            };

            SmartResponse response;
            try
            {
                response = await _dataEngine.ExecuteAsync(request);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing stored procedure {SpName}", spName);
                throw new InvalidOperationException($"Failed to execute stored procedure '{spName}': {ex.Message}", ex);
            }

            if (!response.Success)
            {
                var msg = response.Message ?? response.Error ?? "Stored procedure execution failed";
                _logger.LogWarning("Stored procedure {SpName} returned failure: {Message}", spName, msg);
                throw new InvalidOperationException(msg);
            }

            // Convert SmartResponse (Datasets / Data) to DataSet
            var ds = new DataSet();

            if (response.Datasets is { Count: > 0 })
            {
                for (var i = 0; i < response.Datasets.Count; i++)
                {
                    var rows = response.Datasets[i];
                    var dt = CreateDataTableFromRowList(rows, $"Table{i}");
                    ds.Tables.Add(dt);
                }
            }
            else if (response.Data is { Count: > 0 })
            {
                var dt = CreateDataTableFromRowList(response.Data, "Table0");
                ds.Tables.Add(dt);
            }
            else
            {
                ds.Tables.Add(new DataTable("Table0"));
            }

            return ds;
        }

        private static DataTable CreateDataTableFromRowList(List<Dictionary<string, object?>> rows, string tableName)
        {
            var dt = new DataTable(tableName);

            if (rows == null || rows.Count == 0)
                return dt;

            var allKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var row in rows)
                foreach (var k in row.Keys)
                    allKeys.Add(k);

            foreach (var col in allKeys)
                dt.Columns.Add(col, typeof(object));

            foreach (var row in rows)
            {
                var dr = dt.NewRow();
                foreach (var col in allKeys)
                {
                    if (row.TryGetValue(col, out var val))
                        dr[col] = val ?? DBNull.Value;
                    else
                        dr[col] = DBNull.Value;
                }
                dt.Rows.Add(dr);
            }

            return dt;
        }

    }
}
