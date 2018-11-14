library QuickLogger;

{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Library     : QuickLogger
  Description : Dynamic library headers for external languaje wrappers
  Author      : Kike Fuentes (Turric4n)
  Version     : 1.29
  Created     : 15/10/2017
  Modified    : 14/11/2018

  This file is part of QuickLogger: https://github.com/exilon/QuickLogger

 ***************************************************************************

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

 *************************************************************************** }

uses
  {$IFNDEF UNIX}
  Windows,
  ActiveX,
  {$ELSE}
  Unix,
  Memory,
  {$ENDIF}
  Quick.Logger,
  {$IFDEF MSWINDOWS}
  Quick.Logger.Provider.ADODB,
  Quick.Logger.Provider.EventLog,
  {$ENDIF}
  Quick.Logger.Provider.Console,
  Quick.Logger.Provider.Files,
  Quick.Logger.Provider.Redis,
  Quick.Logger.Provider.Slack,
  Quick.Logger.Provider.Email,
  Quick.Logger.Provider.SysLog,
  Quick.Logger.Provider.Telegram,
  Quick.Logger.Provider.Rest,
  {$IFDEF FPC}
  Generics.Collections,
  jsonparser,
  fpJSON,
  SysUtils,
  Classes;
  {$ELSE}
  System.JSON,
  System.Generics.Collections,
  System.SysUtils,
  System.Classes;
  {$ENDIF}

{$R *.res}

{$M+}

//Designed to work for UNICODE apps only!!!!

type
  //CALLBACK TYPES for QuickLogger wrappers (provider context)
  TWrapperError = procedure(msg : PChar); stdcall;
  TWrapperFailToLog = procedure; stdcall;
  TWrapperStart = procedure(msg : PChar); stdcall;
  TWrapperRestart = procedure; stdcall;
  TWrapperQueueError = procedure(msg : PChar); stdcall;
  TWrapperCriticalError = procedure(msg : PChar); stdcall;
  TWrapperSendLimits = procedure; stdcall;
  TWrapperStatusChanged = procedure(msg : PChar); stdcall;

  //Quicklogger to wrapper Event handler implementation

  { TProviderEventHandler }

  TProviderEventHandler = class
   private
    fprovider : ILogProvider;
    //Pointers to wrapper delegates.
    fwrappererror : TWrapperError;
    fwrapperfailtolog : TWrapperFailToLog;
    fwrapperstart : TWrapperStart;
    fwrapperrestart : TWrapperRestart;
    fwrapperqueueerror :  TWrapperQueueError;
    fwrappercriticalerror : TWrapperCriticalError;
    fwrappersendlimits : TWrapperSendLimits;
    fwraperstatuschanged : TWrapperStatusChanged;
    fproviderfriendlyname : string;
    //logger event references
    {$IFDEF FPC}
    procedure ToWrapperError(const msg : string);
    procedure ToWrapperFailToLog(const aProviderName : string);
    procedure ToWrapperStart(const aProviderName : string);
    procedure ToWrapperQueueError(const msg : string);
    procedure ToWrapperRestart(const aProviderName : string);
    procedure ToWrapperCriticalError(const aProviderName, ErrorMessage : string);
    procedure ToWrapperSendLimits(const aProviderName : string) ;
    procedure ToWrapperStatusChanged(aProviderName : string; status: TLogProviderStatus);
    {$ENDIF}
   protected
    constructor Create(const FriendlyName : string; Provider : ILogProvider);
    procedure TestCallbacks;
    //outside assignements from native library
    property Provider : ILogProvider read fprovider;
    property WrapperError : TWrapperError read fwrappererror write fwrappererror;
    property WrapperFailToLog : TWrapperFailToLog read fwrapperfailtolog write fwrapperfailtolog;
    property WrapperStart : TWrapperStart read fwrapperstart write fwrapperstart;
    property WrapperRestart : TWrapperRestart read fwrapperrestart write fwrapperrestart;
    property WrapperQueueError : TWrapperQueueError read fwrapperqueueerror write fwrapperqueueerror;
    property WrapperCriticalError : TWrapperCriticalError read fwrappercriticalerror write fwrappercriticalerror;
    property WrapperSendLimits : TWrapperSendLimits read fwrappersendlimits write fwrappersendlimits;
    property WrapperStatusChanged : TWrapperStatusChanged read fwraperstatuschanged write fwraperstatuschanged;
  end;

const
  QUICKLOGPROVIDERS : array [0..9] of string = ('ConsoleProvider', 'FileProvider', 'RedisProvider', 'TelegramProvider', 'SlackProvider', 'RestProvider', 'SysLogProvider', 'AdoProvider', 'WindowsEventLogProvider', 'EmailProvider');

