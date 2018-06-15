## QuickLogger
----------

Delphi/Freepascal (Windows/Linux) library for logging on multi providers:
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

### Updates:

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

### Logger:
QuickLogger manages Logger and Providers automatically. Logger and providers have a global class, auto created and released on close your app. You only need to add wanted providers to your uses clause. 
> Note: You need to add almost one provider to send logging.

### EventTypes:

There are a range of eventtypes you can define in your logs: etHeader, etInfo, etSuccess, etWarning, etError, etCritical, etException, etDebug, etTrace, etCustom1, etCustom2.

Every logger provider can be configured to listen for one or more of these event types and limit the number of received eventtypes received for a range of eventtypes per Day, hour, minute or second for avoid performance problems or be spammed.

### Providers:
Providers manage the output for your logs. Output can be file, console, email, etc. If a provider fails many times to send a log, will be disabled automatically (full disk, remote server down, etc). Limits can be specified per provider.
Providers have a property to change Time format settings property to your needs.
Every provider has a queue log to receive log items, but can be disabled to allow direct write/send.
There are some events to control providers work (OnRestart, OnCriticalError, OnSendLimits, etc).

There are some predefined providers, but you can make your own provider if needed:

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

- **Quick.Logger.Provider.Email:** Sends logging by email.
	
    Properties:
    
    - **SMTP:** Class to define host and email account info.
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second to avoid be spammed. Can be configured to limit only certain event types.
    - **ShowTimeStamp:** Shows datetime for every log entry.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Enabled:** Enables/disables receive logging.

- **Quick.Logger.Provider.Events:** Allows throw an event for every log item received. 
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **OnInfo..OnError and OnAny:** Events thown for every event type.
    - **Enabled:** Enables/disables receive logging.

- **Quick.Logger.Provider.IDEDebug:** Sends Logging to IDE Debug messages.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Enabled:** Enables/disables receive logging.

- **Quick.Logger.Provider.EventLog:** Sends Logging to Windows EventLog.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **Source:** Name of source shown in eventlog.
    - **Enabled:** Enables/disables receive logging.

- **Quick.Logger.Provider.Rest:** Sends Logging to Restserver as a JSON post.
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **UserAgent:** Useragent string.
    - **URL:** URL to send post json.
    - **Enabled:** Enables/disables receive logging.

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
	
- **Quick.Logger.Provider.ADODB:** Saves log to ADO database (MSSQL, MSAccess, etc..).
	
    Properties:
    
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of emails sent by day, hour, minute or second.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **DBConfig:** Database config.
    - **ConnectionString:** Alternativelly, you can specify a connectionstring directly.
    - **FieldsMapping:** Customizes your log fields, mapping each log field with its corresponding database field.
    - **Enabled:** Enables/disables receive logging.
	
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

### Optional output:

QuickLogger allows to select with info to log. You can include HOSTNAME, OS Version, AppName, Platform or Environment(production, test, etc) and other fields (to be compatible with multienvironments or multidevices). It's more evident for a remote logging like redis or rest, but File provider can be write a header with this fields if you like.
    Properties:
    
    - **Platform:** Define your log source (API, Destokp app or your own value).
    - **Environment:** Define your environment (Production, Test, develop or your own value). 
	- **AppName:** Uses default filename without extension, but can be customized.
    - **IncludedInfo:** Define which fields do you want to include as part of your log info.
```delphi
GlobalLogConsoleProvider.IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
```
	- **CustomMsgOutput:** If enabled, LogItem.Msg field is only included as output. It ables to send customized json to redis, rest, etc. 
```delphi
GlobalLogRedisProvider.CustomMsgOutput := True;
Log('{"level":"warn","text":"my text"}',etInfo);
```

### Logging Exceptions:

QuickLogger can capture your application exceptions. Add unit Quick.Logger.ExceptionHook to your uses clause to allow receiving any exception thown.

> Note: QuickLogger receives even try..except exceptions.