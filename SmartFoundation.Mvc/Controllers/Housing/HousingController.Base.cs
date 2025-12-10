using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.Mvc.Models;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Net;
using System.Net.Sockets;

namespace SmartFoundation.Mvc.Controllers.Housing
{
    public partial class HousingController : Controller
    {
        private readonly MastersServies _mastersServies;

        protected string? ControllerName;
        protected string? PageName;
        protected int userID;
        protected string? fullName;
        protected int IdaraID;
        protected string? DepartmentName;
        protected string? ThameName;
        protected string? DeptCode;
        protected string? IDNumber;
        protected string? HostName;

        protected DataTable? permissionTable;
        protected DataTable? dt1;
        protected DataTable? dt2;
        protected DataTable? dt3;
        protected DataTable? dt4;
        protected DataTable? dt5;
        protected DataTable? dt6;
        protected DataTable? dt7;
        protected DataTable? dt8;
        protected DataTable? dt9;

        public HousingController(MastersServies mastersServies)
        {
            _mastersServies = mastersServies;
        }

        public IActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// يقرأ بيانات السيشن ويعبّي المتغيّرات المشتركة
        /// يرجع false لو ما فيه user ويضبط redirect
        /// </summary>
        protected bool InitPageContext(out IActionResult? redirectResult)
        {
            redirectResult = null;

            if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("userID")))
            {
                redirectResult = RedirectToAction("Index", "Login", new { logout = 1 });
                return false;
            }

            ControllerName = ControllerContext.ActionDescriptor.ControllerName;
            PageName = ControllerContext.ActionDescriptor.ActionName;
            userID = Convert.ToInt32(HttpContext.Session.GetString("userID"));
            fullName = HttpContext.Session.GetString("fullName");
            IdaraID = Convert.ToInt32(HttpContext.Session.GetString("IdaraID"));
            DepartmentName = HttpContext.Session.GetString("DepartmentName");
            ThameName = HttpContext.Session.GetString("ThameName");
            DeptCode = HttpContext.Session.GetString("DeptCode");
            IDNumber = HttpContext.Session.GetString("IDNumber");
            HostName = HttpContext.Session.GetString("HostName");

            return true;
        }

        /// <summary>
        /// تقسيم الـ DataSet إلى جداول dt1..dt9 + جدول الصلاحيات
        /// </summary>
        protected void SplitDataSet(DataSet ds)
        {
            permissionTable = (ds?.Tables?.Count ?? 0) > 0 ? ds.Tables[0] : null;
            dt1 = (ds?.Tables?.Count ?? 0) > 1 ? ds.Tables[1] : null;
            dt2 = (ds?.Tables?.Count ?? 0) > 2 ? ds.Tables[2] : null;
            dt3 = (ds?.Tables?.Count ?? 0) > 3 ? ds.Tables[3] : null;
            dt4 = (ds?.Tables?.Count ?? 0) > 4 ? ds.Tables[4] : null;
            dt5 = (ds?.Tables?.Count ?? 0) > 5 ? ds.Tables[5] : null;
            dt6 = (ds?.Tables?.Count ?? 0) > 6 ? ds.Tables[6] : null;
            dt7 = (ds?.Tables?.Count ?? 0) > 7 ? ds.Tables[7] : null;
            dt8 = (ds?.Tables?.Count ?? 0) > 8 ? ds.Tables[8] : null;
            dt9 = (ds?.Tables?.Count ?? 0) > 9 ? ds.Tables[9] : null;
        }
    }
}
