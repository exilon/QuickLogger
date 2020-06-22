using Microsoft.Extensions.Configuration;
using QuickLogger.Extensions.Wrapper.Application.Services;

namespace QuickLogger.Extensions.NetCore.Configuration
{
    public class CoreConfigPathFinder : ILoggerSettingsPathFinder
    {
        private readonly IConfiguration _configuration;
        public CoreConfigPathFinder(IConfiguration configuration)
        {
            _configuration = configuration;
        }
        public string GetSettingsPath()
        {
            return _configuration.GetSection("QuickLogger")["ConfigPath"];
        }
    }
}
