using QuickLogger.NetStandard.Abstractions;
using QuickLogger.NetStandard;
using System;
using System.IO;

namespace QuickLogger.Sample
{
    class Program
    {
        private const string CONFIGPATH = ".\\config.json";
        private const string FILELOGPATH = ".\\logging.json";

        static void DeleteDemoFiles()
        {
            if (File.Exists(CONFIGPATH)) { File.Delete(CONFIGPATH); }
            if (File.Exists(FILELOGPATH)) { File.Delete(FILELOGPATH); }
        }
        static void AssignProviderCallbacks(ILoggerProvider provider)
        {
            provider.CriticalError += (x => Console.WriteLine(provider.getProviderProperties().GetProviderName() + " Provider Critical Error : " + x));
            provider.Error += (x => Console.WriteLine(provider.getProviderProperties().GetProviderName() + " Provider Error : " + x));
            provider.QueueError += (x => Console.WriteLine("Provider QueueError : " + x));
            provider.StatusChanged += (x => Console.WriteLine("Provider Status Changed : " + x));
            provider.FailToLog += Provider_FailToLog;  // Another way to define callback references
            provider.Started += (x => Console.WriteLine("Provider Started : " + x));
        }

        private static void Provider_FailToLog()
        {
            Console.WriteLine("Provider Fail to log");
        }

        static ILoggerProvider CreateFileDemoProvider(string logPath)
        {
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Dirty File Logger", "FileProvider");
            providerProps.SetProviderInfo(new System.Collections.Generic.Dictionary<string, object>()
            {
                { "LogLevel", LoggerEventTypes.LOG_ALL}, { "FileName", logPath }, { "AutoFileNameByProcess", "False" },
                { "DailyRotate", false }, { "ShowTimeStamp", true }
            });
            return new QuickLoggerProvider(providerProps);
        }

        static ILoggerProvider CreateConsoleDemoProvider()
        {
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Dirty Console Logger", "ConsoleProvider");

            providerProps.SetProviderInfo(new System.Collections.Generic.Dictionary<string, object>()
            {
                { "LogLevel", LoggerEventTypes.LOG_ALL }, { "ShowEventColors", true }, { "ShowTimeStamp", true }
            });
            return new QuickLoggerProvider(providerProps);
        }

        static void Main(string[] args)
        {
            ILogger logger = new QuickLoggerNative("");                
            try
            {
                System.Console.WriteLine(LoggerEventTypes.LOG_ALL.ToString());

                DeleteDemoFiles();

                ILoggerProvider myFileDemoProvider = CreateFileDemoProvider(FILELOGPATH);
                ILoggerProvider myConsoleDemoProvider = CreateConsoleDemoProvider();

                /* Optional config handler
                Create new config instance, ADD Providers and Write to disk.
                ILoggerConfigManager configManager = new QuickLoggerFileConfigManager(CONFIGPATH);
                if (File.Exists(CONFIGPATH)) { configManager.Load(); }
                else
                {
                    //Add providers to settings
                    configManager.GetSettings().addProvider(myFileDemoProvider);
                    configManager.GetSettings().addProvider(myConsoleDemoProvider);
                    //Write settings to disk
                    configManager.Write();
                }*/

                QuickLoggerSettings quickLoggerSettings = new QuickLoggerSettings();


                quickLoggerSettings.Providers().Add(myConsoleDemoProvider);
                quickLoggerSettings.Providers().Add(myFileDemoProvider);

                quickLoggerSettings.Providers().ForEach(x =>
                {
                    logger.AddProvider(x);
                    AssignProviderCallbacks(x);
                });

                System.Console.WriteLine(logger.GetLoggerNameAndVersion());
                logger.TestCallbacks();

                // Main!
                logger.Info("QuickLogger demo program main loop started.");

                for (int x = 1; x <= 100; x++)
                {
                    logger.Info("QuickLogger demo program main loop iteration. Nº " + x.ToString());
                }

                logger.Info("QuickLogger demo program finished.");
                System.Console.ReadKey();

                quickLoggerSettings.Providers().ForEach(x =>
                {
                    // We remove providers we created before (code sanity)
                    logger.DisableProvider(x);
                    logger.RemoveProvider(x);
                });
            }
            catch (Exception ex)
            {
                System.Console.WriteLine(ex.Message + " " + logger.GetLastError());
                System.Console.ReadKey();
            }
        }

        private static void MyFileDemoProvider_CriticalError(string msg)
        {
            Console.WriteLine(msg);
        }
    }
}
