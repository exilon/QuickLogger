using Microsoft.Extensions.DependencyInjection;
using QuickLogger.Extensions.NetCore.Configuration;
using QuickLogger.Extensions.Wrapper.Application.Services;

namespace QuickLogger.Extensions.NetCore
{
    public static class QuickLoggerExtensions
    {
        public static IServiceCollection AddQuickLogger(this IServiceCollection serviceCollection)
        {
            serviceCollection.AddSingleton<ILoggerSettingsPathFinder, CoreConfigPathFinder>();
            serviceCollection.AddSingleton<ILoggerService, QuickLoggerService>();
            return serviceCollection;
        }
    }
}
