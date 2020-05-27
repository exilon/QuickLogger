program MultiLogger;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Classes,
  SysUtils,
  Quick.Console,
  Quick.Threads,
  Quick.Logger,
  Quick.Logger.ExceptionHook,
  Quick.Logger.Provider.Console,
  Quick.Logger.Provider.Files,
  Quick.Logger.Provider.Email,
  Quick.Logger.Provider.Events,
  Quick.Logger.Provider.Rest,
  Quick.Logger.Provider.Redis,
  Quick.Logger.Provider.IDEDebug,
  Quick.Logger.Provider.EventLog,
  Quick.Logger.Provider.Memory,
  Quick.Logger.Provider.Telegram,
  Quick.Logger.Provider.Slack,
  Quick.Logger.Provider.Logstash,
  Quick.Logger.Provider.ElasticSearch,
  Quick.Logger.Provider.InfluxDB,
  Quick.Logger.Provider.GrayLog,
  Quick.Logger.Provider.Sentry,
  Quick.Logger.Provider.Twilio;

type

  TMyEvent = class
    procedure Critical(logItem : TLogItem);
  end;

  procedure TMyEvent.Critical(logItem : TLogItem);
  begin
    Writeln(Format('OnCritical Event received: %s',[logitem.Msg]));
  end;

var
  backgroundtasks : TBackgroundTasks;

  procedure MultiThreadWriteTest;
  var
    i : Integer;
  begin
    //add 100000 tasks to 10 thread workers
    backgroundtasks := TBackgroundTasks.Create(10);
    backgroundtasks.Start;
    for i := 1 to 100000 do
    begin
      backgroundtasks.AddTask([i],False,
                              procedure(task : ITask)
                              begin
                                Logger.Info('Task %d started (%s)',[task.Param[0].AsInteger,DateTimeToStr(Now)]);
                              end
                            ).OnException(
                              procedure(task : ITask; aException : Exception)
                              begin
                                Logger.Error('Task %d failed: %s (%s)',[task.Param[0].AsInteger,aException.Message,DateTimeToStr(Now)]);
                              end
                            ).OnTerminated(
                              procedure(task : ITask)
                              begin
                                Logger.Done('Task %d finished (%s)',[task.Param[0].AsInteger,DateTimeToStr(Now)]);
                              end
                            ).Run;
    end;
  end;

