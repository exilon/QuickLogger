using System.Collections.Generic;

namespace QuickLogger.NetStandard.Abstractions
{
    public interface ILoggerSettings
    {
        void addProvider(ILoggerProvider provider);        
        List<ILoggerProvider> Providers();
        ILoggerProvider getProvider(string name);                     
    }
}
