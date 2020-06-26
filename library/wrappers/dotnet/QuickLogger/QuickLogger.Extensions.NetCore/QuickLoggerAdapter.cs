using Microsoft.Extensions.Logging;
using QuickLogger.Extensions.Wrapper.Application.Services;
using System;
using System.Collections.Generic;
using System.Text;

namespace QuickLogger.Extensions.NetCore
{
    public class QuickLoggerAdapter : ILogger
    {
        private readonly string _categoryName;
        private readonly ILoggerService _quickloggerInstance;

        public QuickLoggerAdapter(string categoryName,  ILoggerService quickloggerInstance)
        {
            _categoryName = categoryName;
            _quickloggerInstance = quickloggerInstance;
        }

        public IDisposable BeginScope<TState>(TState state)
        {
            return null;
        }

        public bool IsEnabled(LogLevel logLevel)
        {
            return true;
        }

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception exception, Func<TState, Exception, string> formatter)
        {
            switch (logLevel)
            {
                case LogLevel.Information :
                    _quickloggerInstance.Info(_categoryName,  $"{_categoryName}[{eventId.Id}] - {formatter(state, exception)}");
                    break;
                case LogLevel.Error:
                    _quickloggerInstance.Error(_categoryName, $"{_categoryName}[{eventId.Id}] - {formatter(state, exception)}");
                    break;
                case LogLevel.Warning:
                    _quickloggerInstance.Warning(_categoryName, $"{_categoryName}[{eventId.Id}] -  {formatter(state, exception)}");
                    break;
                case LogLevel.Critical:
                    _quickloggerInstance.Critical(_categoryName, $"{_categoryName}[{eventId.Id}] - {formatter(state, exception)}");
                    break;
                case LogLevel.Debug:
                    _quickloggerInstance.Debug(_categoryName, $"{_categoryName}[{eventId.Id}] - {formatter(state, exception)}");
                    break;
                case LogLevel.Trace:
                    _quickloggerInstance.Trace(_categoryName, $"{_categoryName}[{eventId.Id}] - {formatter(state, exception)}");
                    break;
            }

        }
    }
}
