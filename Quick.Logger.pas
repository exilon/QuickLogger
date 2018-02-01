{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger
  Description : Threadsafe Multi Log File, Console, Email, etc...
  Author      : Kike Pérez
  Version     : 1.20
  Created     : 12/10/2017
  Modified    : 30/01/2018

  This file is part of QuickLogger: https://github.com/exilon/QuickLogger

  Needed libraries:
    QuickLib (https://github.com/exilon/QuickLib)

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

unit Quick.Logger;

{.$DEFINE LOGGER_DEBUG}

interface

uses
  Windows,
  Classes,
  System.Types,
  System.SysUtils,
  System.DateUtils,
  System.IOUtils,
  System.Generics.Collections,
  Quick.Commons;

type

  TEventType = (etHeader, etInfo, etSuccess, etWarning, etError, etCritical, etException, etDebug, etTrace, etCustom1, etCustom2);
  TLogLevel = set of TEventType;
  TEventTypeNames = array of string;

  ELogger = class(Exception);

const
  LOG_ONLYERRORS = [etHeader,etInfo,etError,etCritical,etException];
  LOG_ERRORSANDWARNINGS = [etHeader,etInfo,etWarning,etError,etCritical,etException];
  LOG_BASIC = [etInfo,etSuccess,etWarning,etError,etCritical,etException];
  LOG_ALL = [etHeader,etInfo,etSuccess,etWarning,etError,etCritical,etException,etCustom1,etCustom2];
  LOG_TRACE = [etHeader,etInfo,etSuccess,etWarning,etError,etCritical,etException,etTrace];
  LOG_DEBUG = [etHeader,etInfo,etSuccess,etWarning,etError,etCritical,etException,etTrace,etDebug];
  LOG_VERBOSE : TLogLevel = [Low(TEventType)..high(TEventType)];
  DEF_EVENTTYPENAMES : TEventTypeNames = ['','INFO','SUCC','WARN','ERROR','CRITICAL','EXCEPT','DEBUG','TRACE','CUST1','CUST2'];

  DEF_QUEUE_SIZE = 100000;
  DEF_QUEUE_PUSH_TIMEOUT = 1000;
  DEF_QUEUE_POP_TIMEOUT = 500;

type

  TLogProviderStatus = (psNone, psStopped, psInitializing, psRunning, psDraining, psStopping, psRestarting);

  TLogItem = class
  private
    fEventType : TEventType;
    fMsg : string;
    fEventDate : TDateTime;
  public
    constructor Create;
    property EventType : TEventType read fEventType write fEventType;
    property Msg : string read fMsg write fMsg;
    property EventDate : TDateTime read fEventDate write fEventDate;
    function EventTypeName : string;
    function Clone : TLogItem;
  end;

  TLogQueue = class(TThreadedQueue<TLogItem>);

  ILogProvider = interface
  ['{0E50EA1E-6B69-483F-986D-5128DA917ED8}']
    procedure Init;
    procedure Restart;
    //procedure Flush;
    procedure Stop;
    procedure Drain;
    procedure EnQueueItem(cLogItem : TLogItem);
    procedure WriteLog(cLogItem : TLogItem);
    function IsQueueable : Boolean;
    procedure IncAndCheckErrors;
    function Status : TLogProviderStatus;
    procedure SetStatus(cStatus : TLogProviderStatus);
    function IsSendLimitReached(cEventType : TEventType): Boolean;
  end;

  IRotable = interface
  ['{EF5E004F-C7BE-4431-8065-6081FEB3FC65}']
    procedure RotateLog;
  end;

  TThreadLog = class(TThread)
  private
    fLogQueue : TLogQueue;
    fProvider : ILogProvider;
  public
    constructor Create;
    destructor Destroy; override;
    property LogQueue : TLogQueue read fLogQueue write fLogQueue;
    property Provider : ILogProvider read fProvider write fProvider;
    procedure Execute; override;
  end;

  TSendLimitTimeRange = (slNoLimit, slByDay, slByHour, slByMinute, slBySecond);

  TLogSendLimit = class
  private
    fCurrentNumSent : Integer;
    fLastSent : TDateTime;
    fTimeRange : TSendLimitTimeRange;
    fLimitEventTypes : TLogLevel;
    fMaxSent: Integer;
  public
    constructor Create;
    property TimeRange : TSendLimitTimeRange read fTimeRange write fTimeRange;
    property LimitEventTypes : TLogLevel read fLimitEventTypes write fLimitEventTypes;
    property MaxSent : Integer read fMaxSent write fMaxSent;
    function IsLimitReached(cEventType : TEventType): Boolean;
  end;

  TQueueErrorEvent = procedure(const msg : string) of object;
  TFailToLogEvent = procedure of object;
  TRestartEvent = procedure of object;
  TCriticalErrorEvent = procedure of object;
  TSendLimitsEvent = procedure of object;
  TStatusChangedEvent = procedure(status : TLogProviderStatus) of object;

  TLogProviderBase = class(TInterfacedObject,ILogProvider)
  private
    fThreadLog : TThreadLog;
    fLogQueue : TLogQueue;
    fLogLevel : TLogLevel;
    fFormatSettings : TFormatSettings;
    fEnabled : Boolean;
    fTimePrecission : Boolean;
    fFails : Integer;
    fMaxFailsToRestart : Integer;
    fMaxFailsToStop : Integer;
    fUsesQueue : Boolean;
    fStatus : TLogProviderStatus;
    fEventTypeNames : TEventTypeNames;
    fSendLimits : TLogSendLimit;
    fOnFailToLog: TFailToLogEvent;
    fOnRestart: TRestartEvent;
    fOnCriticalError : TCriticalErrorEvent;
    fOnStatusChanged : TStatusChangedEvent;
    fOnQueueError: TQueueErrorEvent;
    fOnSendLimits: TSendLimitsEvent;
    procedure SetTimePrecission(Value : Boolean);
    procedure SetEnabled(aValue : Boolean);
    function GetQueuedLogItems : Integer;
    procedure EnQueueItem(cLogItem : TLogItem);
    function GetEventTypeName(cEventType : TEventType) : string;
    procedure SetEventTypeName(cEventType: TEventType; const cValue : string);
    function IsSendLimitReached(cEventType : TEventType): Boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Init; virtual;
    procedure Restart; virtual; abstract;
    procedure Stop;
    procedure Drain;
    procedure WriteLog(cLogItem : TLogItem); virtual; abstract;
    function IsQueueable : Boolean;
    property LogLevel : TLogLevel read fLogLevel write fLogLevel;
    property FormatSettings : TFormatSettings read fFormatSettings write fFormatSettings;
    property TimePrecission : Boolean read fTimePrecission write SetTimePrecission;
    property Fails : Integer read fFails write fFails;
    property MaxFailsToRestart : Integer read fMaxFailsToRestart write fMaxFailsToRestart;
    property MaxFailsToStop : Integer read fMaxFailsToStop write fMaxFailsToStop;
    property OnFailToLog : TFailToLogEvent read fOnFailToLog write fOnFailToLog;
    property OnRestart : TRestartEvent read fOnRestart write fOnRestart;
    property OnQueueError : TQueueErrorEvent read fOnQueueError write fOnQueueError;
    property OnCriticalError : TCriticalErrorEvent read fOnCriticalError write fOnCriticalError;
    property OnStatusChanged : TStatusChangedEvent read fOnStatusChanged write fOnStatusChanged;
    property OnSendLimits : TSendLimitsEvent read fOnSendLimits write fOnSendLimits;
    property QueueCount : Integer read GetQueuedLogItems;
    property UsesQueue : Boolean read fUsesQueue write fUsesQueue;
    property Enabled : Boolean read fEnabled write SetEnabled;
    property EventTypeName[cEventType : TEventType] : string read GetEventTypeName write SetEventTypeName;
    property SendLimits : TLogSendLimit read fSendLimits write fSendLimits;
    procedure IncAndCheckErrors;
    function Status : TLogProviderStatus;
    procedure SetStatus(cStatus : TLogProviderStatus);
  end;

  TLogProviderList = TList<ILogProvider>;

  TThreadProviderLog = class(TThread)
  private
    fLogQueue : TLogQueue;
    fProviders : TLogProviderList;
  public
    constructor Create;
    destructor Destroy; override;
    property LogQueue : TLogQueue read fLogQueue write fLogQueue;
    property Providers : TLogProviderList read fProviders write fProviders;
    procedure Execute; override;
  end;

  TLogger = class
  private
    fThreadProviderLog : TThreadProviderLog;
    fLogQueue : TLogQueue;
    fProviders : TLogProviderList;
    fOnQueueError: TQueueErrorEvent;
    function GetQueuedLogItems : Integer;
    procedure EnQueueItem(cEventDate : TSystemTime; const cMsg : string; cEventType : TEventType);
    procedure HandleException(E : Exception);
  public
    constructor Create;
    destructor Destroy; override;
    property Providers : TLogProviderList read fProviders write fProviders;
    property QueueCount : Integer read GetQueuedLogItems;
    property OnQueueError : TQueueErrorEvent read fOnQueueError write fOnQueueError;
    procedure Add(const cMsg : string; cEventType : TEventType); overload;
    procedure Add(const cMsg : string; cValues : array of TVarRec; cEventType : TEventType); overload;
  end;

  procedure Log(const cMsg : string; cEventType : TEventType); overload;
  procedure Log(const cMsg : string; cValues : array of TVarRec; cEventType : TEventType); overload;

var
  Logger : TLogger;
  GlobalLoggerHandleException : procedure(E : Exception) of object;

implementation


procedure Log(const cMsg : string; cEventType : TEventType); overload;
begin
  Logger.Add(cMsg,cEventType);
end;

procedure Log(const cMsg : string; cValues : array of TVarRec; cEventType : TEventType); overload;
begin
  Logger.Add(cMsg,cValues,cEventType);
end;


{ TLoggerProviderBase }

constructor TLogProviderBase.Create;
begin
  fFormatSettings.DateSeparator := '/';
  fFormatSettings.TimeSeparator := ':';
  fFormatSettings.ShortDateFormat := 'DD-MM-YYY HH:NN:SS';
  fFormatSettings.ShortTimeFormat := 'HH:NN:SS';
  fStatus := psNone;
  fTimePrecission := False;
  fSendLimits := TLogSendLimit.Create;
  fFails := 0;
  fMaxFailsToRestart := 2;
  fMaxFailsToStop := 10;
  fEnabled := False;
  fUsesQueue := True;
  fEventTypeNames := DEF_EVENTTYPENAMES;
  fLogQueue := TLogQueue.Create(DEF_QUEUE_SIZE,DEF_QUEUE_PUSH_TIMEOUT,DEF_QUEUE_POP_TIMEOUT);
end;

destructor TLogProviderBase.Destroy;
begin
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('destroy object: %s',[Self.ClassName]));
  {$ENDIF}
  if Assigned(fLogQueue) then fLogQueue.Free;
  if Assigned(fSendLimits) then fSendLimits.Free;

  inherited;
end;

procedure TLogProviderBase.Drain;
begin
  //no receive more logs
  fStatus := psDraining;
  fEnabled := False;
  while fLogQueue.QueueSize > 0 do
  begin
    fLogQueue.PopItem.Free;
  end;
  fStatus := psStopped;
end;

procedure TLogProviderBase.IncAndCheckErrors;
begin
  Inc(fFails);
  if Assigned(fOnFailToLog) then fOnFailToLog;

  if fFails > fMaxFailsToStop then
  begin
    //flush queue and stop provider from receiving new items
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('drain: %s (%d)',[Self.ClassName,fFails]));
    {$ENDIF}
    Drain;
    if Assigned(fOnCriticalError) then fOnCriticalError;
  end
  else if fFails > fMaxFailsToRestart then
  begin
    //try to restart provider
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('restart: %s (%d)',[Self.ClassName,fFails]));
    {$ENDIF}
    Restart;
    if Assigned(fOnRestart) then fOnRestart;

  end;
