// يهيّئ خدمات MVC/JSON والضغط، ويسجّل خدمات طبقة البيانات (ConnectionFactory + SmartComponentService).

using SmartFoundation.DataEngine.Core.Interfaces;    // ISmartComponentService
using SmartFoundation.DataEngine.Core.Services;      // SmartComponentService
using SmartFoundation.DataEngine.Core.Utilities;     // ConnectionFactory

var builder = WebApplication.CreateBuilder(args);

// MVC + JSON
// ✅ مهم: نفعل CamelCase عشان يتطابق spName → SpName, operation → Operation
builder.Services.AddControllersWithViews()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });

//builder.Services.AddControllers()
//    .AddJsonOptions(o => {
//        o.JsonSerializerOptions.PropertyNamingPolicy = null;
//    });


// (اختياري أثناء التطوير)
// builder.Services.AddControllersWithViews().AddRazorRuntimeCompilation();

builder.Services.AddResponseCompression(); // ضغط الاستجابة يقلل حجم JSON المنقول

// تسجيل خدمات طبقة البيانات (مرة واحدة فقط)
builder.Services.AddSingleton<ConnectionFactory>();
builder.Services.AddScoped<ISmartComponentService, SmartComponentService>();

var app = builder.Build();

app.UseResponseCompression();
app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
