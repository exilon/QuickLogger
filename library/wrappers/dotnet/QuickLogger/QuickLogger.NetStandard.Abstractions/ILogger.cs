using System;

namespace QuickLogger.NetStandard.Abstractions
{
    public interface ILogger
    {
        void AddStandardConsoleProvider();
        void AddStandardFileProvider(string filename);
        void AddProvider(ILoggerProvider provider);               
        void RemoveProvider(ILoggerProvider provider);
        void RemoveProvider(string name);
        void EnableProvider(ILoggerProvider provider);        
        void EnableProvider(string name);
        void DisableProvider(ILoggerProvider provider);
        void DisableProvider(string name);
        string[] GetLoggerProviderTypes();
        string GetLoggerNameAndVersion();
        void Info(string message);
        void Success(string message);
        void Warning(string message);
        void Error(string message);
        void Error(Exception exception);
        void Trace(string message);
        void KPI(string name, string value);        
        void Custom(string message);
        void TestCallbacks();
        string GetLastError();
    }
}