end;

function TLogProviderBase.Status : TLogProviderStatus;
begin
  Result := fStatus;
end;

procedure TLogProviderBase.Init;
begin
  if not(fStatus in [psNone,psStopped]) then Exit;
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('init thread: %s',[Self.ClassName]));
  {$ENDIF}
  fStatus := psInitializing;
  if fUsesQueue then
  begin
    fThreadLog := TThreadLog.Create;
    fThreadLog.LogQueue := fLogQueue;
    fThreadLog.Provider := Self;
    fThreadLog.Start;
  end;
end;

function TLogProviderBase.IsQueueable: Boolean;
begin
  Result := (fUsesQueue) and (Assigned(fThreadLog));
end;

function TLogProviderBase.IsSendLimitReached(cEventType : TEventType): Boolean;
begin
  Result := fSendLimits.IsLimitReached(cEventType);
  if Result and Assigned(fOnSendLimits) then fOnSendLimits;
end;

procedure TLogProviderBase.Stop;
begin
  if (fStatus = psStopped) or (fStatus = psStopping) then Exit;

  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('stopping thread: %s',[Self.ClassName]));
  {$ENDIF}
  fStatus := psStopping;
  if Assigned(fThreadLog) then
  begin
    fThreadLog.Terminate;
    fThreadLog.WaitFor;
    fThreadLog.Free;
  end;
  fStatus := psStopped;
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('stopped thread: %s',[Self.ClassName]));
  {$ENDIF}
