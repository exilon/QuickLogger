using QuickLogger.NetStandard;
using QuickLogger.NetStandard.Abstractions;
using System;
using System.IO;

namespace QuickLogger.Sample
{
    class Program
    {
        private const string CONFIGPATH = "d:\\config.json";
        private const string FILELOGPATH = "d:\\logging.json";

        static void DeleteDemoFiles()
        {
            if (File.Exists(CONFIGPATH)) { File.Delete(CONFIGPATH); }
            if (File.Exists(FILELOGPATH)) { File.Delete(FILELOGPATH); }
        }
        static void AssignProviderCallbacks(ILoggerProvider provider)
        {
            provider.CriticalError += (x => System.Console.WriteLine(x));
            provider.Error += (x => {
                System.Console.WriteLine("Provider Error " + provider.getProviderProperties().GetProviderName() + " " + x);
                System.Console.ReadLine();
            });
            provider.QueueError += (x => System.Console.WriteLine("Provider Error " + provider.getProviderProperties().GetProviderName() + " " + x));
            provider.StatusChanged += (x => System.Console.WriteLine("Provider Error " + provider.getProviderProperties().GetProviderName() + " " + x));
            provider.QueueError += (x => System.Console.WriteLine("Provider Error " + provider.getProviderProperties().GetProviderName() + " " + x));
            provider.Started += (x => System.Console.WriteLine("Provider Error " + provider.getProviderProperties().GetProviderName() + " " + x));
        }
        static ILoggerProvider CreateFileDemoProvider(string logPath)
        {
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Dirty File Logger", "FileProvider");
            providerProps.SetProviderInfo(new System.Collections.Generic.Dictionary<string, object>()
            {
                { "LogLevel", LoggerEventTypes.LOG_ALL}, { "FileName", logPath }, { "AutoFileNameByProcess", true },
                { "DailyRotate", false }, { "ShowTimeStamp", true }
            });
            return new QuickLoggerProvider(providerProps);
        }

        static ILoggerProvider CreateConsoleDemoProvider()
        {
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Dirty Console Logger", "ConsoleProvider");

            providerProps.SetProviderInfo(new System.Collections.Generic.Dictionary<string, object>()
            {
                { "LogLevel", LoggerEventTypes.LOG_ONLYERRORS }, { "ShowEventColors", true }, { "ShowTimeStamp", true }
            });
            return new QuickLoggerProvider(providerProps);
        }
        static void Main(string[] args)
        {
            try
            {
                System.Console.ReadLine();
                System.Console.WriteLine(LoggerEventTypes.LOG_ALL.ToString());
                DeleteDemoFiles();
                ILoggerProvider myFileDemoProvider = CreateFileDemoProvider(FILELOGPATH);
                ILoggerProvider myConsoleDemoProvider = CreateConsoleDemoProvider();
                AssignProviderCallbacks(myFileDemoProvider);
                AssignProviderCallbacks(myConsoleDemoProvider);

                //Create new config instance, ADD Providers and Write to disk.
                ILoggerConfigManager configManager = new QuickLoggerFileConfigManager(CONFIGPATH);
                ILoggerSettings settings = configManager.Load();
                settings.addProvider(myFileDemoProvider);
                settings.addProvider(myConsoleDemoProvider);

                //Create a new instance of NativeQuickLogger
                ILogger logger = new QuickLoggerNative(configManager);

                logger.AddProvider(myFileDemoProvider);
                logger.AddProvider(myConsoleDemoProvider);

                // Main!
                logger.Info("QuickLogger demo program main loop started.");

                for (int x = 0; x < 100; x++)
                {
                    logger.Info("Info");
                    for (int y = 0; y < 100; y++)
                    {
                        logger.Error("Error");
                        for (int z = 0; z < 100; z++)
                        {
                            logger.Custom("Custom");
                        }
                    }
                }

                logger.Info("QuickLogger demo program finished.");
                System.Console.ReadKey();
            }
            catch (Exception ex)
            {
                System.Console.WriteLine(ex.Message);
            }
        }
    }
}
