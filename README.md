## QuickLogger
----------

Delphi library for logging on files, console, memory, email, rest, eventlog, redis, ide debug messages or throw events.

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
        MaxSizeInMB := 20;
        LogLevel := LOG_ALL;
    	Enabled := True;
  	end;
    with GlobalConsoleProvider do
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
Providers manage the output for your logs. Output can be file, console, email, etc. If a provider fails many times to send a log, will be disabled automatically (full disk, remote server down, etc).

There are some predefined providers, but you can make your own provider if needed:

- **Quick.Logger.Provider.Console:** Sends logging to a file, managing log rotation and compression.
	
    Properties:
    
    - **Filename:** Filename of your log file. If not defined, gets name of your program + log
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of logs entries sent by day, hour, minute or second to avoid be spammed. Can be configured to limit only certain event types.
    - **ShowEventType:** Shows eventype (WARN, ERROR, INFO,..)
    - **ShowHeaderInfo:** Every execution or new log file logs a header with system information like Username, CPU, path, debug mode, etc.
    - **TimePrecission:** If true, shows date and time and milliseconds in log entries.
    - **DailyRotate:** Rotates log file every day.
    - **MaxFileSizeInMB:** If value is greater than 0, rotates log file by size. It's independent of dailyrotate option. 
    - **MaxRotateFiles:** Max number of files to keep when rotate a log.
    - **CompressRotatedFiles:** Defines if rotated files will be compressed.
    - **Enabled**: Enables/disables receive logging.
   
- **Quick.Logger.Provider.Console:** Sends logging to console out, allowing colored eventypes and timestamp.
	
    Properties:
    
    - **ShowEventColors:** Enables colored Event types when writes to console. There are predefined colors but you can change every eventype color with EventTypeColor property (EventTypeColor[etInfo] := clBlue)
    - **LogLevel:** Log level that your provider accepts.
    - **EventTypeNames:** Every eventtype has a customizable text you can change to be reflected in your logs. 
    - **SendLimits:** Defines max number of logs entries sent by day, hour, minute or second to avoid be spammed. Can be configured to limit only certain event types.
    - **ShowEventType:** Shows eventype (WARN, ERROR, INFO,..).
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

### Logging Exceptions:

QuickLogger can capture your application exceptions. Add unit Quick.Logger.ExceptionHook to your uses clause to allow receiving any exception thown.

> Note: QuickLogger receives even try..except exceptions.