end;

procedure TLogProviderBase.EnQueueItem(cLogItem : TLogItem);
begin
  if fLogQueue.PushItem(cLogItem) = TWaitResult.wrTimeout then
  begin
    FreeAndNil(cLogItem);
    if Assigned(fOnQueueError) then fOnQueueError(Format('Logger provider "%s" insertion timeout!',[Self.ClassName]));
    //raise ELogger.Create(Format('Logger provider "%s" insertion timeout!',[Self.ClassName]));
  end;
end;

function TLogProviderBase.GetEventTypeName(cEventType: TEventType): string;
begin
  Result := fEventTypeNames[Integer(cEventType)];
end;

procedure TLogProviderBase.SetEventTypeName(cEventType: TEventType; const cValue : string);
begin
  fEventTypeNames[Integer(cEventType)] := cValue;
end;

function TLogProviderBase.GetQueuedLogItems: Integer;
begin
  Result := fLogQueue.QueueSize;
end;

procedure TLogProviderBase.SetEnabled(aValue: Boolean);
begin
  if (aValue <> fEnabled) then
  begin
    fEnabled := aValue;
    if aValue then Init
      else Stop;
  end;
end;

procedure TLogProviderBase.SetStatus(cStatus: TLogProviderStatus);
begin
  fStatus := cStatus;
  if Assigned(fOnStatusChanged) then fOnStatusChanged(cStatus);
