using Microsoft.Extensions.Logging;
using SmartFoundation.Application.Mapping;
using SmartFoundation.Application.Services.Models;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using System.Data;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Auth data loader that follows the same DataSet pattern as MastersDataLoadService.
/// </summary>
public sealed class AuthDataLoadService : BaseService
{
    public AuthDataLoadService(
        ISmartComponentService dataEngine,
        ILogger<AuthDataLoadService> logger)
        : base(dataEngine, logger)
    {
    }

    public async Task<DataSet> GetLoginDataSetAsync(string userId, string? password, string? hostname, CancellationToken ct = default)
    {
        var spName = ProcedureMapper.GetProcedureName("auth", "sessions_");

        var request = new SmartRequest
        {
            Operation = "sp",
            SpName = spName,
            Params = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
            {
                ["UserID"] = userId,
                ["Password"] = password,
                ["hostname"] = hostname
            }
        };

        var response = await _dataEngine.ExecuteAsync(request, ct);

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

    /// <summary>
    /// Map first row into your updated AuthInfo shape.
    /// </summary>
    public AuthInfo ExtractAuth(DataSet ds)
    {
        //if (ds == null || ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0)
        //    return new AuthInfo(0, "لم يتم العثور على بيانات.", null, null, null, null, null, null);

        var t = ds.Tables[0];
        var r = t.Rows[0];

        // useractive: prefer explicit column, fallback to IsSuccessful/Success/Result/Code
        int useractive = ReadInt(r, new[] { "useractive", "IsSuccessful", "Success", "Result", "Code" }, 0);
        string? message = ReadString(r, new[] { "Message_", "Message", "SuccessMessage" });

        int? userId = ReadNullableInt(r, new[] { "userID", "UserID", "Id", "ID" });
        string? fullName = ReadString(r, new[] { "fullName", "FullName", "name", "Name" });
        string? departmentName = ReadString(r, new[] { "DepartmentName" });
        int? deptCode = ReadNullableInt(r, new[] { "DeptCode", "DepartmentID" }); // map to your new DeptCode
        string? themeName = ReadString(r, new[] { "ThameNAme", "ThemeName", "Theme" });

        string? photoBase64 = null;
        var photoObj = ReadObject(r, new[] { "Photo", "PhotoBase64" });
        if (photoObj is byte[] bytes && bytes.Length > 0)
            photoBase64 = Convert.ToBase64String(bytes);
        else if (photoObj is string s && !string.IsNullOrWhiteSpace(s))
            photoBase64 = s;

        return new AuthInfo(useractive, message, userId, fullName, departmentName, deptCode, photoBase64, themeName);
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