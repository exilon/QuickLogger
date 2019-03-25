using System;
using System.Linq;
using System.Collections.Generic;
using QuickLogger.NetStandard.Abstractions;
using Newtonsoft.Json;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerSettings : ILoggerSettings  
    {
        private bool _handleUncatchedExceptions { get; set; }
        public bool handleUncatchedExceptions { get { return _handleUncatchedExceptions; } set { _handleUncatchedExceptions = value; } }
        public List<ILoggerProvider> providers { get; set; }

        public QuickLoggerSettings() => providers = new List<ILoggerProvider>();
              
        public List<ILoggerProvider> Providers()
        {
            return providers;
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
