using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;

namespace SmartFoundation.Mvc.Middleware
{
    public sealed class SessionGuardMiddleware
    {
        private static readonly PathString[] StaticPrefixes = new[]
        {
            new PathString("/css"),
            new PathString("/js"),
            new PathString("/lib"),
            new PathString("/images"),
            new PathString("/favicon.ico")
        };

        private static readonly string[] RequiredKeys = new[]
        {
            "usersID", "fullName", "IdaraID", "nationalID"
        };

        private readonly RequestDelegate _next;

        public SessionGuardMiddleware(RequestDelegate next) => _next = next;

        public async Task InvokeAsync(HttpContext context)
        {
            var path = context.Request.Path;

            // Skip static files quickly
            foreach (var p in StaticPrefixes)
            {
                if (path.StartsWithSegments(p, StringComparison.OrdinalIgnoreCase))
                {
                    await _next(context);
                    return;
                }
            }

            // Respect endpoints marked with [AllowAnonymous]
            var endpoint = context.GetEndpoint();
            if (endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null)
            {
                await _next(context);
                return;
            }

            // Allow Login path explicitly to avoid loops
            if (path.StartsWithSegments("/Login", StringComparison.OrdinalIgnoreCase))
            {
                await _next(context);
                return;
            }

            // Require session keys
            bool missing = false;
            foreach (var key in RequiredKeys)
            {
                var value = context.Session.GetString(key);
                Console.WriteLine($"[SessionGuard] Checking key '{key}': '{value ?? "NULL"}'");
                
                if (string.IsNullOrWhiteSpace(value))
                {
                    missing = true;
                    Console.WriteLine($"[SessionGuard] MISSING key: '{key}'");
                }
            }

            if (missing)
            {
                Console.WriteLine($"[SessionGuard] Access DENIED - redirecting to login");
                var isAjax = string.Equals(context.Request.Headers["X-Requested-With"], "XMLHttpRequest", StringComparison.OrdinalIgnoreCase);
                var acceptsJson = context.Request.Headers["Accept"].ToString().Contains("application/json", StringComparison.OrdinalIgnoreCase);

                if (isAjax || acceptsJson)
                {
                    context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    return;
                }

                context.Response.Redirect("/Login/Index?logout=1");
                return;
            }

            Console.WriteLine($"[SessionGuard] Access GRANTED - continuing to {context.Request.Path}");

            await _next(context);
        }
    }
}