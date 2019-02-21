using QuickLogger.NetStandard;
using QuickLogger.NetStandard.Abstractions;
using System.Collections.Generic;

namespace QuickLogger.DefaultSettings.Generator
{
    class Program
    {
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
        static string _dbconfig = "{" +
                                "\"Provider\": \"dbMSSQL\"," +
                                "\"Server\": \"localhost\"," +
                                "\"Database\": \"Logger\"," +
                                "\"Table\": \"QuickLogger\"," +
                                "\"UserName\": \"myuser\"," +
                                "\"Password\": \"1234\"" +
                                "},";

        static string _dbfieldsmapping = "{" +
                                        "\"EventDate\": \"EventDate\"," +
                                        "\"EventType\": \"Level\"," +
                                        "\"Msg\": \"Msg\"," +
                                        "\"Environment\": \"Environment\"," +
                                        "\"PlatformInfo\": \"PlaftormInfo\"," +
                                        "\"OSVersion\": \"OSVersion\"," +
                                        "\"AppName\": \"AppName\"," +
                                        "\"UserName\": \"UserName\"," +
                                        "\"Host\": \"Host\"" +
                                        "},";


        static string _limits = "{" +
                                "\"TimeRange\": \"slNoLimit\"," +
                                "\"LimitEventTypes\": \"[]\"," +
                                "\"MaxSent\": 0" +
                                "},";

        static string _configName = "..\\..\\..\\..\\QuickLogger.DefaultSettings\\defaultSettings.json";

        static Dictionary<string, object> _consoleproviderinfo =
        new Dictionary<string, object>() {
        // Cool Console Log provider, events can be represented with colors and underlined.      
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "ShowTimeStamp", true }, { "ShowEventColors", true }, { "UnderlineHeaderEventType", false },
            { "TimePrecission", true }, { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }, { "AppName", "QuickLoggerDemo" }
        };
        // Standard File Log provider, can be rotated daily and compressed. 
        static Dictionary<string, object> _fileproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "Filename", ".\\test.log" }, { "AutoFileNameByProcess", false }, { "MaxRotateFiles", 3 },
            { "MaxFileSizeInMB", 10 }, { "RotatedFilesPath", "" }, { "DailyRotate", false }, { "CompressRotatedFiles", false }, { "ShowEventType", true },
            { "ShowHeaderInfo", true }, { "TimePrecission", true }, { "UnderlineHeaderEventType", false }, { "AutoFlush", false }, { "MaxFailsToRestart", 2 },
            { "MaxFailsToStop", 10 }
        };
        // SMTP Log provider, will send mails CAUTION : (Will spam if limits aren't defined!) 
        static Dictionary<string, object> _emailproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "SMTP", _smtpconfig }, { "Mail", _mailconfig }, { "SendLimits", _limits },
            { "TimePrecission", true }, { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };
        // Windows Event Log provider.
        static Dictionary<string, object> _windowseventlogproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "Source", "QuickLogger" }, { "DailyRotate", false }, { "ShowTimeStamp", true }, { "TimePrecission", true },
            { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };
        // HTTP POST RESTful client provider. Useful to send log events to a WEBAPI. 
        static Dictionary<string, object> _restproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "URL", "http:\\\\localhost\\event" }, { "UserAgent", "Quick.Logger Agent" },
            { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };
        // ELK Friendly redis TCP provider.
        static Dictionary<string, object> _redisproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "Host", "192.168.5.100" }, { "Port", 6379 }, { "Password", "1234"}, { "LogKey", "Log" },
            { "MaxSize", 1000}, { "OutputAsJson", true }, { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };
        // Telegram channel provider.
        static Dictionary<string, object> _telegramproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "ChannelName", "mychannelname" }, { "ChannelType", "tcPrivate" }, { "BotToken", "555555555:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" },
            { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };
        // Slack Provider.
        static Dictionary<string, object> _slackproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "ChannelName", "#myLogger" }, { "UserName", "mySlackUserName" }, { "WebHookURL",  "https:\\\\hooks.slack.com\\services\\TAAAAAAAA\\BBBBBBBBB\\CCCCCCCCCCCCCCCCCCCCCCCC" },
            { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };
        // ADO Provider.
        static Dictionary<string, object> _adoproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL }, { "ConnectionString", "Provider=SQLOLEDB.1;Persist Security Info=False;User ID=myuser;Password=1234;Database=Logger;Data Source=localhost" },
            { "DBConfig", _dbconfig }, { "FieldsMapping",  _dbfieldsmapping },
            { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };
        // SysLog server provider.
        static Dictionary<string, object> _syslogproviderinfo =
        new Dictionary<string, object>() {
            { "LogLevel", LoggerEventTypes.LOG_ALL },  { "Host", "127.0.0.1" }, { "Port", 514 }, { "Facility",  "sfUserLevel" },
            { "MaxFailsToRestart", 2 }, { "MaxFailsToStop", 10 }
        };

        static List<ILoggerProvider> _providers = new List<ILoggerProvider>() {
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default Console Provider", "ConsoleProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default File Provider", "FileProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default Redis Provider", "RedisProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default Telegram Provider", "TelegramProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default Slack Provider", "SlackProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default Rest Provider", "RestProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default Email Provider", "EmailProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default ADODB Provider", "AdoProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default WindowsEventLog Provider", "WindowsEventProvider")),
            new QuickLoggerProvider(new QuickLoggerProviderProps("Default SysLog Provider", "SyslogProvider"))};

        static void Main(string[] args)
        {
            ILoggerConfigManager configManager = new QuickLoggerFileConfigManager(_configName);
            ILoggerSettings settings = configManager.Load();      
            foreach (ILoggerProvider provider in _providers)
            {
                if (provider.getProviderProperties().GetProviderType() == "ConsoleProvider") { provider.getProviderProperties().SetProviderInfo(_consoleproviderinfo); }                
                else if (provider.getProviderProperties().GetProviderType() == "FileProvider") { provider.getProviderProperties().SetProviderInfo(_fileproviderinfo); }
                else if (provider.getProviderProperties().GetProviderType() == "RedisProvider") { provider.getProviderProperties().SetProviderInfo(_redisproviderinfo); }
                else if (provider.getProviderProperties().GetProviderType() == "SlackProvider") { provider.getProviderProperties().SetProviderInfo(_slackproviderinfo); }
                else if (provider.getProviderProperties().GetProviderType() == "RestProvider") { provider.getProviderProperties().SetProviderInfo(_restproviderinfo); }
                else if (provider.getProviderProperties().GetProviderType() == "EmailProvider") { provider.getProviderProperties().SetProviderInfo(_emailproviderinfo); }
                else if (provider.getProviderProperties().GetProviderType() == "AdoProvider") { provider.getProviderProperties().SetProviderInfo(_adoproviderinfo); }
                else if (provider.getProviderProperties().GetProviderType() == "WindowsEventProvider") { provider.getProviderProperties().SetProviderInfo(_windowseventlogproviderinfo); }
                else if (provider.getProviderProperties().GetProviderType() == "SyslogProvider") { provider.getProviderProperties().SetProviderInfo(_syslogproviderinfo); }
                settings.addProvider(provider);
            }
            configManager.Write();
        }
    }
}

