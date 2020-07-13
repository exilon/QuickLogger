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
            var msg = formatter(state, exception);
            switch (logLevel)
            {
                case LogLevel.Information :
                    if (exception == null)
                        _quickloggerInstance.Info(_categoryName, $"{_categoryName}[{eventId.Id}] - {state}");
                    else
                        _quickloggerInstance.Info(_categoryName, exception, $"{_categoryName}[{eventId.Id}] - {state}");
                    break;
                case LogLevel.Error:
                    if (exception == null)
                        _quickloggerInstance.Error(_categoryName, $"{_categoryName}[{eventId.Id}] - {state}");
                    else
                        _quickloggerInstance.Error(_categoryName, exception, $"{_categoryName}[{eventId.Id}] - {state}");
                    break;
                case LogLevel.Warning:
                    if (exception == null)
                        _quickloggerInstance.Warning(_categoryName, $"{_categoryName}[{eventId.Id}] - {state}");
                    else
                        _quickloggerInstance.Warning(_categoryName, exception, $"{_categoryName}[{eventId.Id}] - {state}");
                    break;
                case LogLevel.Critical:
                    if (exception == null)
                        _quickloggerInstance.Critical(_categoryName, $"{_categoryName}[{eventId.Id}] - {state}");
                    else
                        _quickloggerInstance.Critical(_categoryName, exception, $"{_categoryName}[{eventId.Id}] - {state}");
                    break;
                case LogLevel.Debug:
                    if (exception == null)
                        _quickloggerInstance.Debug(_categoryName, $"{_categoryName}[{eventId.Id}] - {state}");
                    else
                        _quickloggerInstance.Debug(_categoryName, exception, $"{_categoryName}[{eventId.Id}] - {state}");
                    break;
                case LogLevel.Trace:
                    if (exception == null)
                        _quickloggerInstance.Trace(_categoryName, $"{_categoryName}[{eventId.Id}] - {state}");
                    else
                        _quickloggerInstance.Trace(_categoryName, exception, $"{_categoryName}[{eventId.Id}] - {state}");
                    break;
            }
        }
    }
}