var
  providerHandlers : TDictionary<string, TProviderEventHandler>;
  eventTypeConversion : TDictionary<string,TLogLevel>;

procedure msgdbg(const msg : string);
begin
  {$IFNDEF  UNIX}
  MessageBox(0, PChar(msg), 'Test from native library', MB_OK +
    MB_ICONINFORMATION);
  {$ELSE}
  {$ENDIF}
end;

function GetPChar(const str : string) : PChar;
begin
  {$IFNDEF  UNIX}
  Result := CoTaskMemAlloc(SizeOf(Char)*(Length(str)+1));
  {$ELSE}
  Result := Memory.MemAlloc(SizeOf(Char)*(Length(str)+1));
  {$ENDIF}
  {$IFNDEF FPC}
    strcopy(Result, PWideChar(str));
  {$ELSE}
    strcopy(result, pchar(str));
  {$ENDIF}
end;

{$IFNDEF FPC}

function InternalAddProviderFromJSON(const providerType, providerName, ProviderInfo : string) : Integer;
var
  provdr : ILogProvider;
  vjsonobject : TJSONObject;
begin
  if providerType = 'fileprovider' then  provdr := TLogFileProvider.Create
  else if providerType = 'consoleprovider' then provdr := TLogConsoleProvider.Create
  else if providerType = 'redisprovider' then provdr := TLogRedisProvider.Create
  else if providerType = 'telegramprovider' then provdr := TLogRedisProvider.Create
  else if providerType = 'slackprovider' then provdr := TLogTelegramProvider.Create
  else if providerType = 'restprovider' then provdr := TLogRestProvider.Create
  else if providerType = 'emailprovider' then provdr := TLogEmailProvider.Create
  else if providerType = 'adoprovider' then provdr := TLogADODBProvider.Create
  else if providerType = 'windowseventprovider' then provdr := TLogEventLogProvider.Create
  else if providerType = 'syslogprovider' then provdr := TLogSysLogProvider.Create;
  if provdr = nil then Result := Ord(False)
  else
  begin
    Writeln('Quick logger : Added provider! ' + providername + ' - ' + providertype);
    provdr.FromJson(ProviderInfo);
    providerHandlers.Add(providername, TProviderEventHandler.Create(providername, provdr));
    Logger.Providers.Add(provdr);
    TLogProviderBase(provdr).Enabled := True;
    Result := Ord(True);
  end;
end;

function AddProviderJSONNative(const Provider : string) : Integer; stdcall; export;
var
  vJSONScenario: TJSONValue;
  vJSONValue: TJSONValue;
  vJSONLevel : TJSONString;
  vJSONObject : TJSONObject;
  vProviderInfo : TJSONObject;
  realLogLevel : TLogLevel;
  providerInfo : string;
  providertype : string;
  providername : string;
begin
  Result := 0;
  try
    try
      vJSONScenario := TJSONObject.ParseJSONValue(Provider, False);
      if vJSONScenario <> nil then
      begin
        if vJSONScenario is TJSONObject then
        begin
          vJSONObject := vJSONScenario as TJSONObject;
          if vJSONObject.GetValue('providerType') as TJSONString = nil then Exit
          else if vJSONObject.GetValue('providerInfo') as TJSONObject = nil then Exit
          else if vJSONObject.GetValue('providerName') as TJSONString = nil then Exit;
          providertype := TJSONString(vJSONObject.GetValue('providerType')).ToString.ToLower.Replace('"','');
          providername := TJSONString(vJSONObject.GetValue('providerName')).ToString.Replace('"','');
          vProviderInfo :=  TJSONObject(vJSONObject.GetValue('providerInfo'));
          if vProviderInfo.GetValue('LogLevel') as TJSONString = nil then realLogLevel := LOG_ALL;
          providerInfo := vProviderInfo.ToJSON;
          Result := InternalAddProviderFromJSON(providertype, providerName, providerInfo)
        end;
      end;
    except
      on e : Exception do Writeln(e.Message);
    end;
  finally
    vJSONScenario.Free;
  end;
end;

{$ELSE}

function InternalAddProviderFromJSON(const providerType, providerName, ProviderInfo : string) : Integer;
var
  provdr : TLogProviderBase;
