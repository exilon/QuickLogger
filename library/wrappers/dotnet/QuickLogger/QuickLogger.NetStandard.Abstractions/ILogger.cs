using System;
using System.Collections.Generic;

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
        string GetCurrentProviders();
        string GetLoggerNameAndVersion();
        void Info(string message);
        void Success(string message);
        void Warning(string message);
        void Error(string message);
        void Exception(Exception exception);
        void Exception(string message, string exceptionType, string stackTrace);
        void Trace(string message);
        void Custom(string message);
        void Critical(string message);
        void Debug(string message);
        void TestCallbacks();
        string GetLastError();
        int GetQueueCount();
        bool IsQueueEmpty();
        void WaitSecondsForFlushBeforeExit(int seconds);
    }
}
