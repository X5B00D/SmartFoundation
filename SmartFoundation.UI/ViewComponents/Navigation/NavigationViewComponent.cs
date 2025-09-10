//using System.Data;
//using Microsoft.AspNetCore.Http;
//using Microsoft.AspNetCore.Mvc;
//using Microsoft.Extensions.Logging;
//using SmartFoundation.DataEngine.Core.Utilities;          
//using SmartFoundation.UI.ViewModels.Navigation;

//namespace SmartFoundation.UI.ViewComponents.Navigation
//{
//    public sealed class NavigationViewComponent : ViewComponent
//    {
//        private readonly ConnectionFactory _factory;
//        private readonly ILogger<NavigationViewComponent> _logger;

//        public NavigationViewComponent(ConnectionFactory factory, ILogger<NavigationViewComponent> logger = null)
//        {
//            _factory = factory ?? throw new ArgumentNullException(nameof(factory));
//            _logger = logger;
//        }

//        public async Task<IViewComponentResult> InvokeAsync()
//        {
//            try
//            {
//                var generalNo = GetGeneralNoSafe(HttpContext);
//                var rows = await FetchLegacyMenuRowsAsync(generalNo);
//                var tree = NavigationAdapter.BuildTree(rows);

//                var vm = new NavigationViewModel
//                {
//                    AppName = "KFMC",
//                    UserName = HttpContext?.User?.Identity?.Name ?? "User",
//                    CurrentUrl = HttpContext?.Request?.Path.Value,
//                    Top = tree,
//                    Side = tree,
//                    Footer = tree
//                };

//                return View("Default", vm);
//            }
//            catch (Exception ex)
//            {
//                _logger?.LogError(ex, "Error loading navigation menu");
                
//                // Return fallback navigation with minimal items
//                var fallbackNavigation = new List<NavItem> {
//                    new NavItem { Id = 1, Text = "الرئيسية", Url = "/", Icon = "fa fa-home" },
//                    new NavItem { Id = 2, Text = "الملف الشخصي", Url = "/profile", Icon = "fa fa-user" }
//                };

//                var vm = new NavigationViewModel
//                {
//                    AppName = "KFMC",
//                    UserName = HttpContext?.User?.Identity?.Name ?? "User",
//                    CurrentUrl = HttpContext?.Request?.Path.Value,
//                    Top = fallbackNavigation,
//                    Side = fallbackNavigation,
//                    Footer = fallbackNavigation
//                };

//                return View("Default", vm);
//            }
//        }

//        private static int GetGeneralNoSafe(HttpContext? http)
//        {
//            var fromClaim = http?.User?.FindFirst("generalNo")?.Value;
//            var fromSess = http?.Session?.GetString("generalNo");
//            var candidate = !string.IsNullOrWhiteSpace(fromClaim) ? fromClaim : fromSess;
//            return int.TryParse(candidate, out var value) ? value : 60014020;
//        }

//        private async Task<List<LegacyMenuRow>> FetchLegacyMenuRowsAsync(int generalNo)
//        {
//            var rows = new List<LegacyMenuRow>();

//            try
//            {
//                using var conn = _factory.Create();
//                if (conn.State != ConnectionState.Open) 
//                    await conn.OpenAsync();

//                using var cmd = conn.CreateCommand();
//                cmd.CommandText = "[dbo].[ListOfMenuByUser_MVC]";
//                cmd.CommandType = CommandType.StoredProcedure;

//                var p = cmd.CreateParameter();
//                p.ParameterName = "@generalNo";
//                p.Value = generalNo;
//                cmd.Parameters.Add(p);

//                using var rdr = (cmd is System.Data.Common.DbCommand dbc)
//                    ? await dbc.ExecuteReaderAsync()
//                    : cmd.ExecuteReader();

//                int Ord(string name) { try { return rdr.GetOrdinal(name); } catch { return -1; } }

//                var oId = Ord("MPID");
//                var oName = Ord("menuName_A");
//                var oSerial = Ord("MPSerial");
//                var oLink = Ord("MPLink");
//                var oParent = Ord("parentMenuID_FK");
//                var oProg = Ord("programID");
//                var oLevel = Ord("Levels");
//                var oIcon = Ord("MPIcon");

//                while (rdr.Read())
//                {
//                    rows.Add(new LegacyMenuRow
//                    {
//                        MPID = oId >= 0 ? Convert.ToInt32(rdr.GetValue(oId)) : 0,
//                        menuName_A = oName >= 0 ? rdr.GetValue(oName)?.ToString() : null,
//                        MPSerial = oSerial >= 0 ? ToNullableInt(rdr.GetValue(oSerial)) : null,
//                        MPLink = oLink >= 0 ? rdr.GetValue(oLink)?.ToString() : null,
//                        parentMenuID_FK = oParent >= 0 ? ToNullableInt(rdr.GetValue(oParent)) : null,
//                        programID = oProg >= 0 ? ToNullableInt(rdr.GetValue(oProg)) : null,
//                        Levels = oLevel >= 0 ? ToNullableInt(rdr.GetValue(oLevel)) : null,
//                        MPIcon = oIcon >= 0 ? rdr.GetValue(oIcon)?.ToString() : null
//                    });
//                }
//            }
//            catch (Exception ex)
//            {
//                _logger?.LogError(ex, "Error fetching menu items for user {GeneralNo}", generalNo);
//                throw;
//            }

//            return rows;
//        }

//        private static int? ToNullableInt(object? v)
//            => v == null || v == DBNull.Value ? null : Convert.ToInt32(v);
//    }
//}