end;

procedure TLogProviderBase.SetTimePrecission(Value: Boolean);
begin
  fTimePrecission := Value;
  if fTimePrecission then fFormatSettings.ShortDateFormat := StringReplace(fFormatSettings.ShortDateFormat,'HH:NN:SS','HH:NN:SS:ZZZ',[rfIgnoreCase])
    else if fFormatSettings.ShortDateFormat.Contains('ZZZ') then fFormatSettings.ShortDateFormat := StringReplace(fFormatSettings.ShortDateFormat,'HH:NN:SS:ZZZ','HH:NN:SS',[rfIgnoreCase]);
end;

{ TThreadLog }

constructor TThreadLog.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
end;

destructor TThreadLog.Destroy;
begin
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('destroy thread: %s',[TLogProviderBase(fProvider).ClassName]));
  {$ENDIF}
  fProvider := nil;
  inherited;
end;

procedure TThreadLog.Execute;
var
  logitem : TLogItem;
  qSize : Integer;
begin
  //call interface provider to writelog
  fProvider.SetStatus(psRunning);
  while (not Terminated) or (fLogQueue.QueueSize > 0) do
  begin
    if fLogQueue.PopItem(qSize,logitem) = TWaitResult.wrSignaled then
    begin
      if logitem <> nil then
      begin
        try
          try
            if fProvider.Status = psRunning then
            begin
              //Writelog if not Send limitable or not limit reached
              if not fProvider.IsSendLimitReached(logitem.EventType) then fProvider.WriteLog(logitem);
            end;
          except
            {$IFDEF LOGGER_DEBUG}
            Writeln(Format('fail: %s (%d)',[TLogProviderBase(fProvider).ClassName,TLogProviderBase(fProvider).Fails + 1]));
            {$ENDIF}
            //check if there are many errors and needs to restart or stop provider
            if not Terminated then fProvider.IncAndCheckErrors;
          end;
        finally
          logitem.Free;
        end;
      end;
    end;
  end;
  //fProvider := nil;
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('terminate thread: %s',[TLogProviderBase(fProvider).ClassName]));
  {$ENDIF}
