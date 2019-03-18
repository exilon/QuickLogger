using NUnit.Framework;
using QuickLogger.NetStandard;
using QuickLogger.NetStandard.Abstractions;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

namespace QuickLogger.Tests.Integration
{
    [TestFixture(Category = "Integration")]
    public class QuickLogger_Integration_Should
    {
        private static ILoggerConfigManager _configManager;
        private static ILoggerProviderProps _providerProps;
        private static string _configPath = String.Empty;
        private static string _fileloggerName = "testfilelog.log";
        private static string _fileloggerPath = "";
        private static string _configName = "qloggerconfig.json";
        private static string _environmentName = "Test Env";

        static string _smtpconfig = "{" +
                                    "\"Host\": \"mail.domain.com\"," +
                                    "\"UserName\": \"email@domain.com\"," +
                                    "\"Password\": \"jfs93as\"," +
                                    "\"UseSSL\": false" +
                                    "}";
        static string _mailconfig = "{" +
                                    "\"SenderName\": \"Quick.Logger Alert\"," +
                                    "\"From\": \"email@domain.com\"," +
                                    "\"Recipient\": \"alert@domain.com\"," +
                                    "\"Subject\": \"\"," +
                                    "\"Body\": \"\"," +
                                    "\"CC\": \"myemail@domain.com\"," +
                                    "\"BCC\": \"\"" +
                                    "}";

        static Dictionary<string, object> _consoleProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL},
            { "ShowTimeStamp", true }, { "ShowEventColors", true }
        };
        static Dictionary<string, object> _fileProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL}, { "AutoFileNameByProcess", false },
            { "DailyRotate", false }, { "ShowTimeStamp", true }, { "Enabled", false }
        };
        static Dictionary<string, object> _smtpProviderInfo = new Dictionary<string, object>()
        {
            { "LogLevel", LoggerEventTypes.LOG_ALL}, { "UnderlineHeaderEventType", true },
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
            using (StreamReader sr = new StreamReader(File.Open(fileName, FileMode.Open, FileAccess.Read)))
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
            _configPath = Directory.GetParent(Assembly.GetAssembly(typeof(QuickLogger_Integration_Should)).Location).Parent.Parent.FullName;
            _fileloggerPath = Path.Combine(_configPath, _fileloggerName);
            _configPath = Path.Combine(_configPath, _configName);            
            if (File.Exists(_configPath)) { File.Delete(_configPath); }
            if (File.Exists(_fileloggerPath)) { File.Delete(_fileloggerPath); }
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
            ILogger logger = new QuickLoggerNative(".\\");
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test Console Provider", "ConsoleProvider");
            providerProps.SetProviderInfo(_consoleProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);            
            logger.Info("Works");
            logger.Custom("Works");
            logger.Error("Works");
            logger.Success("Works");
            //Assert that words are shown on the console 
            logger.RemoveProvider(loggerProvider);
        }
        [Test]
        public void Add_Logger_Default_Console_Provider_To_New_Logger_Write_5_Lines_And_DisableIT()
        {
            ILogger logger = new QuickLoggerNative(".\\");
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test Console Provider", "ConsoleProvider");
            providerProps.SetProviderInfo(_consoleProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);            
            logger.AddProvider(loggerProvider);
            var currentstatus = "";
            loggerProvider.StatusChanged += (x => currentstatus = x); 
            
            for (var x = 0; x < 5; x++)
            {
                logger.Info("Works");
                logger.Custom("Works");
                logger.Error("Works");
                logger.Success("Works");
            }
            //Assert that words are shown on the console 
            logger.DisableProvider(loggerProvider);            
            for (var x = 0; x < 5; x++)
            {
                logger.Info("Works");
                logger.Custom("Works");
                logger.Error("Works");
                logger.Success("Works");
            }
            //Assert that words are not shown on the console 
            logger.RemoveProvider(loggerProvider);
        }

        [Test]
        public void Add_Logger_Default_File_Provider_To_New_Logger()
        {
            ILogger logger = new QuickLoggerNative(".\\");
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test File Provider", "FileProvider");
            _fileProviderInfo.Add("FileName", _fileloggerPath);
            providerProps.SetProviderInfo(_fileProviderInfo);            
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);            
            logger.Info("Info line");
            logger.Custom("Custom line");
            logger.Error("Error line");
            logger.Success("Success line");
            logger.RemoveProvider(loggerProvider);
            Assert.That(FindStringInsideFile(_fileloggerPath, "Info line"), Is.True);
            Assert.That(FindStringInsideFile(_fileloggerPath, "Custom line"), Is.True);
            Assert.That(FindStringInsideFile(_fileloggerPath, "Error line"), Is.True);
            Assert.That(FindStringInsideFile(_fileloggerPath, "Success line"), Is.True);            
        }

        [Test]
        public void Init_Logger_And_Get_Logger_Version()
        {        
            ILogger logger = new QuickLoggerNative(".\\");
            var loggerversion = logger.GetLoggerNameAndVersion();
            Assert.That(loggerversion != "", Is.True);            
        }


        [Test]
        public void Add_Logger_Default_SMTP_Provider_To_New_Logger()
        {
            ILogger logger = new QuickLoggerNative(".\\");
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test SMTP Provider", "SMTPProvider");
            providerProps.SetProviderInfo(_fileProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);
            logger.Info("Info line");
            logger.Custom("Custom line");
            logger.Error("Error line");
            logger.Success("Success line");
            //Assert that words are received by name 
            logger.RemoveProvider(loggerProvider);
        }
        [Test]
        public void Add_Logger_Default_Redis_Provider_To_New_Logger()
        {
            ILogger logger = new QuickLoggerNative(".\\");
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps("Test Redis (ELK) Provider", "RedisProvider");
            providerProps.SetProviderInfo(_fileProviderInfo);
            ILoggerProvider loggerProvider = new QuickLoggerProvider(providerProps);
            logger.AddProvider(loggerProvider);
            logger.Info("Info line");
            logger.Custom("Custom line");
            logger.Error("Error line");
            logger.Success("Succes line");
            Assert.That(FindStringInsideFile(_configPath, "Info line"), Is.True);
            Assert.That(FindStringInsideFile(_configPath, "Custom line"), Is.True);
            Assert.That(FindStringInsideFile(_configPath, "Error line"), Is.True);
            Assert.That(FindStringInsideFile(_configPath, "Success line"), Is.True);
            //Assert that words are received by name 
            logger.RemoveProvider(loggerProvider);
        }
    }
}
