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
            "userID", "fullName", "IdaraID", "IDNumber"
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
                if (string.IsNullOrWhiteSpace(context.Session.GetString(key)))
                {
                    missing = true;
                    break;
                }
            }

            if (missing)
            {
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

            await _next(context);
        }
    }
}