// كلاس: خدمة التنفيذ العامة عبر Dapper لأي SP مع دعم Paging/Sort/Filters والـ Whitelist.
using Dapper;
using Microsoft.Extensions.Configuration;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using SmartFoundation.DataEngine.Core.Utilities;
using System.Data;
using System.Diagnostics;

namespace SmartFoundation.DataEngine.Core.Services
{
    public class SmartComponentService(ConnectionFactory factory, IConfiguration config) : ISmartComponentService
    {
        private readonly ConnectionFactory _factory = factory;
        private readonly IConfiguration _config = config;

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

                // أمان: القائمة البيضاء
                //var whitelist = _config.GetSection("SmartData:Whitelist").Get<string[]>() ?? [];
                //if (whitelist.Length > 0 && !whitelist.Contains(request.SpName, StringComparer.OrdinalIgnoreCase))
                //    throw new UnauthorizedAccessException($"Stored Procedure '{request.SpName}' is not allowed.");

                // سقف حجم الصفحة
                var maxSize = _config.GetValue<int?>("SmartData:MaxPageSize") ?? 100;
                if (resp.Size > maxSize) resp.Size = maxSize;

                using var conn = _factory.Create();
                await conn.OpenAsync(ct);

                var dp = new DynamicParameters();

                // العملية + الصفحة
                dp.Add("@Operation", request.Operation ?? "select");
                dp.Add("@Page", resp.Page);
                dp.Add("@Size", resp.Size);

                // الفرز
                if (!string.IsNullOrWhiteSpace(request.Sort?.Field))
                {
                    dp.Add("@SortField", request.Sort!.Field);
                    dp.Add("@SortDir", request.Sort!.Dir ?? "asc");
                }

                // الفلاتر (JSON)
                if (request.Filters is { Count: > 0 })
                {
                    var filtersJson = System.Text.Json.JsonSerializer.Serialize(request.Filters);
                    dp.Add("@FiltersJson", filtersJson);
                }

                // باقي الباراميترات
                if (request.Params is not null)
                {
                    foreach (var kv in request.Params)
                        dp.Add("@" + kv.Key, kv.Value);
                }

                // نحاول Multiple Result Sets: Data ثم Total
                try
                {
                    using var grid = await conn.QueryMultipleAsync(
                        new CommandDefinition(request.SpName, dp, commandType: CommandType.StoredProcedure, cancellationToken: ct));

                    var rowsDyn = await grid.ReadAsync();

                    // ✅ نوع صريح + collection expression لإزالة IDE0028/IDE0030
                    List<Dictionary<string, object?>> data = [];
                    foreach (var row in rowsDyn)
                    {
                        var dict = (IDictionary<string, object?>)row;
                        data.Add(dict.ToDictionary(kv => kv.Key, kv => kv.Value));
                    }

                    var total = data.Count;

                    // محاولة قراءة إجمالي الصفوف من المجموعة الثانية إن وُجدت
                    if (!grid.IsConsumed)
                    {
                        var tRow = await grid.ReadFirstOrDefaultAsync();
                        if (tRow is not null)
                        {
                            var tDict = (IDictionary<string, object?>)tRow;
                            if (tDict.TryGetValue("Total", out var t)) total = Convert.ToInt32(t ?? 0);
                            else if (tDict.TryGetValue("total", out t)) total = Convert.ToInt32(t ?? 0);
                            else if (tDict.Values.FirstOrDefault() is { } any && int.TryParse(any?.ToString(), out var parsed)) total = parsed;
                        }
                    }

                    resp.Data = data;
                    resp.Total = total;
                }
                catch
                {
                    // بديل: SP تُرجع مجموعة واحدة فقط
                    var rowsDyn = await conn.QueryAsync(
                        new CommandDefinition(request.SpName, dp, commandType: CommandType.StoredProcedure, cancellationToken: ct));

                    // ✅ نوع صريح + collection expression
                    List<Dictionary<string, object?>> list = [];
                    foreach (var row in rowsDyn)
                    {
                        var dict = (IDictionary<string, object?>)row;
                        list.Add(dict.ToDictionary(kv => kv.Key, kv => kv.Value));
                    }

                    resp.Data = list;
                    resp.Total = resp.Data.Count;
                }

                resp.Success = true;
            }
            catch (Exception ex)
            {
                resp.Success = false;
                resp.Error = ex.Message;
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
