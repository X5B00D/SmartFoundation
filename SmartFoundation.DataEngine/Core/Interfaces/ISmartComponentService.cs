// كلاس: واجهة الخدمة الموحّدة لتنفيذ أي طلب SmartRequest وإرجاع SmartResponse.
using SmartFoundation.DataEngine.Core.Models;

namespace SmartFoundation.DataEngine.Core.Interfaces
{
    public interface ISmartComponentService
    {
        Task<SmartResponse> ExecuteAsync(SmartRequest request, CancellationToken ct = default);
    }
}
