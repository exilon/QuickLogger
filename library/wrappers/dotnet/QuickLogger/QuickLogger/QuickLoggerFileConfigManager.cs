using System.IO;
using QuickLogger.NetStandard.Abstractions;
using Newtonsoft.Json;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerFileConfigManager : ILoggerConfigManager
    {        
        private readonly string _configurationFilePath;

        private ILoggerSettings _settings;

        private JsonSerializerSettings JsonSerializerSettings = new JsonSerializerSettings
        {
            ConstructorHandling = ConstructorHandling.AllowNonPublicDefaultConstructor,
            ReferenceLoopHandling = ReferenceLoopHandling.Ignore,               
        };

        public QuickLoggerFileConfigManager(string configurationFilePath)
        {
            _configurationFilePath = configurationFilePath;
            JsonSerializerSettings.Converters.Add(new ILoggerProviderTypeConverter());
            JsonSerializerSettings.Converters.Add(new ILoggerProviderPropsTypeConverter());
            JsonSerializerSettings.Converters.Add(new ILoggerLoggerTypeConverter());
            JsonSerializerSettings.Converters.Add(new ILoggerHashSetTypeConverter());
        }
        public ILoggerSettings Load()
        {
            _settings = null;
            if (!File.Exists(_configurationFilePath))
            {
                _settings = new QuickLoggerSettings();
                return _settings;
            }
                
            var jsonFile = File.ReadAllText(_configurationFilePath);

            _settings = (QuickLoggerSettings)JsonConvert.DeserializeObject(jsonFile, typeof(QuickLoggerSettings), JsonSerializerSettings);
            return _settings;
        }

        public void Write()
        {
            if (_settings == null) { _settings = new QuickLoggerSettings(); }
            if (File.Exists(_configurationFilePath))
                File.Delete(_configurationFilePath);

            using (var sw = new StreamWriter(_configurationFilePath))
                sw.Write(JsonConvert.SerializeObject(_settings, JsonSerializerSettings));
        }

        public ILoggerSettings Reset()
        {
            _settings = null;
            return _settings; 
        }
    }
}
