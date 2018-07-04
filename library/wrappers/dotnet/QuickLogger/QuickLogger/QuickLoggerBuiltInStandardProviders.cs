using QuickLogger.NetStandard.Abstractions;
using System;
using System.Collections.Generic;
using System.Text;

namespace QuickLogger.NetStandard
{
    public class QuickLoggerBuiltInStandardProviders
    {
        static public ILoggerProvider CreateStandardConsoleProvider()
        {
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Standard Console", "ConsoleProvider");
            providerProps.SetProviderInfo(new Dictionary<string, object>() { { "LogLevel", LoggerEventTypes.LOG_ALL }, { "ShowEventColors", true }, { "ShowTimeStamp", true } });            
            return new QuickLoggerProvider(providerProps);
        }
        static public ILoggerProvider CreateStandardFileProvider(string filePath)
        {
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("FileProvider", "Standard File");
            providerProps.SetProviderInfo(new Dictionary<string, object>() { { "LogLevel", LoggerEventTypes.LOG_ALL }, { "Filename", filePath }, { "DailyRotate", false }, { "ShowTimeStamp", true } });
            return new QuickLoggerProvider(providerProps);
        }
    }
}
