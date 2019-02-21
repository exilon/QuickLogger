using System.IO;
using QuickLogger.NetStandard.Abstractions;
using Newtonsoft.Json;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerFileConfigManager : QuickConfigManager
    {        
        private readonly string _configurationFilePath;

        public QuickLoggerFileConfigManager(string configurationFilePath)
        {
            _configurationFilePath = configurationFilePath;
        }

        public override ILoggerSettings Load()
        {
            _settings = null;
            if (!File.Exists(_configurationFilePath)) throw new FileNotFoundException("[QuickLogger Exception] Config File not found");

            var jsonFile = File.ReadAllText(_configurationFilePath);

            _settings = (QuickLoggerSettings)JsonConvert.DeserializeObject(jsonFile, typeof(QuickLoggerSettings), JsonSerializerSettings);
            return _settings;
        }

        public override void Write()
        {
            if (_settings == null) { _settings = new QuickLoggerSettings(); }
            if (File.Exists(_configurationFilePath))
                File.Delete(_configurationFilePath);

            using (var sw = new StreamWriter(_configurationFilePath))
                sw.Write(JsonConvert.SerializeObject(_settings, JsonSerializerSettings));
        }
    }
}
