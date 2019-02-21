using System;
using System.Linq;
using System.Collections.Generic;
using QuickLogger.NetStandard.Abstractions;
using Newtonsoft.Json;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerSettings : ILoggerSettings  
    {
        private string _environment { get; set; }
        private string _appName { get; set; }
        public string environment { get { return _environment; } set { _environment = value; } }
        public string appName { get; set; }
        public List<ILoggerProvider> providers { get; set; }

        public QuickLoggerSettings() => providers = new List<ILoggerProvider>();
               
        public string getEnvironment()
        {
            return _environment;
        }

        public List<ILoggerProvider> Providers()
        {
            return providers;
        }

        public void setEnvironment(string environment)
        {
            if (string.IsNullOrEmpty(environment)) { throw new Exception("Invalid environment name"); }
            _environment = environment;
        }

        public void addProvider(ILoggerProvider provider)
        {
            providers.Add(provider);
        }

        public ILoggerProvider getProvider(string name)
        {
            //Areglar
            return providers.Where(x => x.getProviderProperties().GetProviderName() == name).FirstOrDefault();
        }
    }
}
