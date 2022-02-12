![alt text](docs/QuickLogger.png "QuickLogger") 

Delphi(Delphi XE6 - Delphi 11 Alexandria)/Freepascal(trunk)/.NET (Windows/Linux/Android/MACOSX/IOS) library for logging on multi providers:
- Files
- Console
- Memory
- Email
- Rest server
- Windows EventLog
- Redis server
- IDE debug
- Throw events
- Telegram
- Slack
- MSSQL, MSAcces, etc with ADODB.
- SysLog
- Logstash
- ElasticSearch
- InfluxDB
- GrayLog
- Controlled and unhandled exceptions hook
- Sentry
- Twilio

## Give it a star
Please "star" this project in GitHub! It costs nothing but helps to reference the code.
![alt text](docs/githubstartme.jpg "Give it a star")

## Support
If you find this project useful, please consider making a donation.

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=BKLKPNEYKSBKL)

### Updates:

**Nov 22,2021** RAD Studio 11 supported

**May 30,2020:** RAD Studio 10.4 supported

**May 02,2020:** Twilio provider

**Apr 25,2020:** Custom Output Format & custom Tags support

**Apr 24,2020:** Sentry provider

**Sep 14,2019:** New optional Included log info: ThreadId.

**Sep 11,2019:** Now included on RAD Studio GetIt package manager.

**Mar 28,2019:** Unhandled exceptions hook

**Mar 28,2019:** Improved exception info

**Mar 16,2019:** GrayLog provider

**Feb 28,2019:** InfluxDB provider

**Feb 26,2019:** ElasticSearch provider

**Feb 25,2019:** Logstash provider

**Feb 19,2019:** Delphi Linux compatilibity.

**Feb 10,2019:** Firemonkey OSX & IOS compatibility.

**Dec 08,2018:** Load/Save providers config from single json

**Dec 07,2018:** Delphi 10.3 Rio support

**Sep 11,2018:** Firemonkey android compatibility improved

**Jul 04,2018:** Native dll and .Net warpper (thanks to Turrican)

**Jun 29,2018:** Config from/to Json

**Jun 15,2018:** SysLog provider.

**May 28,2018:** Slack provider.

**May 27,2018:** ADODB provider.

**May 27,2018:** Telegram provider.

**May 25,2018:** Custom output Msg.

**May 22,2018:** ELK support.

**May 20,2018:** Delphinus support.

**May 20,2018:** Json output with optional fields for Redis and Rest providers.

**May 17,2018:** FreePascal Linux compatibility.

**May 02,2018:** FreePascal Windows compatibility.

**Installation:**
----------
* **From package managers:**
1. Search "QuickLogger" on Delphinus or GetIt package managers and click *Install*
* **From Github:**
1. Clone this Github repository or download zip file and extract it.
2. Add QuickLogger folder to your path libraries on Delphi IDE.
3. Clone QuickLib Github repository https://github.com/exilon/QuickLib or download zip file and extract it.
4. Add QuickLib folder to your path libraries on Delphi IDE.

**Documentation:**
----------
Quick Logger is asynchronous. All logs are sent to a queue and don't compromises your application flow. You can define many providers to sent every log entry and decide what level accepts every one.

```delphi
program
{$APPTYPE CONSOLE}
uses
    Quick.Logger:
    Quick.Logger.Provider.Files;
    Quick.Logger.Provider.Console;
begin
    //Add Log File and console providers
    Logger.Providers.Add(GlobalLogFileProvider);
    Logger.Providers.Add(GlobalLogConsoleProvider);
    //Configure provider options
    with GlobalLogFileProvider do
 	begin
    	FileName := '.\Logger.log';
        DailyRotate := True;
        MaxFileSizeInMB := 20;
        LogLevel := LOG_ALL;
    	Enabled := True;
  	end;
    with GlobalLogConsoleProvider do
    begin
    	LogLevel := LOG_DEBUG;
        ShowEventColors := True;
        Enabled := True;
    end;
    Log('Test entry',etInfo);
    Log('Test number: %d',[1],etWarning);
end.
```

