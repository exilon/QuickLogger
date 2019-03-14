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
            provider.CriticalError += (x => Console.WriteLine("Provider Critical Error : " + x));
            provider.Error += (x => Console.WriteLine("Provider Error : " + x));
            provider.QueueError += (x => Console.WriteLine("Provider QueueError : " + x));
            provider.StatusChanged += (x => Console.WriteLine("Provider Status Changed : " + x));
            provider.FailToLog += Provider_FailToLog;
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

                { "LogLevel", LoggerEventTypes.LOG_ALL}, { "FileName", logPath }, { "AutoFileNameByProcess", false },
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
            ILogger logger = new QuickLoggerNative(".\\");
            try
            {
                System.Console.WriteLine(LoggerEventTypes.LOG_ALL.ToString());
                
                DeleteDemoFiles();

                ILoggerProvider myFileDemoProvider = CreateFileDemoProvider(FILELOGPATH);
                ILoggerProvider myConsoleDemoProvider = CreateConsoleDemoProvider();
                AssignProviderCallbacks(myFileDemoProvider);
                AssignProviderCallbacks(myConsoleDemoProvider);                

                //Create new config instance, ADD Providers and Write to disk.
                ILoggerConfigManager configManager = new QuickLoggerFileConfigManager(CONFIGPATH);
                if (File.Exists(CONFIGPATH)) { configManager.Load(); }   
                else
                {
                    //Add providers to settings
                    configManager.GetSettings().addProvider(myFileDemoProvider);
                    configManager.GetSettings().addProvider(myConsoleDemoProvider);
                    //Write settings to disk
                    configManager.Write();
                }
                
                //Create a new instance of NativeQuickLogger                
                configManager.GetSettings().Providers().ForEach(x => logger.AddProvider(x));                

                System.Console.WriteLine(logger.GetLoggerNameAndVersion());

                logger.TestCallbacks();

                System.Console.WriteLine(logger.GetLoggerNameAndVersion());
                logger.TestCallbacks();                

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
                throw new Exception("Uncontrolled exception");
                System.Console.ReadKey();
            }
            catch (Exception ex)
            {
                //Quick Logger will catch uncontrolled exceptions.
                throw new Exception("Uncontrolled exception");
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
