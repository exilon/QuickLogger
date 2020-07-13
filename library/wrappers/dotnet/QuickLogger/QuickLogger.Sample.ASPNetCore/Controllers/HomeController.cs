using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;

namespace QuickLogger.Sample.ASPNetCore.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController : ControllerBase
    {
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> Logger)
        {
            _logger = Logger;
        }

        public IActionResult Index()
        {
            var exception = new Exception("Test exception");
            _logger.LogError(3, exception, "error");
            _logger.LogDebug("Index Called, debug");
            _logger.LogError("Index Called, error");
            _logger.LogTrace("Index Called, trace");
            _logger.LogCritical("Index Called, critical");
            _logger.LogWarning("Index Called, warning");
            _logger.LogInformation("Index Called, information");
            return Ok();
        }
    }
}