## Logger:
QuickLogger manages Logger and Providers automatically. Logger and providers have a global class, auto created and released on close your app. You only need to add wanted providers to your uses clause. 
> Note: You need to add almost one provider to send logging.

	Properties:
	
	- **Providers:** List of providers to send logs.
	- **OnProviderError:** Event to receive provider error notifications.
	- **RedirectOwnErrorsToProvider:** Select provider to get all provider notification errors.
	- **WaitForFlushBeforeExit:** Number of seconds logger allowed to flush queue before closed.
	- **QueueCount:** Queued items in main queue.
	- **ProvidersQueueCount:** Queued items in providers queue (all providers).
	- **OnQueueError:** Event for receive queue errors.
	- **IsQueueEmpty:** Check if main queue or any provider queue has items pending to process.

## EventTypes:

There are a range of eventtypes you can define in your logs: etHeader, etInfo, etSuccess, etWarning, etError, etCritical, etException, etDebug, etTrace, etCustom1, etCustom2.

Every logger provider can be configured to listen for one or more of these event types and limit the number of received eventtypes received for a range of eventtypes per Day, hour, minute or second for avoid performance problems or be spammed.

## Log Providers:
Providers manage the output for your logs. Output can be file, console, email, etc. If a provider fails many times to send a log, will be disabled automatically (full disk, remote server down, etc). Limits can be specified per provider.
Providers have a property to change Time format settings property to your needs.
Every provider has a queue log to receive log items, but can be disabled to allow direct write/send.
There are some events to control providers work (OnRestart, OnCriticalError, OnSendLimits, etc).

There are some predefined providers, but you can make your own provider if needed:

**FILE PROVIDER:**
- **Quick.Logger.Provider.Files:** Sends logging to a file, managing log rotation and compression.
	
    Properties:
    
    - **Filename:** Filename of your log file. If not defined, gets name of your program + log
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of logs entries sent by day, hour, minute or second to avoid be spammed. Can be configured to limit only certain event types.
    - **ShowEventType:** Shows eventype (WARN, ERROR, INFO,..)
    - **ShowHeaderInfo:** Every execution or new log file logs a header with system information like Username, CPU, path, debug mode, etc.
	- **UnderlineHeaderEventType:** Writes an underline below every etHeader eventtype.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **DailyRotate:** Rotates log file every day.
    - **MaxFileSizeInMB:** If value is greater than 0, rotates log file by size. It's independent of dailyrotate option. 
    - **MaxRotateFiles:** Max number of files to keep when rotate a log.
	- **RotatedFilesPath:** Path where rotated files will be moved/zipped. If leave blank, rotated files will be remain in same folder log exists.
    - **CompressRotatedFiles:** Defines if rotated files will be compressed.
    - **Enabled**: Enables/disables receive logging.
   
**CONSOLE PROVIDER:**
- **Quick.Logger.Provider.Console:** Sends logging to console out, allowing colored eventypes and timestamp.
	
    Properties:
    
    - **ShowEventColors:** Enables colored Event types when writes to console. There are predefined colors but you can change every eventype color with EventTypeColor property (EventTypeColor[etInfo] := clBlue)
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of logs entries sent by day, hour, minute or second to avoid be spammed. Can be configured to limit only certain event types.
    - **ShowEventType:** Shows eventype (WARN, ERROR, INFO,..).
	- **UnderlineHeaderEventType:** Writes an underline below every etHeader eventtype.
    - **ShowTimeStamp:** Shows datetime for every log entry.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Enabled:** Enables/disables receive logging.

**EMAIL PROVIDER:**
- **Quick.Logger.Provider.Email:** Sends logging by email.
	
    Properties:
    
    - **SMTP:** Class to define host and email account info.
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second to avoid be spammed. Can be configured to limit only certain event types.
    - **ShowTimeStamp:** Shows datetime for every log entry.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Enabled:** Enables/disables receive logging.

