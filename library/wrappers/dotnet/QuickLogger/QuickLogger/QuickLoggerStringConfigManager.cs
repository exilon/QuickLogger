using Newtonsoft.Json;
using QuickLogger.NetStandard.Abstractions;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerStringConfigManager : QuickConfigManager
    {
        private string _config;
        public QuickLoggerStringConfigManager(string configLines)
        {
            _config = configLines;
        }

        public QuickLoggerStringConfigManager()
        {
            _settings = new QuickLoggerSettings();
        }

        public override ILoggerSettings Load()
        {
            _settings = null;           
            _settings = (QuickLoggerSettings)JsonConvert.DeserializeObject(_config, typeof(QuickLoggerSettings), JsonSerializerSettings);
            return _settings;
        }

        public override void Write()
        {
            if (_settings == null) { _settings = new QuickLoggerSettings(); }           
            _config = JsonConvert.SerializeObject(_settings, JsonSerializerSettings);
        }
    }
}
