using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using SmartFoundation.Application.Mapping;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;

namespace SmartFoundation.Mvc.Controllers
{
    /// <summary>
    /// Intelligent router controller that directs requests to the Application Layer
    /// or falls back to the legacy DataEngine for backward compatibility.
    /// </summary>
    [ApiController]
    [Route("smart")]
    public class SmartComponentController : ControllerBase
    {
        private readonly ISmartComponentService _dataEngine;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<SmartComponentController> _logger;

        /// <summary>
        /// Constructor for SmartComponentController with dependency injection.
        /// </summary>
        /// <param name="dataEngine">Legacy data engine service for backward compatibility</param>
        /// <param name="serviceProvider">Service provider for resolving Application Layer services</param>
        /// <param name="logger">Logger for diagnostic and monitoring purposes</param>
        public SmartComponentController(
            ISmartComponentService dataEngine,
            IServiceProvider serviceProvider,
            ILogger<SmartComponentController> logger)
        {
            _dataEngine = dataEngine;
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        /// <summary>
        /// Executes a request by routing to the Application Layer service if available,
        /// otherwise falls back to the legacy DataEngine.
        /// </summary>
        /// <param name="request">The smart request containing SP name, operation, and parameters</param>
        /// <param name="ct">Cancellation token for async operations</param>
        /// <returns>SmartResponse containing the result of the operation</returns>
        [HttpPost("execute")]
        public async Task<ActionResult<SmartResponse>> Execute([FromBody] SmartRequest request, CancellationToken ct)
        {
            try
            {
                // Attempt to resolve route to Application Layer service
                var route = ProcedureMapper.GetServiceRoute(request.SpName ?? "", request.Operation ?? "");

                if (route != null)
                {
                    // Application Layer path - use intelligent routing
                    _logger.LogInformation(
                        "Routing request to Application Layer: SP={SpName}, Operation={Operation}, Service={ServiceName}, Method={MethodName}",
                        request.SpName, request.Operation, route.ServiceName, route.MethodName);

                    try
                    {
                        // Resolve the service instance from DI container
                        var service = _serviceProvider.GetRequiredService(route.ServiceType);

                        // Get the method to invoke using reflection
                        var method = route.ServiceType.GetMethod(route.MethodName);
                        if (method == null)
                        {
                            _logger.LogError(
                                "Method {MethodName} not found on service type {ServiceType}",
                                route.MethodName, route.ServiceType.Name);

                            return StatusCode(500, new SmartResponse
                            {
                                Success = false,
                                Message = $"Method '{route.MethodName}' not found on service '{route.ServiceType.Name}'"
                            });
                        }

                        // Invoke the service method with parameters
                        var task = method.Invoke(service, new object[] { request.Params ?? new Dictionary<string, object?>() }) as Task<string>;
                        if (task == null)
                        {
                            _logger.LogError("Method invocation did not return Task<string>");
                            return StatusCode(500, new SmartResponse
                            {
                                Success = false,
                                Message = "Invalid service method signature"
                            });
                        }

                        // Await the task to get the JSON result
                        var jsonResult = await task;

                        // Deserialize JSON string to SmartResponse
                        var response = JsonSerializer.Deserialize<SmartResponse>(jsonResult, new JsonSerializerOptions
                        {
                            PropertyNameCaseInsensitive = true
                        });

                        _logger.LogInformation(
                            "Application Layer execution completed: Success={Success}",
                            response?.Success ?? false);

                        return Ok(response);
                    }
                    catch (InvalidOperationException ex)
                    {
                        // Service resolution failed
                        _logger.LogError(ex,
                            "Failed to resolve service {ServiceType} from DI container",
                            route.ServiceType.Name);

                        return StatusCode(500, new SmartResponse
                        {
                            Success = false,
                            Message = $"Service resolution failed: {ex.Message}"
                        });
                    }
                    catch (JsonException ex)
                    {
                        // JSON deserialization failed
                        _logger.LogError(ex, "Failed to deserialize service response to SmartResponse");

                        return StatusCode(500, new SmartResponse
                        {
                            Success = false,
                            Message = $"Response deserialization failed: {ex.Message}"
                        });
                    }
                    catch (Exception ex)
                    {
                        // Method invocation or other unexpected error
                        _logger.LogError(ex,
                            "Error invoking service method {MethodName} on {ServiceType}",
                            route.MethodName, route.ServiceType.Name);

                        return StatusCode(500, new SmartResponse
                        {
                            Success = false,
                            Message = $"Service invocation failed: {ex.Message}"
                        });
                    }
                }
                else
                {
                    // Legacy fallback path - no service route found
                    _logger.LogInformation(
                        "No service route found for SP={SpName}, Operation={Operation}. Falling back to legacy DataEngine",
                        request.SpName, request.Operation);

                    var result = await _dataEngine.ExecuteAsync(request, ct);
                    return Ok(result);
                }
            }
            catch (Exception ex)
            {
                // Top-level exception handler
                _logger.LogError(ex, "Unexpected error in Execute method");

                return StatusCode(500, new SmartResponse
                {
                    Success = false,
                    Message = $"Unexpected error: {ex.Message}"
                });
            }
        }
    }
}