using Microsoft.Extensions.Logging;
using SmartFoundation.Application.Mapping;
using SmartFoundation.Application.Services.Models;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using System.Data;
using System.Text.Json;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Authentication data loader service.
/// Mirrors the same execution pattern used in MastersDataLoadService:
/// - params overload that builds a parameter dictionary
/// - dictionary-based overload that resolves SP, executes, logs, and converts to DataSet
/// </summary>
public sealed class AuthDataLoadService : BaseService
{
    public AuthDataLoadService(
        ISmartComponentService dataEngine,
        ILogger<AuthDataLoadService> logger)
        : base(dataEngine, logger)
    {
    }

    /// <summary>
    /// Params-based overload (pattern-matching MastersDataLoadService).
    /// Order:
    /// [0] UserID, [1] Password, [2] hostname, [3..] parameter_01..parameter_10 (optional)
    /// </summary>
    public async Task<DataSet> GetLoginDataSetAsync(params object?[] args)
    {
        string userId = args.Length > 0 ? args[0]?.ToString() ?? "" : "";
        string? password = args.Length > 1 ? args[1]?.ToString() : null;
        string? hostName = args.Length > 2 ? args[2]?.ToString() : null;

        var extraParams = args.Skip(3).ToArray();

        void AddIfHasValue(IDictionary<string, object?> d, string key, object? val)
        {
            if (val == null || val == DBNull.Value) return;
            d[key] = val;
        }

        var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);

        // Required/primary inputs
        dict["UserID"] = userId;
        AddIfHasValue(dict, "Password", password);
        AddIfHasValue(dict, "hostname", hostName);

        // parameter_01 .. parameter_10 (optional extras)
        int take = Math.Min(extraParams.Length, 10);
        for (int i = 1; i <= take; i++)
        {
            var val = extraParams[i - 1];
            if (val == DBNull.Value) val = null;
            AddIfHasValue(dict, $"parameter_{i:00}", val);
        }

        return await GetLoginDataSetAsync(dict);
    }

    /// <summary>
    /// Convenience overload to keep existing controller calls working.
    /// </summary>
    public async Task<DataSet> GetLoginDataSetAsync(string userId, string? password, string? hostname, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["UserID"] = userId,
            ["Password"] = password,
            ["hostname"] = hostname
        };

        return await GetLoginDataSetAsync(parameters, ct);
    }

    /// <summary>
    /// Executes the auth stored procedure using the same pattern as MastersDataLoadService:
    /// - Resolve SP via ProcedureMapper
    /// - Log, try/catch around DataEngine
    /// - Throw on response.Success == false
    /// - Convert SmartResponse to DataSet (always at least Table0)
    /// </summary>
    public async Task<DataSet> GetLoginDataSetAsync(Dictionary<string, object?> parameters, CancellationToken ct = default)
    {
        _logger.LogInformation("GetLoginDataSetAsync called with parameters: {Params}", JsonSerializer.Serialize(parameters));

        var spName = ProcedureMapper.GetProcedureName("auth", "sessions_");

        var request = new SmartRequest
        {
            Operation = "sp",
            SpName = spName,
            Params = parameters ?? new Dictionary<string, object?>()
        };

        SmartResponse response;
        try
        {
            response = await _dataEngine.ExecuteAsync(request, ct);
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

        return ConvertResponseToDataSet(response);
    }

    /// <summary>
    /// Map first row into AuthInfo. Returns inactive AuthInfo if no data.
    /// </summary>
    public AuthInfo ExtractAuth(DataSet ds)
    {
        if (ds == null)
        {
            _logger.LogWarning("ExtractAuth called with null DataSet.");
            return new AuthInfo(0, "لم يتم العثور  null على بيانات.", null, null, null, null, null, null, null, null);
        }

        if (ds.Tables.Count == 0)
        {
            _logger.LogWarning("ExtractAuth received DataSet with no tables.");
            return new AuthInfo(0, "لم يتم  zero العثور على بيانات.", null, null, null, null, null, null, null, null);
        }

        var t = ds.Tables[0];
        if (t.Rows.Count == 0)
        {
            _logger.LogInformation("ExtractAuth: first table has zero rows (likely invalid credentials).");
            return new AuthInfo(0, "لايوجد حساب نشط لهذا المستخدم", null, null, null, null, null, null, null, null);
        }

        var r = t.Rows[0];

        int useractive = ReadInt(r, new[] { "useractive", "IsSuccessful", "Success", "Result", "Code", "userActive" }, 0);
        string? message = ReadString(r, new[] { "Message_", "Message", "SuccessMessage" });

        string? userId = ReadString(r, new[] { "userID", "UserID" });
        string? IdaraID = ReadString(r, new[] { "IdaraID", "daraID" });
        string? fullName = ReadString(r, new[] { "fullName", "FullName", "name", "Name" });
        string? departmentName = ReadString(r, new[] { "DepartmentName" });
        int? deptCode = ReadNullableInt(r, new[] { "DeptCode", "DepartmentID" });
        string? IDNumber = ReadString(r, new[] { "IDNumber", "IdNumber" });
        string? themeName = ReadString(r, new[] { "ThameNAme", "ThemeName", "Theme" });

        string? photoBase64 = null;
        var photoObj = ReadObject(r, new[] { "Photo", "PhotoBase64" });
        if (photoObj is byte[] bytes && bytes.Length > 0)
            photoBase64 = Convert.ToBase64String(bytes);
        else if (photoObj is string s && !string.IsNullOrWhiteSpace(s))
            photoBase64 = s;

        return new AuthInfo(useractive, message, userId, IdaraID, fullName, departmentName, deptCode, IDNumber, photoBase64, themeName);
    }

    private static DataSet ConvertResponseToDataSet(SmartResponse response)
    {
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
                dr[col] = row.TryGetValue(col, out var val) ? (val ?? DBNull.Value) : DBNull.Value;
            dt.Rows.Add(dr);
        }
        return dt;
    }

    private static string? ReadString(DataRow r, string[] names)
    {
        foreach (var n in names)
            if (HasColumn(r.Table, n) && r[n] != DBNull.Value)
                return r[n]?.ToString();
        return null;
    }

    private static int ReadInt(DataRow r, string[] names, int def)
    {
        foreach (var n in names)
        {
            if (!HasColumn(r.Table, n) || r[n] == DBNull.Value) continue;
            var v = r[n];
            if (v is int i) return i;
            if (v is bool b) return b ? 1 : 0;
            if (int.TryParse(v.ToString(), out var parsed)) return parsed;
        }
        return def;
    }

    private static int? ReadNullableInt(DataRow r, string[] names)
    {
        foreach (var n in names)
        {
            if (!HasColumn(r.Table, n) || r[n] == DBNull.Value) continue;
            var v = r[n];
            if (v is int i) return i;
            if (int.TryParse(v.ToString(), out var parsed)) return parsed;
        }
        return null;
    }

    private static object? ReadObject(DataRow r, string[] names)
    {
        foreach (var n in names)
            if (HasColumn(r.Table, n) && r[n] != DBNull.Value)
                return r[n];
        return null;
    }

    private static bool HasColumn(DataTable t, string name) => t.Columns.Contains(name);
}