begin
  if providerType = 'FileProvider' then
  begin
    provdr := TLogFileProvider.Create;
    providerHandlers.Add(Providername, TProviderEventHandler.Create(providerName, provdr));
  end
  else if providerType = 'RedisProvider' then
  begin
    provdr := TLogRedisProvider.Create;
    providerHandlers.Add(Providername, TProviderEventHandler.Create(providerName, provdr));
  end
  else if providerType = 'TelegramProvider' then
  begin
    provdr := TLogTelegramProvider.Create;
    providerHandlers.Add(Providername, TProviderEventHandler.Create(providerName, provdr));
  end
  else if providerType = 'SlackProvider' then
  begin
    provdr := TLogSlackProvider.Create;
    providerHandlers.Add(Providername, TProviderEventHandler.Create(providerName, provdr));
  end
  else if providerType = 'RestProvider' then
  begin
    provdr := TLogRestProvider.Create;
    providerHandlers.Add(Providername, TProviderEventHandler.Create(providerName, provdr));
  end;
end;

function AddProviderJSONNative(const Provider : string) : Integer; stdcall; export;
var
  vJSONScenario: TJSONData;
  vJSONObject : TJSONObject;
  providername : string;
  providerinfo : string;
  providertype : string;
begin
  Writeln('Add provider from JSON is not implemented on linux yet... use Default Console and File Providers.');
  Result := 0;
  Exit;
  //TODO Implement Add providers from JSON and Linux
  vJSONScenario := GetJSON(Provider);
  if vJSONScenario = nil then Result := 0
  else
  begin
    try
      case vJSONScenario.JSONType of
        jtObject :
        begin
          vJSONObject := TJSONObject(vJSONScenario) as TJSONObject;
          if vJSONObject = nil then Result := Ord(False)
          else if vJSONObject.Get('providerType') = '' then Result := Ord(False)
          else if vJSONObject.Get('providerName') = '' then Result := Ord(False)
          else if vJSONObject.Get('providerInfo') = '' then Result := Ord(False)
          else
          begin
            providername := string(vJSONObject.Get('providerName')).Replace('"','');
            providerinfo := string(vJSONObject.Get('providerInfo')).Replace('"','');
            providertype := string(vJSONObject.Get('providerType')).Replace('"','');
            writeln('Adding provider ' + providername);
            InternalAddProviderFromJSON(providertype, providername, providerinfo);
            Result := Ord(True);
          end;
        end;
      end;
    finally
      vJSONScenario.Free;
    end;
  end;
end;

{$ENDIF}

function RemoveProviderNative(const Provider : string) : Integer; stdcall; export;
var
  providerHandler : TProviderEventHandler;
begin
  if not providerHandlers.TryGetValue(provider, providerHandler) then Result := Ord(False)
  else
  begin
    providerHandler.fprovider.Stop;
    Logger.Providers.Remove(providerHandler.fprovider);
    providerHandler.Free;
    Result := Ord(true);
  end;
end;

function AddStandardConsoleProviderNative : Integer; stdcall; export;
begin
  with GlobalLogConsoleProvider do
  begin
    LogLevel := LOG_ALL;
    UnderlineHeaderEventType := True;
    ShowEventColors := True;
    ShowTimeStamp := True;
    Enabled := True;
  end;
  Logger.Providers.Add(GlobalLogConsoleProvider);
  Result := Ord(True);
end;

function AddStandardFileProviderNative(const LogFilename : string) : Integer; stdcall; export;
begin
  with GlobalLogFileProvider do
  begin
    LogLevel := LOG_ALL;
    FileName := LogFilename;
    Enabled := True;
  end;
  Logger.Providers.Add(GlobalLogFileProvider);
  Result := Ord(True);
end;

procedure ResetProviderNative(const ProviderName : string); stdcall; export;
begin
  Writeln('ResetProvider is not implemented yet.');
end;

procedure InfoNative(const Line : string); stdcall; export;
begin
  Logger.Add(Line, Quick.Logger.TEventType.etInfo);
end;

procedure WarningNative(const Line : string); stdcall; export;
begin
  Logger.Add(Line, Quick.Logger.TEventType.etWarning);
end;

procedure ErrorNative(const Line : string); stdcall; export;
begin
  Logger.Add(Line, Quick.Logger.TEventType.etError);
end;

procedure CriticalNative(const Line : string); stdcall; export;
begin
  Logger.Add(Line, Quick.Logger.TEventType.etCritical);
end;

procedure TraceNative(const Line : string); stdcall; export;
begin
  Logger.Add(Line, Quick.Logger.TEventType.etCritical);
end;

procedure CustomNative(const Line : string); stdcall; export;
begin
  Logger.Add(Line, Quick.Logger.TEventType.etCustom1);
end;

procedure SuccessNative(const Line : string); stdcall; export;
begin
  Logger.Add(Line, Quick.Logger.etSuccess);
end;

