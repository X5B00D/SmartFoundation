// خدمة تنفيذ عام عبر Dapper مع أمان + Logging + Validation
using Dapper;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using SmartFoundation.DataEngine.Core.Utilities;
using System.Data;
using System.Diagnostics;
using System.Text.Json;

namespace SmartFoundation.DataEngine.Core.Services
{
    public class SmartComponentService : ISmartComponentService
    {
        private readonly ConnectionFactory _factory;
        private readonly IConfiguration _config;
        private readonly ILogger<SmartComponentService> _logger;

        public SmartComponentService(ConnectionFactory factory, IConfiguration config, ILogger<SmartComponentService> logger)
        {
            _factory = factory;
            _config = config;
            _logger = logger;
        }

        public async Task<SmartResponse> ExecuteAsync(SmartRequest request, CancellationToken ct = default)
        {
            var sw = Stopwatch.StartNew();

            var resp = new SmartResponse
            {
                Page = request.Paging?.Page ?? 1,
                Size = request.Paging?.Size ?? 10
            };

            try
            {
                if (string.IsNullOrWhiteSpace(request.SpName))
                    throw new ArgumentException("SpName is required.");

                //  القائمة البيضاء
                var whitelist = _config.GetSection("SmartData:Whitelist").Get<string[]>() ?? [];
                if (whitelist.Length > 0 && !whitelist.Contains(request.SpName, StringComparer.OrdinalIgnoreCase))
                {
                    _logger.LogWarning("محاولة استدعاء SP غير مسموح: {SpName}", request.SpName);
                    throw new UnauthorizedAccessException($"Stored Procedure '{request.SpName}' is not allowed.");
                }

                var maxSize = _config.GetValue<int?>("SmartData:MaxPageSize") ?? 100;
                if (resp.Size > maxSize) resp.Size = maxSize;

                using var conn = _factory.Create();
                await conn.OpenAsync(ct);

                var dp = new DynamicParameters();

                dp.Add("@Operation", request.Operation ?? "select");
                dp.Add("@Page", resp.Page);
                dp.Add("@Size", resp.Size);

                if (!string.IsNullOrWhiteSpace(request.Sort?.Field))
                {
                    dp.Add("@SortField", request.Sort!.Field);
                    dp.Add("@SortDir", request.Sort!.Dir ?? "asc");
                }

                //  الفلاتر (JSON)
                if (request.Filters is { Count: > 0 })
                {
                    foreach (var f in request.Filters)
                    {
                        if (string.IsNullOrWhiteSpace(f.Field))
                            throw new ArgumentException("Filter field name is required.");
                    }
                    var filtersJson = JsonSerializer.Serialize(request.Filters);
                    dp.Add("@FiltersJson", filtersJson);
                }

                //  الباراميترات 
                if (request.Params is not null)
                {
                    foreach (var kv in request.Params)
                    {
                        if (string.IsNullOrWhiteSpace(kv.Key))
                            throw new ArgumentException("Parameter key is required.");

                        object? val = kv.Value;

                        if (val is JsonElement je)
                        {
                            val = je.ValueKind switch
                            {
                                JsonValueKind.String => je.GetString(),
                                JsonValueKind.Number => je.TryGetInt64(out var l) ? l : je.GetDouble(),
                                JsonValueKind.True => true,
                                JsonValueKind.False => false,
                                JsonValueKind.Null => null,
                                _ => je.ToString()
                            };
                        }

                        if (val is bool b)
                            val = b ? 1 : 0;
                        if (val is string s && string.IsNullOrWhiteSpace(s))
                            val = null;

                        dp.Add("@" + kv.Key, val ?? DBNull.Value);
                    }
                }

                // Multiple Result Sets
                try
                {
                    using var grid = await conn.QueryMultipleAsync(
                        new CommandDefinition(request.SpName, dp, commandType: CommandType.StoredProcedure, cancellationToken: ct));

                    var rowsDyn = await grid.ReadAsync();
                    List<Dictionary<string, object?>> data = [];

                    foreach (var row in rowsDyn)
                    {
                        var dict = (IDictionary<string, object?>)row;
                        data.Add(dict.ToDictionary(kv => kv.Key, kv => kv.Value));
                    }

                    var total = data.Count;

                    
                    if (data.Count > 0)
                    {
                        var msgKey = data[0].Keys.FirstOrDefault(k => k.Equals("Message", StringComparison.OrdinalIgnoreCase));
                        if (msgKey != null && data[0][msgKey] != null)
                        {
                            resp.Message = data[0][msgKey]?.ToString();
                        }
                    }

                    
                    if (!grid.IsConsumed)
                    {
                        var tRow = await grid.ReadFirstOrDefaultAsync();
                        if (tRow is not null)
                        {
                            var tDict = (IDictionary<string, object?>)tRow;

                            if (tDict.TryGetValue("Total", out var t)) total = Convert.ToInt32(t ?? 0);
                            else if (tDict.TryGetValue("total", out t)) total = Convert.ToInt32(t ?? 0);
                            else if (tDict.Values.FirstOrDefault() is { } any && int.TryParse(any?.ToString(), out var parsed)) total = parsed;

                            var msgKey = tDict.Keys.FirstOrDefault(k => k.Equals("Message", StringComparison.OrdinalIgnoreCase));
                            if (msgKey != null && tDict[msgKey] != null)
                            {
                                resp.Message = tDict[msgKey]?.ToString();
                            }
                        }
                    }

                    resp.Data = data;
                    resp.Total = total;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "فشل في قراءة Multiple Result Sets لـ {SpName}", request.SpName);

                    var rowsDyn = await conn.QueryAsync(
                        new CommandDefinition(request.SpName, dp, commandType: CommandType.StoredProcedure, cancellationToken: ct));

                    List<Dictionary<string, object?>> list = [];
                    foreach (var row in rowsDyn)
                    {
                        var dict = (IDictionary<string, object?>)row;
                        list.Add(dict.ToDictionary(kv => kv.Key, kv => kv.Value));
                    }

                    resp.Data = list;
                    resp.Total = resp.Data.Count;

                    
                    if (list.Count > 0)
                    {
                        var msgKey = list[0].Keys.FirstOrDefault(k => k.Equals("Message", StringComparison.OrdinalIgnoreCase));
                        if (msgKey != null && list[0][msgKey] != null)
                        {
                            resp.Message = list[0][msgKey]?.ToString();
                        }
                    }
                }

                resp.Success = true;
                _logger.LogInformation("تم تنفيذ {SpName} بنجاح في {Duration}ms مع {Count} سجل",
                    request.SpName, sw.ElapsedMilliseconds, resp.Total);
            }
            catch (Exception ex)
            {
                resp.Success = false;
                resp.Error = ex.Message;
                _logger.LogError(ex, "خطأ أثناء تنفيذ SP: {SpName}", request.SpName);
            }
            finally
            {
                sw.Stop();
                resp.DurationMs = sw.ElapsedMilliseconds;
            }

            return resp;
        }
    }
}