begin
  //wait for 60 seconds to flush pending logs in queue on program finishes
  Logger.WaitForFlushBeforeExit := 60;
  Logger.CustomTags.Add('MyTag','MyText');

  //configure Console Log provider
  Logger.Providers.Add(GlobalLogConsoleProvider);
  with GlobalLogConsoleProvider do
  begin
    LogLevel := LOG_ALL;
    ShowEventColors := True;
    ShowTimeStamp := True;
    TimePrecission := True;
    {$IFDEF DELPHIXE7_UP}
    IncludedTags := ['MYTAG'];
    {$ENDIF}
    Enabled := True;
  end;

  //configure File log provider
  Logger.Providers.Add(GlobalLogFileProvider);
  with GlobalLogFileProvider do
  begin
    FileName := '.\LoggerDemo.log';
    LogLevel := LOG_ALL;
    TimePrecission := True;
    MaxRotateFiles := 3;
    MaxFileSizeInMB := 5;
    RotatedFilesPath := '.\RotatedLogs';
    CompressRotatedFiles := False;
    Enabled := True;
  end;

  //configure Email log provider
  Logger.Providers.Add(GlobalLogEmailProvider);
  with GlobalLogEmailProvider do
  begin
    LogLevel := [etCritical];
    SMTP.Host := 'smtp.domain.com';
    SMTP.Username := 'myemail@domain.com';
    SMTP.Password := '1234';
    Mail.SenderName := 'Quick.Logger Alert';
    Mail.From := 'myemail@domain.com';
    Mail.Recipient := 'otheremail@domain.com';
    Mail.CC := '';
    Enabled := False; //enable when you have a stmp server to connect
  end;

  //configure Events log provider
  Logger.Providers.Add(GlobalLogEventsProvider);
  with GlobalLogEventsProvider do
  begin
    LogLevel := [etWarning,etCritical];
    SendLimits.TimeRange := slByMinute;
    SendLimits.LimitEventTypes := [etWarning];
    SendLimits.MaxSent := 2;
    OnCritical := procedure(logItem : TLogItem)
                  begin
                    Writeln(Format('OnCritical Event received: %s',[logitem.Msg]));
                  end;
    OnWarning := procedure(logItem : TLogItem)
              begin
                Writeln(Format('OnWarning Event received: %s',[logitem.Msg]));
              end;
    Enabled := True;
  end;

  //configure IDEDebug provider
  Logger.Providers.Add(GlobalLogIDEDebugProvider);
  with GlobalLogIDEDebugProvider do
  begin
    LogLevel := [etCritical];
    Enabled := True;
  end;

  //configure EventLog provider
  Logger.Providers.Add(GlobalLogEventLogProvider);
  with GlobalLogEventLogProvider do
  begin
    LogLevel := [etSuccess,etError,etCritical,etException];
    Source := 'QuickLogger';
    Enabled := True;
  end;

  //configure Rest log provider
  Logger.Providers.Add(GlobalLogRestProvider);
  with GlobalLogRestProvider do
  begin
    URL := 'http://localhost/event';
    LogLevel := [etError,etCritical,etException];
    Environment := 'Production';
    PlatformInfo := 'Desktop';
    IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
    Enabled := False; //enable when you have a http server server to connect
  end;

  //configure Redis log provider
  Logger.Providers.Add(GlobalLogRedisProvider);
  with GlobalLogRedisProvider do
  begin
    Host := '192.168.1.133';
    LogKey := 'Log';
    MaxSize := 1000;
    Password := 'pass123';
    Environment := 'Production';
    PlatformInfo := 'API';
    IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
    OutputAsJson := True;
    LogLevel := LOG_ALL;// [etError,etCritical,etException];
    Enabled := False; //enable when you have a redis to connect
  end;

  //configure Mem log provider
  Logger.Providers.Add(GlobalLogMemoryProvider);
  with GlobalLogMemoryProvider do
  begin
    LogLevel := [etError,etCritical,etException];
    Enabled := True;
  end;

  //configure Telegram log provider
  Logger.Providers.Add(GlobalLogTelegramProvider);
  with GlobalLogTelegramProvider do
  begin
    ChannelName := 'Exilon';
    ChannelType := TTelegramChannelType.tcPrivate;
    BotToken := 'xxxxxxxxxxxx';
    LogLevel := [etError,etCritical,etException];
    Enabled := False; //enable when you have a Telegram bot and Channel configured to send messages
  end;

  //configure Slack log provider
  Logger.Providers.Add(GlobalLogSlackProvider);
  with GlobalLogSlackProvider do
  begin
    ChannelName := '#alerts';
    UserName := 'Exilon';
    WebHookURL := 'https://hooks.slack.com/services/TXXXXXXXX/BXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX';
    LogLevel := [etError,etCritical,etException];
    Enabled := False; //enable when you have a Slack Weekhook to send messages
  end;

  //configure Logstash log provider
  Logger.Providers.Add(GlobalLogLogstashProvider);
  with GlobalLogLogstashProvider do
 begin
    URL := 'http://192.168.1.133:5011';
    IndexName := 'logger';
    LogLevel := [etError,etCritical,etException];
    Environment := 'Production';
    PlatformInfo := 'Desktop';
    IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
    Enabled := False; //enable when you have a logstash service to connect
  end;

  //configure ElasticSearch log provider
  Logger.Providers.Add(GlobalLogElasticSearchProvider);
  with GlobalLogElasticSearchProvider do
  begin
    URL := 'http://192.168.1.133:9200';
    IndexName := 'logger';
    LogLevel := [etError,etCritical,etException];
    Environment := 'Production';
    PlatformInfo := 'Desktop';
    IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
    Enabled := False; //enable when you have a ElasticSearch service to connect
  end;

  //configure InfluxDB log provider
  Logger.Providers.Add(GlobalLogInfluxDBProvider);
  with GlobalLogInfluxDBProvider do
  begin
    URL := 'http://192.168.1.133:8086';
    DataBase := 'logger';
    CreateDataBaseIfNotExists := True;
    LogLevel := LOG_DEBUG;
    MaxFailsToRestart := 5;
    MaxFailsToStop := 0;
    Environment := 'Production';
    PlatformInfo := 'Desktop';
    IncludedTags := [iiAppName,iiHost,iiEnvironment,iiPlatform];
    IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
    Enabled := False; //enable when you have a InfluxDB server to connect
  end;

  //configure GrayLog log provider
  Logger.Providers.Add(GlobalLogGrayLogProvider);
  with GlobalLogGrayLogProvider do
    begin
      URL := 'http://192.168.1.133:12201';
      LogLevel := LOG_DEBUG;
      MaxFailsToRestart := 5;
      MaxFailsToStop := 0;
      Environment := 'Production';
      PlatformInfo := 'Desktop';
      IncludedInfo := [iiAppName,iiEnvironment,iiPlatform];
      Enabled := False; //enable when you have a GrayLog server to connect
    end;

  //configure Sentry log provider
  Logger.Providers.Add(GlobalLogSentryProvider);
  with GlobalLogSentryProvider do
    begin
      DSNKey := 'https://xxxxxxxxxxx@999999.ingest.sentry.io/999999';
      LogLevel := LOG_DEBUG;
      MaxFailsToRestart := 5;
      MaxFailsToStop := 0;
      Environment := 'Production';
      PlatformInfo := 'Desktop';
      IncludedInfo := [iiAppName,iiEnvironment,iiPlatform,iiOSVersion,iiUserName];
      Enabled := False; //enable when you have a Sentry server to connect
    end;

  //configure Twilio log provider
  Logger.Providers.Add(GlobalLogTwilioProvider);
  with GlobalLogTwilioProvider do
    begin
      AccountSID := 'ACxxxxxxxxx';
      AuthToken := 'xxxx';
      SendFrom := '+123123123';
      SendTo := '+123123123';
      LogLevel := LOG_DEBUG;
      MaxFailsToRestart := 5;
      MaxFailsToStop := 0;
      Environment := 'Production';
      PlatformInfo := 'Desktop';
      IncludedInfo := [iiAppName,iiEnvironment,iiPlatform,iiOSVersion,iiUserName];
      Enabled := False; //enable when you have a Twilio account to connect
    end;

  Logger.RedirectOwnErrorsToProvider := GlobalLogConsoleProvider;

  Log('Quick.Logger Demo 1 [Event types]',etHeader);
  Logger.Info('Hello world!');
  Logger.Error('An error msg!');
  Logger.Warn('A warning msg!');
  Logger.Critical('A critical error!');
  Logger.Succ('Successfully process');

  Log('Quick.Logger Demo 2 [Exception Hook]',etHeader);
  //raise an exception
  try
    raise Exception.Create('Exception example raised to be catched by logger');
  except
    //Logger catches this exception
  end;

  Logger.Info('Press <Enter> to begin Thread collision Test');
  //ConsoleWaitForEnterKey;

  Log('Quick.Logger Demo 3 [Thread collision]',etHeader);
  MultiThreadWriteTest;
  ConsoleWaitForEnterKey;

  //check if you press the key before all items are flushed to console/disk
  if Logger.QueueCount > 0 then
  begin
    cout(Format('There are %d log items in queue. Waiting %d seconds max to flush...',[Logger.QueueCount,Logger.WaitForFlushBeforeExit]),ccYellow);
  end;
end.
