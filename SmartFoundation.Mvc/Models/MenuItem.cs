using System.Collections.Generic;

namespace SmartFoundation.Mvc.Models
{
    /// <summary>
    /// Represents a menu item returned from the stored procedure.
    /// Includes raw columns and normalized fields for routing.
    /// </summary>
    public class MenuItem
    {
        public int MPID { get; set; }
        public string MenuName_A { get; set; }
        public int? MPSerial { get; set; }
        public string MPLink { get; set; }
        public int? ParentMenuID_FK { get; set; }
        public int? ProgramID { get; set; }
        public int? Parents { get; set; }
        public int? Levels { get; set; }
        public string MPIcon { get; set; }

        public string? MenuNameForView { get; set; }
        public int? LevelNo { get; set; }

        public string? PathName_A { get; set; }
        public string? PathName_E { get; set; }
        public string? ProgramName_A { get; set; }
        public string? ProgramName_E { get; set; }
        public string? ProgramIcon { get; set; }
        public string? ProgramLink { get; set; }
        public int? ProgramSerial { get; set; }
        public int? MenuID { get; set; }
        public string? MenuName_E { get; set; }
        public string? MenuDescription { get; set; }
        public int? MenuSerial { get; set; }
        public int? MenuActive { get; set; }
        public int? IsDashboard { get; set; }
        public string? SortKey { get; set; }
        public int? HasPermissionForUser { get; set; }
        public string? IndentedMenuName { get; set; }

        // Routing (action name). If null/empty, parent should toggle children instead of navigating.
        public string? MenuLink { get; set; }

        // Children for hierarchy rendering (must be non-null)
        public List<MenuItem> Children { get; set; } = new();
    }
}
