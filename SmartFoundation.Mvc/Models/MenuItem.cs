using System.Collections.Generic;

namespace SmartFoundation.Mvc.Models
{
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
}

}
