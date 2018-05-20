program ConsoleLogger;

{$mode delphi}

uses
  {$IFDEF UNIX}
  CThreads,
  {$ENDIF}
  Classes,
  Quick.Logger,
  Quick.Logger.Provider.Console,
  Quick.Logger.Provider.Files;
  //Quick.Logger.Provider.Events,
  //Quick.Logger.Provider.Rest,
  //Quick.Logger.Provider.Redis,
  //Quick.Logger.Provider.Memory;

begin
  GlobalLogConsoleProvider.LogLevel := LOG_DEBUG;
  GlobalLogConsoleProvider.Enabled := True;
  GlobalLogConsoleProvider.ShowTimeStamp:= True;
  Logger.Providers.Add(GlobalLogConsoleProvider);

  GlobalLogFileProvider.LogLevel := LOG_DEBUG;
  GlobalLogFileProvider.Enabled := True;
  Logger.Providers.Add(GlobalLogFileProvider);

  Log('Console output Test',etHeader);
  Log('Hello world!',etInfo);
  Log('Error Test!',etError);
  Log('Warning Test',etWarning);
  Log('Debug Test',etDebug);
  Log('Trace Test',etTrace);
  Log('Critical Test',etCritical);
  Log('Exception Test',etException);
end.