**EVENTS PROVIDER:**
- **Quick.Logger.Provider.Events:** Allows throw an event for every log item received. 
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **OnInfo..OnError and OnAny:** Events thown for every event type.
    - **Enabled:** Enables/disables receive logging.

**IDE DEBUG PROVIDER:**
- **Quick.Logger.Provider.IDEDebug:** Sends Logging to IDE Debug messages.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Enabled:** Enables/disables receive logging. Provider begins to receive logs after enabled.

**WINDOWS EVENTLOG PROVIDER:**
- **Quick.Logger.Provider.EventLog:** Sends Logging to Windows EventLog.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Source:** Name of source shown in eventlog.
    - **Enabled:** Enables/disables receive logging.

**HTTP REST PROVIDER:**
- **Quick.Logger.Provider.Rest:** Sends Logging to Restserver as a JSON post.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **UserAgent:** Useragent string.
    - **URL:** URL to send post json.
	- **JsonOutputOptions:** Json options to format output json.
    - **Enabled:** Enables/disables receive logging.

**REDIS PROVIDER:**
- **Quick.Logger.Provider.Redis:** Sends Logging to Redis server.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Host:** Redis server DNS or ip.
    - **Port:** Redis server port.
    - **LogKey:** Redis will save log into this key.
    - **MaxSize:** Limits size of redis key. When reached, old entries are deleted.
    - **Password:** For access to secured Redis servers.
	- **OutputAsJson:** Sends log as Json.
    - **Enabled:** Enables/disables receive logging.

**MEMORY PROVIDER:**
- **Quick.Logger.Provider.Memory:** Saves logging into memory.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **MaxSize:** Limits size. When reached, old entries are deleted.
    - **MemLog:** Object list containing all log item entries.
    - **AsStrings:** Returns a TStringList containing all log item entries.
    - **AsString:** Returns a string containing all log item entries.
    - **Enabled:** Enables/disables receive logging.
	
**TELEGRAM PROVIDER:**	
- **Quick.Logger.Provider.Telegram:** Send log as a message to public/private Telegram channel. (You need token of a bot in this channel)
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **ChannelName:** Name of channel to send messages. If its a private channel, ChannelName will be an Id. QuickLogger can get this Id automatically if bot has sent a message to this channel first. You can get it with this request https://api.telegram.org/bot<token>/getUpdates
	- **ChannelType:** Private or Public channel.
    - **BotToken:** Telegram bot token key.
    - **Enabled:** Enables/disables receive logging.
	
**SLACK PROVIDER:**
- **Quick.Logger.Provider.Slack:** Send log as a message to public/private Slack channel.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **ChannelName:** Name of channel to send messages.
    - **UserName:** Name included as sender.
    - **WebHookURL:** Webhook with permissions to send to the channel. https://api.slack.com/incoming-webhooks
    - **Enabled:** Enables/disables receive logging.
	
**ADODB PROVIDER:**
- **Quick.Logger.Provider.ADODB:** Saves log to ADO database (MSSQL, MSAccess, etc..)
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **DBConfig:** Database config.
    - **ConnectionString:** Alternativelly, you can specify a connectionstring directly.
    - **FieldsMapping:** Customizes your log fields, mapping each log field with its corresponding database field.
    - **Enabled:** Enables/disables receive logging.
	
**SYSLOG PROVIDER:**
- **Quick.Logger.Provider.SysLog:** Sends Logging to SysLog server.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
	- **Host:** SysLog server host.
	- **Port:** SysLog server port.
	- **Facility:** Type of program is logging to syslog.
    - **Enabled:** Enables/disables receive logging.
	
**LOGSTASH PROVIDER:**
- **Quick.Logger.Provider.Logstash:** Sends Logging to Logstash service.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
	- **URL:** Host
	- **JsonOutputOptions:** Json options to format output json.
	- **IndexName:** ElasticSearch index name.
	- **DocType:** Entry document type.
	- **Enabled:** Enables/disables receive logging.

