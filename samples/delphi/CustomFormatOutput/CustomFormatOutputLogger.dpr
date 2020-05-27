program CustomFormatOutputLogger;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Quick.Commons,
  Quick.Console,
  Quick.Logger,
  Quick.Logger.Provider.Console,
  Quick.Logger.Provider.Files;

begin
  try
    //wait for 60 seconds to flush pending logs in queue on program finishes
    Logger.WaitForFlushBeforeExit := 60;
    Logger.CustomTags['MYTAG1'] := 'MyTextTag1';
    Logger.CustomTags['MYTAG2'] := 'MyTextTag2';

    //configure Console Log provider
    Logger.Providers.Add(GlobalLogConsoleProvider);
    with GlobalLogConsoleProvider do
    begin
      LogLevel := LOG_ALL;
      ShowEventColors := True;
      ShowTimeStamp := True;
      TimePrecission := True;
      CustomMsgOutput := True;
      CustomFormatOutput := '%{DATE} %{TIME} - [%{LEVEL}] : %{MESSAGE} (%{MYTAG1} / %{MYTAG2})';
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
      CustomMsgOutput := True;
      CustomFormatOutput := '%{DATETIME} [%{LEVEL}] : %{MESSAGE} [%{APPNAME}] (%{MYTAG2})';
      Enabled := True;
    end;

    Logger.Info('This is a info message');

    Logger.Error('This is a error message');

    Logger.Done('This is a done message');




    ConsoleWaitForEnterKey;

    //check if you press the key before all items are flushed to console/disk
    if Logger.QueueCount > 0 then
    begin
      cout(Format('There are %d log items in queue. Waiting %d seconds max to flush...',[Logger.QueueCount,Logger.WaitForFlushBeforeExit]),ccYellow);
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
