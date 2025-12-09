using SmartFoundation.Application.Extensions;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Services;
using SmartFoundation.DataEngine.Core.Utilities;
using SmartFoundation.Mvc.Controllers;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    });

builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(o =>
{
    o.IdleTimeout = TimeSpan.FromMinutes(10); // 10-minute inactivity on server side
    o.Cookie.HttpOnly = true;
    o.Cookie.IsEssential = true;
});

builder.Services.AddResponseCompression();
builder.Services.AddSingleton<ConnectionFactory>();
builder.Services.AddScoped<ISmartComponentService, SmartComponentService>();
builder.Services.AddScoped<CrudController>();




// Register Application Layer services
builder.Services.AddApplicationServices();

var app = builder.Build();

app.UseResponseCompression();
app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseSession();
// (Optional: your existing guard middleware here)
app.UseAuthorization();

app.MapControllers();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Login}/{action=Index}/{id?}");
//app.MapRazorPages();

app.Run();
