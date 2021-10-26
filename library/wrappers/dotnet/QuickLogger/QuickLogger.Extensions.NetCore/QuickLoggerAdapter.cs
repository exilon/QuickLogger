using Microsoft.Extensions.Logging;
using QuickLogger.Extensions.Wrapper.Application.Services;
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
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

            var formatterType = formatter?.GetType().ToString();

            var isStandardFormatter = formatterType == "System.Func`3[Microsoft.Extensions.Logging.FormattedLogValues,System.Exception,System.String]";

            Func<TState, Exception, string> ourFormatter = (s, e) =>
            {
                var msg = s.ToString();

                var exceptionMsg = e != null
                    ? $" - [{e.GetType()}] : {e.Message} - StackTrace : {e.StackTrace}" : "";

                msg = $"{_categoryName}[{eventId.Id}] - {msg}{exceptionMsg}";
                return msg;
            };

            var overrideFormatter = isStandardFormatter ? ourFormatter : formatter ?? ourFormatter;

            //We don't care of standard formatter...
            var message = overrideFormatter(state, exception);

            switch (logLevel)
            {
                case LogLevel.Error:
                    _quickloggerInstance.Error(_categoryName, message);
                    break;
                case LogLevel.Warning:
                    _quickloggerInstance.Warning(_categoryName, message);
                    break;
                case LogLevel.Critical:
                    _quickloggerInstance.Critical(_categoryName, message);
                    break;
                case LogLevel.Debug:
                    _quickloggerInstance.Debug(_categoryName, message);
                    break;
                case LogLevel.Trace:
                    _quickloggerInstance.Trace(_categoryName, message);
                    break;
                default:
                    _quickloggerInstance.Info(_categoryName, message);
                    break;
            }
        }
    }
}
