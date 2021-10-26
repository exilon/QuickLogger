using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using QuickLogger.Extensions.NetCore.Configuration;
using QuickLogger.Extensions.Wrapper.Application.Services;
using System;
using System.Net;

namespace QuickLogger.Extensions.NetCore
{
    public static class QuickLoggerExtensions
    {
        internal static ILoggingBuilder AddLogger(ILoggingBuilder builder, ILoggerService loggerService)
        {
            builder.ClearProviders();
            builder.AddProvider(new QuickLoggerProvider(loggerService));
            return builder;
        }

        public static IServiceCollection AddQuickLogger(this IServiceCollection serviceCollection)
        {
            serviceCollection.AddSingleton<ILoggerSettingsPathFinder, CoreConfigPathFinder>();
            serviceCollection.AddSingleton<ILoggerService, QuickLoggerService>();

            serviceCollection.AddSingleton<IScopeInfoProviderService, ScopeInfoProvider>();
            serviceCollection.AddLogging(x => AddLogger(x, serviceCollection.BuildServiceProvider().GetService<ILoggerService>()));            
            return serviceCollection;
        }
    }
}