**ELASTICSEARCH PROVIDER:**
- **Quick.Logger.Provider.ElasticSearch:** Sends Logging to ElasticSearch server.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
	- **URL:** Host and port
	- **JsonOutputOptions:** Json options to format output json.
	- **IndexName:** ElasticSearch index name.
	- **DocType:** Entry document type.
    - **Enabled:** Enables/disables receive logging.
	
**INFLUXDB PROVIDER:**
- **Quick.Logger.Provider.InfluxDB:** Sends Logging to InfluxDB Database.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **URL:** Host and port
    - **Database:** Database name.
    - **UserName:** Database username.
    - **Password:** Database password.
    - **CreateDatabaseIfNotExists:** Creates influxdb database if not exists on server.
    - **IncludedTags:** Tags included to influxdb.
    - **Enabled:** Enables/disables receive logging.
	
**GRAYLOG PROVIDER:**
- **Quick.Logger.Provider.GrayLog:** Sends Logging to GrayLog service.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **URL:** Host and port
    - **GrayLogVersion:** GrayLog version to send to server.
    - **ShortMessageAsEventType:** If enabled, shortmessage will be eventype as string and fullmessage will be the log message.
    - **Enabled:** Enables/disables receive logging.

**SENTRY PROVIDER:**
- **Quick.Logger.Provider.Sentry:** Sends Logging to Sentry service.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **DSNKey:** Uses DSN provided by Sentry to configure api server access.
    - **SentryVersion:** Sentry version to send to server.
    - **Secured:** Enable to use https.
    - **Host:** : Defines Sentry host endpoint.
    - **ProjectId:** Set your Sentry Project Id.
    - **PublicKey:** Set your Sentry Public Key.
    - **Enabled:** Enables/disables receive logging.

**TWILIO PROVIDER:**
- **Quick.Logger.Provider.Twilio:** Sends Logging to Twilio service.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **AccountSID:** Account SID provided by Twilio.
    - **AuthToken:** Token of your Twilio account.
    - **SendFrom:** Phone from you are sending sms/whastup.
    - **SendTo:** Phone you are sending to sms/whatsup.
    - **Enabled:** Enables/disables receive logging.

## Optional output:

QuickLogger allows to select what info to log. You can include HOSTNAME, OS Version, AppName, Platform or Environment(production, test, etc), ThreadId, ProcessId and other fields (to be compatible with multienvironments or multidevices). It's more evident for a remote logging like redis or rest, but File provider can be write a header with this fields if you like.
 
Properties:
    
- **Platform:** Define your log source (API, Destokp app or your own value).
- **Environment:** Define your environment (Production, Test, develop or your own value). 
- **AppName:** Uses default filename without extension, but can be customized.
- **IncludedInfo:** Define which fields do you want to include as part of your log info (iiAppName, iiHost, iiUserName, iiEnvironment, iiPlatform, iiOSVersion, iiExceptionInfo, iiExceptionStackTrace, iiThreadId, iiProcessId)
- **IncludedTags:** Define wich tags do you want to include as part of your log info (tags are global and need to added to logger).
	
```delphi
GlobalLogConsoleProvider.IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
GlobalLogConsoleProvider.IncludedTags := ['MyTag1','MyTag2'];
```

- **CustomMsgOutput:** If enabled, LogItem.Msg field is only included as output. It ables to send customized json to redis, rest, etc. 

```delphi
GlobalLogRedisProvider.CustomMsgOutput := True;
Log('{"level":"warn","text":"my text"}',etInfo);
```
- **CustomFormatOutput:** Better control of custom output. Define a format template output to allow customize at your own way. CustomMsgOutput needs to be True.
```delphi
GlobalLogConsoleProvider.CustomMsgOutput := True;
GlobalLogConsoleProvider.CustomFormatOutput := '%{DATE} & %{TIME} - [%{LEVEL}] : %{MESSAGE} (%{MYTAG1})';
```
QuickLogger has a lot of predefined variables, but you can define your own tags to use into custom output format. 

### Predefined variables:

**DATETIME** : Date & time log item occurs

**DATE** : Date log item occurs

**TIME** : Time log item occurs

**LEVEL** : Level or Eventype 

**LEVELINT** : Level as numeric

