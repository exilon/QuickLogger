using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using QuickLogger.Extensions.Wrapper.Application.Services;
using System.Collections.Concurrent;

namespace QuickLogger.Extensions.NetCore
{
    public class QuickLoggerProvider : ILoggerProvider
    {
        private readonly ILoggerService _quickloggerService;
        private readonly ConcurrentDictionary<string, QuickLoggerAdapter> _loggers = new ConcurrentDictionary<string, QuickLoggerAdapter>();

        public QuickLoggerProvider(ILoggerService quickloggerService)
        {

            _quickloggerService = quickloggerService;
        }

        public ILogger CreateLogger(string categoryName)
        {
            return _loggers.GetOrAdd(categoryName, name => new QuickLoggerAdapter(name, _quickloggerService));
        }

        public void Dispose()
        {
            _loggers.Clear();
        }
    }
}
