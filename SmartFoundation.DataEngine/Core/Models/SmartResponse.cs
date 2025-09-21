namespace SmartFoundation.DataEngine.Core.Models
{
    
    public sealed class SmartResponse
    {
        public bool Success { get; set; }
        public int Page { get; set; }
        public int Size { get; set; }
        public int Total { get; set; }
        public List<Dictionary<string, object?>> Data { get; set; } = [];
        public Dictionary<string, object?> Meta { get; set; } = [];
        public string? Error { get; set; }
        public string? Message { get; set; }  
        public long DurationMs { get; set; }
    }
}
