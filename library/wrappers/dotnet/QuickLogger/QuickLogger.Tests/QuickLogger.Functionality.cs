using NUnit.Framework;
using QuickLogger.NetStandard;
using QuickLogger.NetStandard.Abstractions;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

namespace QuickLogger.Tests.Unit
{
    [TestFixture(Category = "Integration")]
    public class QuickLogger_Functionality_Should
    {
        private static ILoggerConfigManager _configManager;
        private static ILoggerProviderProps _providerProps;
        private static string _configPath = String.Empty;
        private static string _fileloggerName = "\\testfilelog.log";
        private static string _fileloggerPath = "";
        private static string _configName = "\\qloggerconfig.json";
        private static string _environmentName = "Test Env";
        static Dictionary<string, object> _consoleProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL},
            { "ShowTimeStamp", true }, { "ShowEventColors", true }
        };
        static Dictionary<string, object> _fileProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL}, { "FileName", _fileloggerPath },
            { "DailyRotate", false }, { "ShowTimeStamp", true }
        };
        static Dictionary<string, object> _smtpProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL}, { "UnderlineHeaderEventType", true } ,
            { "DailyRotate", false }, { "ShowTimeStamp", true }, { "ShowEventColors", true }
        };
        static Dictionary<string, object> _eventsProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL}, { "UnderlineHeaderEventType", true } ,
            { "DailyRotate", false }, { "ShowTimeStamp", true }, { "ShowEventColors", true }
        };
        static Dictionary<string, object> _redisProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL}, {"Host", "192.168.1.133" }, {"Port", "6379" },
            { "OutputAsJson", true }
        };

        private void DeleteFile(string fileName)
        {
            if (File.Exists(fileName)) { File.Delete(fileName); };
        }
        private Boolean FindStringInsideFile(string fileName, string line)
        {
            using (StreamReader sr = new StreamReader(File.Open(fileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)))
            {
                while (!sr.EndOfStream)
                {
                    if (sr.ReadLine().Contains(line)) { return true; }
                }
                return false;
            }        
        }

        [OneTimeSetUp]
        public void SetUp()
        {
            _configPath = Directory.GetParent(Assembly.GetAssembly(typeof(QuickLogger_Configuration_Should)).Location).Parent.Parent.FullName;
            _configPath += _configName;
            _fileloggerPath = _configPath;
            _fileloggerPath += _fileloggerName;
            if (File.Exists(_configPath)) { File.Delete(_configPath); }
            _configManager = new QuickLoggerFileConfigManager(_configPath);
        }

        [TearDown]
        public void TearDown()
        {
            DeleteFile(_configName);
            DeleteFile(_fileloggerPath);
        }

        [Test]
        public void Add_Logger_Default_Console_Provider_To_New_Logger()
        {
            ILogger logger = new QuickLoggerNative(_configManager);
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test Console Provider", "ConsoleProvider");
            providerProps.SetProviderInfo(_consoleProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);            
            logger.Info("Works");
            logger.Custom("Works");
            logger.Error("Works");
            logger.RemoveProvider(loggerProvider);
        }

        [Test]
        public void Add_Logger_Default_File_Provider_To_New_Logger()
        {
            ILogger logger = new QuickLoggerNative(_configManager);
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test File Provider", "FileProvider");
            providerProps.SetProviderInfo(_fileProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);            
            logger.Info("Info line");
            logger.Custom("Custom line");
            logger.Error("Error line");
            Assert.That(FindStringInsideFile(_fileloggerPath, "Info line"), Is.True);
            Assert.That(FindStringInsideFile(_fileloggerPath, "Custom line"), Is.True);
            Assert.That(FindStringInsideFile(_fileloggerPath, "Error line"), Is.True);
            logger.RemoveProvider(loggerProvider);
        }

        [Test]
        public void Add_Logger_Default_SMTP_Provider_To_New_Logger()
        {
            ILogger logger = new QuickLoggerNative(_configManager);
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test File Provider", "SMTPProvider");
            providerProps.SetProviderInfo(_fileProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);
            logger.Info("Info line");
            logger.Custom("Custom line");
            logger.Error("Error line");
            Assert.That(FindStringInsideFile(_configPath, "Info line"), Is.True);
            Assert.That(FindStringInsideFile(_configPath, "Custom line"), Is.True);
            Assert.That(FindStringInsideFile(_configPath, "Error line"), Is.True);
            logger.RemoveProvider(loggerProvider);
        }
        [Test]
        public void Add_Logger_Default_Redis_Provider_To_New_Logger()
        {
            ILogger logger = new QuickLoggerNative(_configManager);
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test Redis (ELK) Provider", "RedisProvider");
            providerProps.SetProviderInfo(_fileProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);
            logger.Info("Info line");
            logger.Custom("Custom line");
            logger.Error("Error line");
            Assert.That(FindStringInsideFile(_configPath, "Info line"), Is.True);
            Assert.That(FindStringInsideFile(_configPath, "Custom line"), Is.True);
            Assert.That(FindStringInsideFile(_configPath, "Error line"), Is.True);
            logger.RemoveProvider(loggerProvider);
        }
    }
}
