namespace SmartFoundation.Application.Services.Models;

/// <summary>
/// Authentication result parsed from the login stored procedure.
/// </summary>
public sealed record AuthInfo(
    int useractive,                  // 0=Error, 1=Success, 2=Warning, 3=Info
    string? Message_,
    string? userId,
    string? IdaraID,
    string? fullName,
    string? DepartmentName,
    int? DeptCode,
    string? IDNumber,
    string? PhotoBase64,
    string? ThameName
    );