end;


{ TThreadProviderLog }

constructor TThreadProviderLog.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
end;

destructor TThreadProviderLog.Destroy;
var
  IProvider : ILogProvider;
begin
  //finalizes main queue
  if Assigned(fLogQueue) then fLogQueue.Free;
  //release providers
  if Assigned(fProviders) then
  begin
    for IProvider in fProviders do IProvider.Stop;
    IProvider := nil;
    fProviders.Free;
  end;
  inherited;
end;

procedure TThreadProviderLog.Execute;
var
  provider : ILogProvider;
  logitem : TLogItem;
  qSize : Integer;
begin
  //send log items to all providers
  while (not Terminated) or (fLogQueue.QueueSize > 0) do
  begin
    try
      if fLogQueue.PopItem(qSize,logitem) = TWaitResult.wrSignaled then
      begin
        if logitem <> nil then
        begin
          //send log item to all providers
          try
            for provider in fProviders do
            begin
              //send LogItem to provider if Provider Enabled and accepts LogLevel
              if (TLogProviderBase(provider).Enabled)
                  and (logitem.EventType in TLogProviderBase(provider).LogLevel) then
              begin
                if provider.IsQueueable then provider.EnQueueItem(logitem.Clone)
                else
                begin
                  try
                    provider.WriteLog(logitem);
                  except
                    {$IFDEF LOGGER_DEBUG}
                    Writeln(Format('fail: %s (%d)',[TLogProviderBase(provider).ClassName,TLogProviderBase(provider).Fails + 1]));
                    {$ENDIF}
                    //try to restart provider
                    if not Terminated then TLogProviderBase(provider).IncAndCheckErrors;
                  end;
                end;
              end;
            end;
          finally
            logitem.Free;
            provider := nil;
          end;
        end;
      end;
    except
      on E : Exception do
      begin
        //if e.ClassType <> EMonitorLockException then  raise ELogger.Create(Format('Error reading Queue Log : %s',[e.Message]));
      end;
    end;
  end;
end;


{ TLogItem }

constructor TLogItem.Create;
begin
  inherited;
  fEventDate := Now();
  fEventType := TEventType.etInfo;
  fMsg := '';
end;

function TLogItem.EventTypeName : string;
begin
  Result := DEF_EVENTTYPENAMES[Integer(fEventType)];
end;

function TLogItem.Clone : TLogItem;
begin
  Result := TLogItem.Create;
  Result.EventType := Self.EventType;
  Result.EventDate := Self.EventDate;
  Result.Msg := Self.Msg;
end;


{ TLogger }

