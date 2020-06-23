using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

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
            _logger.LogInformation("Index Called", this.GetType().FullName);
            return Ok();
        }
    }
}
