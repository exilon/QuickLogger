using System.Collections.Generic;

namespace QuickLogger.NetStandard.Abstractions
{
    public interface ILoggerSettings
    {
        void setEnvironment(string environment);
        string getEnvironment();
        void addProvider(ILoggerProvider provider);        
        List<ILoggerProvider> Providers();
        ILoggerProvider getProvider(string name);                     
    }
}
