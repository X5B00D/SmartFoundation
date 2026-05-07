using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using QuestPDF.Drawing;
using QuestPDF.Infrastructure;
using SmartFoundation.Application.Extensions;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Services;
using SmartFoundation.DataEngine.Core.Utilities;
using SmartFoundation.Mvc.Controllers;
using SmartFoundation.Mvc.Helpers;
using SmartFoundation.Mvc.Services.AiAssistant;
using SmartFoundation.Mvc.Services.Chart;
using SmartFoundation.Mvc.Services.Exports.Pdf;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
QuestPDF.Settings.License = LicenseType.Community;

var fontPath = Path.Combine(builder.Environment.WebRootPath, "fonts", "Tajawal-Regular.ttf");
using (var fs = File.OpenRead(fontPath))
{
    FontManager.RegisterFont(fs);
}

builder.Services.AddControllersWithViews()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    });

builder.Services.AddRazorPages();

builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(o =>
{
    o.IdleTimeout = TimeSpan.FromMinutes(10);
    o.Cookie.HttpOnly = true;
    o.Cookie.IsEssential = true;
    o.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});

builder.Services.AddResponseCompression();
builder.Services.AddAntiforgery(o =>
{
    o.Cookie.HttpOnly = true;
    o.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});
builder.Services.AddHsts(o =>
{
    o.IncludeSubDomains = true;
    o.MaxAge = TimeSpan.FromDays(365);
});

builder.Services.AddSingleton<ConnectionFactory>();
builder.Services.AddScoped<ISmartComponentService, SmartComponentService>();
builder.Services.AddScoped<CrudController>();
builder.Services.AddScoped<IPdfExportService, QuestPdfExportService>();
builder.Services.AddApplicationServices();
builder.Services.Configure<AiAssistantOptions>(builder.Configuration.GetSection("AiAssistant"));
builder.Services.AddSingleton<IAiKnowledgeBase, FileAiKnowledgeBase>();
builder.Services.AddSingleton<LLamaModelHolder>(sp =>
{
    var opt = sp.GetRequiredService<IOptions<AiAssistantOptions>>().Value;
    var env = sp.GetRequiredService<IWebHostEnvironment>();
    var log = sp.GetRequiredService<ILogger<LLamaModelHolder>>();

    return new LLamaModelHolder(opt, env, log);
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<IAiChatService, EmbeddedLlamaChatService>();
builder.Services.AddScoped<Chart>();

var app = builder.Build();

UserPermissionSessionAccessor.Configure(
    app.Services.GetRequiredService<IHttpContextAccessor>()
);

app.UseResponseCompression();
app.UseHsts();
app.UseHttpsRedirection();
app.UseCookiePolicy(new CookiePolicyOptions
{
    Secure = CookieSecurePolicy.Always
});

app.Use(async (context, next) =>
{
    context.Response.OnStarting(() =>
    {
        var headers = context.Response.Headers;

        headers["X-Frame-Options"] = "SAMEORIGIN";
        headers["X-Content-Type-Options"] = "nosniff";
        headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains";

        headers["Cross-Origin-Opener-Policy"] = "same-origin";
        headers["Cross-Origin-Embedder-Policy"] = "require-corp";
        headers["Cross-Origin-Resource-Policy"] = "same-origin";
        headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";

        return Task.CompletedTask;
    });

    await next();
});

app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.UseSession();
app.MapRazorPages();
app.MapControllers();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Login}/{action=Index}/{id?}");

app.Run();