**MESSAGE** : Message sent to logger

**ENVIRONMENT** : Customizable variable (normally Production, Test, etc)

**PLATFORM** : Customizable variable (normally Desktop, Mobile, etc)

**APPNAME** : Customizable variable (by default set as filename without extension)

**APPVERSION** : Application file version

**APPPATH** : Application run path

**HOSTNAME** : Computer name

**USERNAME** : Logged user name

**OSVERSION** : OS version

**CPUCORES** : Number of CPU cores

**THREAID** : Thread Id log item set

### Custom Tags:

- **LogTags:** Add your own tags to be accesible as part of log output.

```delphi
Logger.LogTags['MODULE'] := 'Admin';
GlobalLogConsoleProvider.CustomMsgOutput := True;
GlobalLogConsoleProvider.CustomFormatOutput := '%{DATE} & %{TIME} - [%{LEVEL}] : %{MESSAGE} (%{MODULE})';
```


### Load/Save Config:
QuickLogger can import or export config from/to JSON format. This feature allows a easy way to preconfigure your providers.

```delphi
	//Load single provider from json file
	GlobalLogRedisProvider.LoadFromFile('C:\logfileprovider.json');
	//Save all providers to json file
	Logger.Providers.SaveToFile('C:\loggerconfig.json');
	//Load all providers from json string
	Logger.Providers.FromJson(json);
```
	
	Example multiprovider config file:
	
	{"GlobalLogConsoleProvider":
			{
                "ShowEventColors": true,
                "ShowTimeStamp": true,
                "UnderlineHeaderEventType": false,
                "Name": "TLogConsoleProvider",
                "LogLevel": "[etHeader,etInfo,etSuccess,etWarning,etError,etCritical,etException,etDone,etCustom1,etCustom2]",
                "TimePrecission": true,
                "MaxFailsToRestart": 2,
                "MaxFailsToStop": 10,
                "CustomMsgOutput": false,
                "UsesQueue": true,
                "Enabled": true,
                "SendLimits": {
                               "TimeRange": "slNoLimit",
                               "LimitEventTypes": "[]",
                               "MaxSent": 0
                },
                "AppName": "QuickLoggerDemo",
                "Environment": "",
                "PlatformInfo": "",
                "IncludedInfo": "[iiAppName,iiHost]"
			},

	"GlobalLogFileProvider":
			{
                "FileName": "D:\\LoggerDemo.log",
                "AutoFileNameByProcess": false,
                "MaxRotateFiles": 3,
                "MaxFileSizeInMB": 10,
                "DailyRotate": false,
                "RotatedFilesPath": "",
                "CompressRotatedFiles": false,
                "ShowEventType": true,
                "ShowHeaderInfo": true,
                "UnderlineHeaderEventType": false,
                "AutoFlush": false,
                "Name": "TLogFileProvider",
                "LogLevel": "[etInfo,etSuccess,etWarning,etError,etCritical,etException]",
                "TimePrecission": false,
                "MaxFailsToRestart": 2,
                "MaxFailsToStop": 10,
                "CustomMsgOutput": false,
                "UsesQueue": true,
                "Enabled": true,
                "SendLimits": {
                               "TimeRange": "slNoLimit",
                               "LimitEventTypes": "[etInfo]",
                               "MaxSent": 0
                },
                "AppName": "QuickLoggerDemo",
                "Environment": "",
                "PlatformInfo": "",
                "IncludedInfo": "[iiAppName,iiHost,iiUserName,iiOSVersion]"
			}	
	}

## Logging Exceptions:

QuickLogger can capture your application exceptions. There are 3 exception hooks. You need to add one or more units to your uses clause:


- **Quick.Logger.ExceptionHook:** Receive every raise exception. QuickLogger receives even try..except exceptions.
- **Quick.Logger.RuntimeErrorHook:** Receive runtime errors.
- **Quick.Logger.UnhandledExceptionHook:** Receive only unhandled exceptions (not in try..except block).


>Do you want to learn delphi or improve your skills? [learndelphi.org](https://learndelphi.org)