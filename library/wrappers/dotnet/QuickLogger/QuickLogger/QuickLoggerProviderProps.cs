using QuickLogger.NetStandard.Abstractions;
using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using System.Text;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerProviderProps : ILoggerProviderProps
    {
        private JsonSerializerSettings JsonSerializerSettings = new JsonSerializerSettings
        {
            ConstructorHandling = ConstructorHandling.AllowNonPublicDefaultConstructor,
            ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
        };

        private string _providerName { get; set; }
        public string providerName { get { return _providerName; } }
        private string _providerType { get; set; }
        public string providerType { get { return this._providerType; }  }
        private Dictionary<string, object> _providerInfo { get; set; }
        public Dictionary<string, object> providerInfo { get { return _providerInfo; } set { _providerInfo = value; } }



        public QuickLoggerProviderProps(string providerName, string providerType)
        {
            SetProviderName(providerName);
            SetProviderType(providerType);            
            JsonSerializerSettings.Converters.Add(new LoggerHashSetTypeConverter());
            _providerInfo = new Dictionary<string, object>();
        }
        public Dictionary<string, object> GetProviderInfo()
        {
            return _providerInfo;
        }

        public string GetProviderName()
        {
            return _providerName;
        }
        public void SetProviderName(string providerName)
        {
            if (string.IsNullOrEmpty(providerName)) { throw new Exception("Invalid provider name"); }
            _providerName = providerName;
        }

        public void SetProviderInfo(Dictionary<string, object> providerInfo)
        {           
            _providerInfo = providerInfo;
        }

        public string GetProviderType()
        {
            return _providerType;
        }

        public void SetProviderType(string providerType)
        {
            if (string.IsNullOrEmpty(providerName)) { throw new Exception("Invalid provider type, call getProviders() to get valid providers"); }
            _providerType = providerType;
        }

        public string ToJSON()
        {
            return JsonConvert.SerializeObject(this, JsonSerializerSettings);
        }
    }
}
