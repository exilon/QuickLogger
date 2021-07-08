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
            if (!(state is IDictionary<string, object>))
                return new Scope<TState>(state);

            try
            {
                return Scope<TState>.CreateScope(state);
            }
            catch (Exception e)
            {
                return new Scope<TState>(state);
            }
        }

        public bool IsEnabled(LogLevel logLevel)
        {
            return true;
        }

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception exception, Func<TState, Exception, string> formatter)
        {
            if (!IsEnabled(logLevel))
            {
                return;
            }

            string message = formatter != null ? formatter(state, exception) : state.ToString();

            if (string.IsNullOrWhiteSpace(message) && exception != null)
                message = exception.Message;

            switch (logLevel)
            {
                case LogLevel.Error:
                    _quickloggerInstance.Error(_categoryName, $"{_categoryName}[{eventId.Id}] - {message}");
                    break;
                case LogLevel.Warning:
                    _quickloggerInstance.Warning(_categoryName, $"{_categoryName}[{eventId.Id}] - {message}");
                    break;
                case LogLevel.Critical:
                    _quickloggerInstance.Critical(_categoryName, $"{_categoryName}[{eventId.Id}] - {message}");
                    break;
                case LogLevel.Debug:
                    _quickloggerInstance.Debug(_categoryName, $"{_categoryName}[{eventId.Id}] - {message}");
                    break;
                case LogLevel.Trace:
                    _quickloggerInstance.Trace(_categoryName, $"{_categoryName}[{eventId.Id}] - {message}");
                    break;
                default:
                    _quickloggerInstance.Info(_categoryName, $"{_categoryName}[{eventId.Id}] - {message}");
                    break;
            }
        }
    }
}
