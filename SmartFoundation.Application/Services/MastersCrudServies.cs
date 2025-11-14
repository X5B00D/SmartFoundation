using Microsoft.Extensions.Logging;
using SmartFoundation.Application.Mapping;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using System.Data;
using System.Text.Json;

namespace SmartFoundation.Application.Services
{
    /// <summary>
    /// Service for CRUD-style master operations with up to 50 dynamic parameters.
    /// Parameter order (positional overload):
    /// [0] pageName, [1] ActionType, [2] idaraID, [3] entryData, [4] hostName, [5..] parameter_01..parameter_50
    /// </summary>
    public class MastersCrudServies : BaseService
    {
        public MastersCrudServies(
            ISmartComponentService dataEngine,
            ILogger<MastersCrudServies> logger)
            : base(dataEngine, logger)
        {
        }

        /// <summary>
        /// Builds parameter dictionary from positional args then executes mapped stored procedure, returning a DataSet.
        /// </summary>
        /// <param name="args">
        /// [0] pageName (string, required/allow empty),
        /// [1] ActionType (string, optional),
        /// [2] idaraID (int?, optional),
        /// [3] entryData (int?, optional),
        /// [4] hostName (string?, optional),
        /// [5..54] parameter_01 .. parameter_50 (only added if non-null)
        /// </param>
        public async Task<DataSet> GetCrudDataSetAsync(params object?[] args)
        {
            string pageName = args.Length > 0 ? args[0]?.ToString() ?? "" : "";
            string? actionType = args.Length > 1 ? args[1]?.ToString() : null;
            int? idaraID = args.Length > 2 ? (args[2] == null ? (int?)null : Convert.ToInt32(args[2])) : null;
            int? entryData = args.Length > 3 ? (args[3] == null ? (int?)null : Convert.ToInt32(args[3])) : null;
            string? hostName = args.Length > 4 ? args[4]?.ToString() : null;

            var extraParams = args.Skip(5).ToArray();

            void AddIfHasValue(IDictionary<string, object?> d, string key, object? val)
            {
                if (val == null || val == DBNull.Value) return;
                d[key] = val;
            }

            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
            {
                ["pageName_"] = pageName
            };

            AddIfHasValue(dict, "ActionType", actionType);
            AddIfHasValue(dict, "idaraID", idaraID);
            AddIfHasValue(dict, "entrydata", entryData);
            AddIfHasValue(dict, "hostname", hostName);

            int take = Math.Min(extraParams.Length, 50);
            for (int i = 1; i <= take; i++)
            {
                var val = extraParams[i - 1];
                if (val == DBNull.Value) val = null;
                AddIfHasValue(dict, $"parameter_{i:00}", val);
            }

            return await ExecuteMappedAsync(dict);
        }

        /// <summary>
        /// Executes the mapped stored procedure and converts SmartResponse to DataSet.
        /// Requires a ProcedureMapper entry: "MastersCrud:getData" (add if missing).
        /// </summary>
        private async Task<DataSet> ExecuteMappedAsync(Dictionary<string, object?> parameters)
        {
            _logger.LogInformation("MastersCrudServies executing with params: {Params}",
                JsonSerializer.Serialize(parameters));

            var spName = ProcedureMapper.GetProcedureName("MastersCrud", "crud");

            var request = new SmartRequest
            {
                Operation = "sp",
                SpName = spName,
                Params = parameters
            };

            SmartResponse response;
            try
            {
                response = await _dataEngine.ExecuteAsync(request);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing SP {SpName}", spName);
                throw new InvalidOperationException($"Failed to execute stored procedure '{spName}': {ex.Message}", ex);
            }

            if (!response.Success)
            {
                var msg = response.Message ?? response.Error ?? "Stored procedure execution failed";
                _logger.LogWarning("Stored procedure {SpName} returned failure: {Message}", spName, msg);
                throw new InvalidOperationException(msg);
            }

            var ds = new DataSet();

            if (response.Datasets is { Count: > 0 })
            {
                for (int i = 0; i < response.Datasets.Count; i++)
                {
                    var rows = response.Datasets[i];
                    ds.Tables.Add(CreateDataTableFromRowList(rows, $"Table{i}"));
                }
            }
            else if (response.Data is { Count: > 0 })
            {
                ds.Tables.Add(CreateDataTableFromRowList(response.Data, "Table0"));
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
            if (rows == null || rows.Count == 0) return dt;

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
                    dr[col] = row.TryGetValue(col, out var val) && val != null ? val : DBNull.Value;
                dt.Rows.Add(dr);
            }
            return dt;
        }
    }
}
