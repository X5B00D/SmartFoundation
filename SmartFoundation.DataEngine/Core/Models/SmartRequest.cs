namespace SmartFoundation.DataEngine.Core.Models
{
    public sealed class SmartRequest
    {
        public string Component { get; set; } = "Table";
        public string Operation { get; set; } = "select";
        public string SpName { get; set; } = "";
        public Dictionary<string, object?> Params { get; set; } = [];
        public Paging Paging { get; set; } = new();
        public Sort? Sort { get; set; }

        // يفضل عدم جعلها nullable وتعيين قيمة افتراضية فارغة
        public List<Filter> Filters { get; set; } = [];
        public Dictionary<string, object?> Meta { get; set; } = [];
    }

    public sealed class Paging
    {
        public int Page { get; set; } = 1;
        public int Size { get; set; } = 10;
    }

    public sealed class Sort
    {
        public string? Field { get; set; }
        public string Dir { get; set; } = "asc";
    }

    public sealed class Filter
    {
        public string Field { get; set; } = "";
        public string Op { get; set; } = "=";
        public object? Value { get; set; }
    }
}
