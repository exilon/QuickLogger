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
            JsonSerializerSettings.Converters.Add(new ILoggerProviderTypeConverter());
            JsonSerializerSettings.Converters.Add(new ILoggerProviderPropsTypeConverter());
            JsonSerializerSettings.Converters.Add(new ILoggerLoggerTypeConverter());
            JsonSerializerSettings.Converters.Add(new ILoggerHashSetTypeConverter());
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
