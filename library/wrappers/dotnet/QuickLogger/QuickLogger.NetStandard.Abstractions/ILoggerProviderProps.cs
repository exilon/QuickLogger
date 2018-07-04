using System;
using System.Collections.Generic;
using System.Text;

namespace QuickLogger.NetStandard.Abstractions
{
    public interface ILoggerProviderProps
    {
        string GetProviderName();
        void SetProviderName(string providerName);
        string GetProviderType();
        void SetProviderType(string providerType);
        string ToJSON();
        Dictionary<string, object> GetProviderInfo();
        void SetProviderInfo(Dictionary<string, object> providerInfo);
    }
}