constructor TLogger.Create;
begin
  inherited;
  GlobalLoggerHandleException := HandleException;
  fLogQueue := TLogQueue.Create(DEF_QUEUE_SIZE,DEF_QUEUE_PUSH_TIMEOUT,DEF_QUEUE_POP_TIMEOUT);
  fProviders := TLogProviderList.Create;
  fThreadProviderLog := TThreadProviderLog.Create;
  fThreadProviderLog.LogQueue := fLogQueue;
  fThreadProviderLog.Providers := fProviders;
  fThreadProviderLog.Start;
end;

destructor TLogger.Destroy;
var
  FinishTime : TDateTime;
begin
  GlobalLoggerHandleException := nil;
  //wait for log queue finalization
  FinishTime := Now();
  repeat
    Sleep(1);
  until (fThreadProviderLog.LogQueue.QueueSize = 0) or (SecondsBetween(Now(),FinishTime) > 60);
  //finalize queue thread
  fThreadProviderLog.Terminate;
  fThreadProviderLog.WaitFor;
  fThreadProviderLog.Free;
  //Sleep(1500);
  inherited;
end;

function TLogger.GetQueuedLogItems : Integer;
begin
  Result := fLogQueue.QueueSize;
end;

procedure TLogger.Add(const cMsg : string; cEventType : TEventType);
var
  SystemTime : TSystemTime;
begin
  GetLocalTime(SystemTime);
  Self.EnQueueItem(SystemTime,cMsg,cEventType);
end;

procedure TLogger.Add(const cMsg : string; cValues : array of TVarRec; cEventType : TEventType);
var
  SystemTime : TSystemTime;
begin
  GetLocalTime(SystemTime);
  Self.EnQueueItem(SystemTime,Format(cMsg,cValues),cEventType);
end;

procedure TLogger.EnQueueItem(cEventDate : TSystemTime; const cMsg : string; cEventType : TEventType);
var
  logitem : TLogItem;
begin
  logitem := TLogItem.Create;
  logitem.EventType := cEventType;
  logitem.Msg := cMsg;
  logitem.EventDate := SystemTimeToDateTime(cEventDate);
  if fLogQueue.PushItem(logitem) = TWaitResult.wrTimeout then
  begin
    FreeAndNil(logitem);
    if Assigned(fOnQueueError) then fOnQueueError('Logger insertion timeout!');
    //raise ELogger.Create('Logger insertion timeout!');
  end;
end;

procedure TLogger.HandleException(E : Exception);
var
  SystemTime : TSystemTime;
begin
  GetLocalTime(SystemTime);
  Self.EnQueueItem(SystemTime,Format('(%s) : %s',[E.ClassName,E.Message]),etException);
end;

{ TLogSendLimit }

constructor TLogSendLimit.Create;
begin
  inherited;
  fTimeRange := slNoLimit;
  fMaxSent := 0;
  fLastSent := 0;
  fCurrentNumSent := 0;
end;

function TLogSendLimit.IsLimitReached(cEventType : TEventType): Boolean;
begin
  //check sent number in range
  if (fTimeRange = slNoLimit) or (not (cEventType in fLimitEventTypes)) then
  begin
    Result := False;
    Exit;
  end;
  if fCurrentNumSent > 0 then
  begin
    case fTimeRange of
      slByDay : if HoursBetween(Now(),fLastSent) > 24 then fCurrentNumSent := 0;
      slByHour : if MinutesBetween(Now(),fLastSent) > 60 then fCurrentNumSent := 0;
      slByMinute : if SecondsBetween(Now(),fLastSent) > 60 then fCurrentNumSent := 0;
      slBySecond : if MilliSecondsBetween(Now(),fLastSent) > 999 then fCurrentNumSent := 0;
    end;
  end;
  if fCurrentNumSent > fMaxSent then Result := True
  else
  begin
    Inc(fCurrentNumSent);
    Result := False;
  end;
  fLastSent := Now();
end;

initialization
  Logger := TLogger.Create;


finalization
  Logger.Free;

end.
