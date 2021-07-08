using Newtonsoft.Json;
using QuickLogger.NetStandard.Abstractions;

namespace QuickLogger.NetStandard
{
    public abstract class QuickConfigManager : ILoggerConfigManager
    {
        protected ILoggerSettings _settings;

        protected JsonSerializerSettings JsonSerializerSettings = new JsonSerializerSettings
        {
            ConstructorHandling = ConstructorHandling.AllowNonPublicDefaultConstructor,
            Formatting = Formatting.Indented,
            ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
        };

        protected QuickConfigManager()
        {
            JsonSerializerSettings.Converters.Add(new LoggerProviderTypeConverter());
            JsonSerializerSettings.Converters.Add(new LoggerProviderPropsTypeConverter());
            JsonSerializerSettings.Converters.Add(new LoggerLoggerTypeConverter());
            JsonSerializerSettings.Converters.Add(new LoggerHashSetTypeConverter());
        }

        public ILoggerSettings GetSettings()
        {
            return _settings ?? (_settings = new QuickLoggerSettings());
        }

        public abstract ILoggerSettings Load();

        public ILoggerSettings Reset()
        {
            _settings = null;
            return (_settings = new QuickLoggerSettings());
        }       

        public abstract void Write();
    }
}
