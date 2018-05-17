program MultiLogger;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Classes,
  SysUtils,
  Quick.Console,
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
  Quick.Logger.Provider.Memory;

var
  a : Integer;

  procedure Test;
  var
    x : Integer;
    threadnum : Integer;
  begin
    Inc(a);
    threadnum := a;
    Sleep(Random(50));
    for x := 1 to 10000 do
    begin
      Log('Thread %d - Item %d (%s)',[threadnum,x,DateTimeToStr(Now)],etWarning);
    end;
    Log('Thread %d - (Finished) (%s)',[threadnum,DateTimeToStr(Now)],etWarning);
  end;

  procedure MultiThreadWriteTest;
  var
    i : Integer;
  begin
    a := 0;
    for i := 1 to 30 do
    begin
      Log('Launch Thread %d',[i],etInfo);
      TThread.CreateAnonymousThread(Test).Start;
    end;
    Sleep(1000);
    Log('Process finished. Press <Enter> to Exit',etInfo);
  end;

  type

  TMyEvent = class
    procedure Critical(logItem : TLogItem);
  end;

  procedure TMyEvent.Critical(logItem : TLogItem);
  begin
    Writeln(Format('OnCritical Event received: %s',[logitem.Msg]));
  end;

begin
  //wait for 60 seconds to flush pending logs in queue on program finishes
  Logger.WaitForFlushBeforeExit := 60;
  //configure Console Log provider
  Logger.Providers.Add(GlobalLogConsoleProvider);
  with GlobalLogConsoleProvider do
  begin
    LogLevel := LOG_ALL;
    ShowEventColors := True;
    ShowTimeStamp := True;
    TimePrecission := True;
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
    Enabled := True; //enable when you have a redis to connect
  end;
  //configure Mem log provider
  Logger.Providers.Add(GlobalLogMemoryProvider);
  with GlobalLogMemoryProvider do
  begin
    LogLevel := [etError,etCritical,etException];
    Enabled := True;
  end;

  Log('Quick.Logger Demo 1 [Event types]',etHeader);
  Log('Hello world!',etInfo);
  Log('An error msg!',etError);
  Log('A warning msg!',etWarning);
  Log('A critical error!',etCritical);
  Log('Successfully process',etSuccess);

  Log('Quick.Logger Demo 2 [Exception Hook]',etHeader);
  //raise an exception
  try
    raise Exception.Create('Exception example raised to be catched by logger');
  except
    //Logger catches this exception
  end;

  Log('Press <Enter> to begin Thread collision Test',etInfo);
  //ConsoleWaitForEnterKey;

  Log('Quick.Logger Demo 3 [Thread collision]',etHeader);
  MultiThreadWriteTest;
  ConsoleWaitForEnterKey;

  //check if you press the key before all items are flushed to console/disk
  if Logger.QueueCount > 0 then
  begin
    Writeln(Format('There are %d log items in queue. Waiting %d seconds max to flush...',[Logger.QueueCount,Logger.WaitForFlushBeforeExit]));
  end;
end.
