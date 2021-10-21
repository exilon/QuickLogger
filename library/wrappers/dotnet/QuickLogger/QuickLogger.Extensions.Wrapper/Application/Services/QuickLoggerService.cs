using Newtonsoft.Json;
using QuickLogger.Extensions.Wrapper.Domain;
using QuickLogger.NetStandard;
using QuickLogger.NetStandard.Abstractions;
using System;
using System.IO;
using System.Reflection;

namespace QuickLogger.Extensions.Wrapper.Application.Services
{
    public class QuickLoggerService : ILoggerService
    {
        private static string currentPath => AppDomain.CurrentDomain != null ?
        Path.Combine(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "bin")) :
        Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

        private ILoggerConfigManager _configManager;
        private ILoggerSettings _settings;
        private readonly IScopeInfoProviderService _additionalLoggerInfoProvider;

        private readonly ILoggerSettingsPathFinder _loggerSettingsPathFinder;
        private readonly ILogger _quicklogger;

        protected JsonSerializerSettings JsonSerializerSettings = new JsonSerializerSettings
        {
            ConstructorHandling = ConstructorHandling.AllowNonPublicDefaultConstructor,
            Formatting = Formatting.Indented,

            ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
        };

        private void InitMessage()
        {
            _quicklogger?.Success("QuickLogger loaded -> version " + _quicklogger?.GetLoggerNameAndVersion());
            _settings.Providers().ForEach(x => _quicklogger?.Info(x.getProviderProperties().GetProviderName() + " Provider Initalized."));
        }

        private ILoggerSettings LoadConfigFromDisk()
        {
            var quickloggerconfigpath = _loggerSettingsPathFinder.GetSettingsPath();
            if (!Path.IsPathRooted(quickloggerconfigpath)) { quickloggerconfigpath = Path.Combine(currentPath, "..", quickloggerconfigpath); }
            _configManager = new QuickLoggerFileConfigManager(quickloggerconfigpath);
            return _configManager.Load();
        }
        private QuickLoggerService()
        {
            var loaderpath = currentPath;
            if (!Directory.Exists(loaderpath)) { loaderpath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location); }
            _quicklogger = new QuickLoggerNative(loaderpath, true);
        }
        ~QuickLoggerService()
        {
            foreach (var provider in _settings.Providers())
            {
                try
                {
                    _quicklogger?.Info(provider.getProviderProperties().GetProviderName() + " Provider is going to be disabled.");
                    _quicklogger?.DisableProvider(provider);
                    _quicklogger?.RemoveProvider(provider);
                }
                catch (Exception ex)
                {
                    //TODO : Turrican -> Do something with this! Case provider cannot be disabled removed...
                }
            }
        }
        public QuickLoggerService(ILoggerSettingsPathFinder loggerSettingsPathFinder, IScopeInfoProviderService scopeInfoProvider = null) : this()
        {

            _loggerSettingsPathFinder = loggerSettingsPathFinder;
            _additionalLoggerInfoProvider = scopeInfoProvider;
            _settings = LoadConfigFromDisk();
            foreach (var provider in _settings.Providers())
            {
                try
                {
                    var providername = String.Format("[Name : {0}] - [PID : {1}] - [GUID : {2}]", provider.getProviderProperties().GetProviderName(),
                        System.Diagnostics.Process.GetCurrentProcess().Id, Guid.NewGuid().ToString());
                    provider.getProviderProperties().SetProviderName(providername);
                    _quicklogger?.AddProvider(provider);
                }
                catch (Exception ex)
                {
                    //TODO : Turrican -> Do something with this! Case provider cannot be added...
                }
            }
            InitMessage();
        }
        public QuickLoggerService(string setttingsAsJson) : this()
        {
            _configManager = new QuickLoggerStringConfigManager(setttingsAsJson);
            _settings = _configManager.Load();
            foreach (var provider in _settings.Providers())
            {
                _quicklogger?.AddProvider(provider);
            }
            InitMessage();
        }

        private string BuildJSONSerializedMessage(string className, string msg)
        {
            object scopeinfo = _additionalLoggerInfoProvider?.GetScopeInfo();
            CustomLogMessage custommessage =
                new CustomLogMessage(className, msg, scopeinfo);
            return JsonConvert.SerializeObject(custommessage, JsonSerializerSettings);
        }

        private string BuildJSONSerializedException(string className, Exception exception, string msg)
        {
            object scopeinfo = _additionalLoggerInfoProvider?.GetScopeInfo();
            CustomExceptionWithHTTPRequestInfo customException =
                new CustomExceptionWithHTTPRequestInfo(className, exception, msg, scopeinfo);
            return JsonConvert.SerializeObject(customException, JsonSerializerSettings);
        }

        public void Error(string className, string msg)
        {
            string custommessage = BuildJSONSerializedMessage(className, msg);
            _quicklogger?.Error(custommessage);
        }
        public void Info(string className, string msg)
        {
            string custommessage = BuildJSONSerializedMessage(className, msg);
            _quicklogger?.Info(custommessage);
        }
        public void Warning(string className, string msg)
        {
            string custommessage = BuildJSONSerializedMessage(className, msg);
            _quicklogger?.Warning(custommessage);
        }
        public void Success(string className, string msg)
        {
            string custommessage = BuildJSONSerializedMessage(className, msg);
            _quicklogger?.Success(custommessage);
        }
        public void Trace(string className, string msg)
        {
            string custommessage = BuildJSONSerializedMessage(className, msg);
            _quicklogger?.Trace(custommessage);
        }
        public void Debug(string className, string msg)
        {
            string custommessage = BuildJSONSerializedMessage(className, msg);
            _quicklogger?.Debug(custommessage);
        }
        public bool IsQueueEmpty()
        {
            return _quicklogger.IsQueueEmpty();
        }
        public void Critical(string className, string msg)
        {
            string custommessage = BuildJSONSerializedMessage(className, msg);
            _quicklogger?.Critical(custommessage);
        }
        public void Exception(Exception exception)
        {
            _quicklogger?.Exception(exception);
        }
        public void Exception(Exception exception, string msg)
        {
            string custommessage = BuildJSONSerializedException("", exception, msg);
            _quicklogger?.Exception(custommessage, exception.GetType().ToString(),
                exception.StackTrace);
        }

        public void MultiException(AggregateException aggregateException)
        {
            foreach (Exception exception in aggregateException.InnerExceptions)
            {
                _quicklogger?.Exception(exception);
            }
        }

        public void Info(string className, Exception exception, string msg)
        {
            string custommessage = BuildJSONSerializedException(className, exception, msg);
            _quicklogger?.Info(custommessage);
        }

        public void Warning(string className, Exception exception, string msg)
        {
            string custommessage = BuildJSONSerializedException(className, exception, msg);
            _quicklogger?.Warning(custommessage);
        }

        public void Error(string className, Exception exception, string msg)
        {
            string custommessage = BuildJSONSerializedException(className, exception, msg);
            _quicklogger?.Error(custommessage);
        }

        public void Trace(string className, Exception exception, string msg)
        {
            string custommessage = BuildJSONSerializedException(className, exception, msg);
            _quicklogger?.Trace(custommessage);
        }

        public void Critical(string className, Exception exception, string msg)
        {
            string custommessage = BuildJSONSerializedException(className, exception, msg);
            _quicklogger?.Critical(custommessage);
        }

        public void Debug(string className, Exception exception, string msg)
        {
            string custommessage = BuildJSONSerializedException(className, exception, msg);
            _quicklogger?.Debug(custommessage);
        }
    }
}

