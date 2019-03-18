using System;
using System.IO;
using System.Collections.Generic;
using NUnit.Framework;
using System.Reflection;
using QuickLogger.NetStandard;
using QuickLogger.NetStandard.Abstractions;

namespace QuickLogger.Tests.Unit
{    
    [TestFixture(Category = "Unit")]    
    public class QuickLogger_Configuration_Should
    {
        static string _configPath = String.Empty;
        static string _configName = "config.json";
        static string _environmentName = "Test Env";
        static string _testprovidername = "A dirty File provider";
        static string _testprovidertype = "FileProvider";
        static Dictionary<string, object> _testproviderinfo = 
        new Dictionary<string, object>() {
            { "LogLevel", "LOG_DEBUG" }, { "Filename", ".\\test.log" }, { "DailyRotate", false }, { "ShowTimeStamp", true }
        };

        public ILoggerProvider GetaTestProvider(string providername)
        {
            ILoggerProviderProps providerProps = new QuickLoggerProviderProps(_testprovidername, _testprovidertype);
            providerProps.SetProviderInfo(_testproviderinfo);
            ILoggerProvider provider = new QuickLoggerProvider(providerProps);
            return provider;
        }

        public ILoggerConfigManager GetaTestFileConfigManager(string configpath)
        {
            ILoggerConfigManager configmanager = new QuickLoggerFileConfigManager(configpath);
            return configmanager;
        }
        public ILoggerConfigManager GetTestStringConfigManager()
        {
            var conf = "{  \"environment\": \"Test\",  \"providers\": [    {      \"providerProps\": {        \"providerName\": \"A dirty File provider\",        \"providerType\": \"RedisProvider\",        \"providerInfo\": {          \"AppName\": \"Habitatsoft.SignIn.API\",          \"LogLevel\": \"[etHeader,etInfo,etSuccess,etWarning,etError,etCritical,etException,etDebug,etTrace,etDone,etCustom1,etCustom2]\",          \"Host\": \"elksistemas.westeurope.cloudapp.azure.com\",          \"Port\": 6379,          \"Password\": \"\",	            \"LogKey\": \"sistemas-logstash-key\",          \"MaxSize\": 1000,                    \"MaxFailsToRestart\": 2,          \"MaxFailsToStop\": 0,         	        \"OutputAsJson\": true,	        \"Enable\": true        }      }    }  ]}";
            ILoggerConfigManager configmanager = new QuickLoggerStringConfigManager(conf);
            return configmanager;
        }

        [OneTimeSetUp]
        public void SetUp()
        {
            _configPath = Directory.GetParent(Assembly.GetAssembly(typeof(QuickLogger_Configuration_Should)).Location).Parent.Parent.FullName;
            _configPath += _configName;
            if (File.Exists(_configPath)) { File.Delete(_configPath); }
        }
        [Test]
        public void Create_new_configuration_manager()
        {
            ILoggerConfigManager configManager = new QuickLoggerFileConfigManager(_configPath);           
            Assert.That(configManager, !Is.Null);
        }
        [Test]
        public void Add_Logger_provider_into_a_new_configuration_manager()
        {
            ILoggerConfigManager configmanager = GetaTestFileConfigManager(_configPath);
            configmanager.GetSettings().addProvider(GetaTestProvider(_testprovidername));
            Assert.That(configmanager.GetSettings().getProvider(_testprovidername), !Is.Null);
        }
        [Test]
        public void Make_default_settings_and_save_to_disk()
        {
            ILoggerConfigManager configmanager = GetaTestFileConfigManager(_configPath);
            configmanager.Write();
            Assert.That(File.Exists(_configPath), Is.True);
        }
        [Test]
        public void Create_Save_And_Load_logger_configuration_from_disk()
        {
            ILoggerConfigManager configmanager = GetaTestFileConfigManager(_configPath);
            configmanager.GetSettings().addProvider(GetaTestProvider(_testprovidername));
            configmanager.GetSettings().setEnvironment("Test");
            configmanager.Write();
            Assert.That(File.Exists(_configPath), Is.True);
            Assert.That(configmanager.Reset().getEnvironment(), Is.Null);
            configmanager.Load();
            Assert.That(configmanager.GetSettings(), !Is.Null);
            Assert.That(configmanager.GetSettings().getEnvironment(), Is.EqualTo("Test"));
            Assert.That(configmanager.GetSettings().getProvider(_testprovidername), !Is.Null);
        }
        [Test]
        public void Create_logger_configuration_from_string()
        {
            ILoggerConfigManager configmanager = GetTestStringConfigManager();
            configmanager.Load();
            Assert.That(configmanager.GetSettings(), !Is.Null);
            Assert.That(configmanager.GetSettings().getEnvironment(), Is.EqualTo("Test"));
            Assert.That(configmanager.GetSettings().getProvider(_testprovidername), !Is.Null);
        }
        [TearDown]
        public void TearDown()
        {
            if (File.Exists(_configPath)) { File.Delete(_configPath); };
        }
    }
}