procedure AddWrapperErrorDelegateNative(const ProviderName : string; Callback : TWrapperError); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    providerhandler.WrapperError := Callback;
  end;
end;

procedure AddWrapperFailDelegateNative(const ProviderName : string; Callback : TWrapperFailToLog); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    providerhandler.WrapperFailToLog := Callback;
  end;
end;

procedure AddWrapperStartDelegateNative(const ProviderName : string; Callback : TWrapperStart); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  Writeln('AddWrapperStart delegate native called ' + ProviderName);
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    Writeln('Provider handler is assigned and is ' + providerhandler.fproviderfriendlyname);
    if not Assigned(Callback) then Writeln('But passed callback pointer is nil');
    providerhandler.WrapperStart := Callback;
  end;
end;

procedure AddWrapperRestartDelegateNative(const ProviderName : string; Callback : TWrapperRestart); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    providerhandler.WrapperRestart := Callback;
  end;
end;

procedure AddWrapperQueueErrorDelegateNative(const ProviderName : string; Callback : TWrapperQueueError); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    providerhandler.WrapperQueueError := Callback;
  end;
end;

procedure AddWrapperCriticalErrorDelegateNative(const ProviderName : string; Callback : TWrapperCriticalError); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    providerhandler.WrapperCriticalError := Callback;
  end;
end;

procedure AddWrapperSendLimitsDelegateNative(const ProviderName : string; Callback : TWrapperSendLimits); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    providerhandler.WrapperSendLimits := Callback;
  end;
end;

procedure AddWrapperStatusChangedDelegateNative(const ProviderName : string; Callback : TWrapperStatusChanged); stdcall; export;
var
  providerhandler : TProviderEventHandler;
begin
  if providerHandlers.TryGetValue(providername, providerHandler) then
  begin
    providerhandler.WrapperStatusChanged := Callback;
  end;
end;

procedure TestCallbacksNative; stdcall; export;
var
  prov : TProviderEventHandler;
begin
  Writeln('TestCallBacksNativeCalled');
  for prov in providerHandlers.Values do
  begin
    Writeln('Providername ' + prov.fproviderfriendlyname);
    prov.TestCallbacks;
  end;
end;

function GetProviderNamesNative(out str: PChar): Integer; stdcall; export;
var
  vJSONScenario : TJSONArray;
  providername : string;
begin
  try
    with TJSONArray.Create do
    begin
      try
        for providername in QUICKLOGPROVIDERS do Add(providername);
        {$IFNDEF FPC}
          str := GetPChar(ToJSON);
        {$ELSE}
          str := GetPChar(AsJSON);
        {$ENDIF}
        Result := 1;
      finally
        Free;
      end;
    end;
  except
    on e : Exception do Writeln(e.Message);
  end;
end;

function GetLibVersionNative(out str: PChar): Integer; stdcall;
begin
  str := GetPChar('QuickLogger 1.29');
  Result := 1;
end;

{ TProviderEventHandler }

constructor TProviderEventHandler.Create(const FriendlyName : string; Provider: ILogProvider);
begin
  fprovider := provider;
  fproviderfriendlyname := FriendlyName;
  {$IFDEF FPC}
  TLogProviderBase(fprovider).OnFailToLog := ToWrapperError;
  TLogProviderBase(fprovider).OnRestart := ToWrapperRestart;
  TLogProviderBase(fprovider).OnQueueError := ToWrapperQueueError;
  TLogProviderBase(fprovider).OnCriticalError := ToWrapperCriticalError;
  TLogProviderBase(fprovider).OnStatusChanged := ToWrapperStatusChanged;
  TLogProviderBase(fprovider).OnSendLimits := ToWrapperSendLimits;
  {$ELSE}
  TLogProviderBase(fprovider).OnFailToLog := procedure(const providername : string)
  begin
    if Assigned(fwrapperfailtolog) then fwrapperfailtolog;
  end;
  TLogProviderBase(fprovider).OnRestart := procedure(const providername : string)
  begin
    if Assigned(fwrapperrestart) then fwrapperrestart;
  end;
  TLogProviderBase(fprovider).OnQueueError := procedure(const msg : string)
  begin
    if Assigned(fwrapperqueueerror) then fwrapperqueueerror(PChar(msg));
  end;
  TLogProviderBase(fprovider).OnCriticalError := procedure(const providername, msg : string)
  begin
    if Assigned(fwrappercriticalerror) then fwrappercriticalerror(PChar(msg));
  end;
  TLogProviderBase(fprovider).OnStatusChanged := procedure(providername : string; status : TLogProviderStatus)
  begin
    case status of
      psNone : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('None'));
      psStopped : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Stopped'));
      psInitializing : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Init'));
      psRunning : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Running'));
      psDraining : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Draining'));
      psStopping : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Stopping'));
      psRestarting : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Restarting'));
    end;
  end
  {$ENDIF}
end;

{$IFDEF FPC}

procedure TProviderEventHandler.TestCallbacks;
begin
  //
end;

procedure TProviderEventHandler.ToWrapperError(const msg: string);
begin
  if Assigned(fwrappererror) then fwrappererror(PChar(msg));
end;

procedure TProviderEventHandler.ToWrapperFailToLog(const aProviderName: string);
begin
  if Assigned(fwrapperfailtolog) then fwrapperfailtolog;
end;

procedure TProviderEventHandler.ToWrapperStart(const aProviderName: string);
begin
  if Assigned(fwrapperstart) then fwrapperstart(PChar(aProviderName));
end;

procedure TProviderEventHandler.ToWrapperQueueError(const msg: string);
begin
  if Assigned(fwrapperqueueerror) then fwrapperqueueerror(PChar(msg));
end;

procedure TProviderEventHandler.ToWrapperRestart(const aProviderName: string);
begin
  if Assigned(fwrapperrestart) then fwrapperrestart;
end;

procedure TProviderEventHandler.ToWrapperCriticalError(const aProviderName,
  ErrorMessage: string);
begin
  if Assigned(fwrappercriticalerror) then fwrappercriticalerror(PChar(ErrorMessage));
end;

procedure TProviderEventHandler.ToWrapperSendLimits(const aProviderName: string);
begin
  if Assigned(fwrappersendlimits) then fwrappersendlimits;
end;

procedure TProviderEventHandler.ToWrapperStatusChanged(aProviderName: string; status: TLogProviderStatus);
begin
  case status of
    psNone : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('None'));
    psStopped : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Stopped'));
    psInitializing : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Init'));
    psRunning : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Running'));
    psDraining : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Draining'));
    psStopping : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Stopping'));
    psRestarting : if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar('Restarting'));
  end;
end;


{$ELSE}

procedure TProviderEventHandler.TestCallbacks;
begin
  if Assigned(fwrapperstart) then fwrapperstart(PChar(fproviderfriendlyname + ' Native on start callback called'));
  if Assigned(fwraperstatuschanged) then fwraperstatuschanged(PChar(fproviderfriendlyname + ' Native onstatus changed callback called'));
  if Assigned(fwrappersendlimits) then fwrappersendlimits;
  if Assigned(fwrapperrestart) then fwrapperrestart;
  if Assigned(fwrapperqueueerror) then fwrapperqueueerror(PChar(fproviderfriendlyname + ' Native on queue error called'));
  if Assigned(fwrapperfailtolog) then fwrapperfailtolog;
  if Assigned(fwrappererror) then fwrappererror(PChar(fproviderfriendlyname + ' Native on error callback called'));
  if Assigned(fwrappercriticalerror) then fwrappercriticalerror(PChar(fproviderfriendlyname + ' Native on critical error callback called'));
end;

{$ENDIF}

exports
  AddProviderJSONNative,
  RemoveProviderNative,
  InfoNative,
  WarningNative,
  ErrorNative,
  CriticalNative,
  TraceNative,
  CustomNative,
  SuccessNative,
  AddStandardConsoleProviderNative,
  AddStandardFileProviderNative,
  AddWrapperErrorDelegateNative,
  AddWrapperFailDelegateNative,
  AddWrapperStartDelegateNative,
  AddWrapperRestartDelegateNative,
  AddWrapperQueueErrorDelegateNative,
  AddWrapperCriticalErrorDelegateNative,
  AddWrapperSendLimitsDelegateNative,
  AddWrapperStatusChangedDelegateNative,
  ResetProviderNative,
  GetProviderNamesNative,
  TestCallbacksNative,
  GetLibVersionNative;


begin
  providerHandlers := TDictionary<string,TProviderEventHandler>.Create;
  eventTypeConversion := TDictionary<string,TLogLevel>.Create;
  eventTypeConversion.Add('LOG_ONLYERRORS', LOG_ONLYERRORS);
  eventTypeConversion.Add('LOG_ERRORSANDWARNINGS', LOG_ONLYERRORS);
  eventTypeConversion.Add('LOG_BASIC', LOG_BASIC);
  eventTypeConversion.Add('LOG_ALL', LOG_ALL);
  eventTypeConversion.Add('LOG_TRACE', LOG_BASIC);
  eventTypeConversion.Add('LOG_DEBUG', LOG_DEBUG);
  eventTypeConversion.Add('LOG_VERBOSE', LOG_VERBOSE);
end.
