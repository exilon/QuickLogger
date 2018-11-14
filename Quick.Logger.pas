{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger
  Description : Threadsafe Multi Log File, Console, Email, etc...
  Author      : Kike Pérez
  Version     : 1.30
  Created     : 12/10/2017
  Modified    : 17/09/2018

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

{$i QuickLib.inc}

{.$DEFINE LOGGER_DEBUG}
{.$DEFINE LOGGER_DEBUG2}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
    {$IFDEF DELPHIXE8_UP}
    Quick.Json.Serializer,
    {$ENDIF}
    {$IFDEF DELPHIXE7_UP}
    {$ELSE}
    SyncObjs,
    {$ENDIF}
  {$ENDIF}
  {$IF Defined(DELPHITOKYO_UP) AND Defined(LINUX)}
  Quick.Json.Serializer,
  {$ENDIF}
  Classes,
  Types,
  SysUtils,
  DateUtils,
  {$IFDEF FPC}
  fpjson,
  fpjsonrtti,
    {$IFDEF LINUX}
    SyncObjs,
    {$ENDIF}
  Quick.Files,
  Generics.Collections,
  {$ELSE}
  System.IOUtils,
  System.Generics.Collections,
    {$IFDEF DELPHIXE8_UP}
    System.JSON,
    {$ELSE}
    Data.DBXJSON,
    {$ENDIF}
  {$ENDIF}
  Quick.Threads,
  Quick.Commons,
  Quick.SysInfo;

const
  QLVERSION = '1.28';

type

  TEventType = (etHeader, etInfo, etSuccess, etWarning, etError, etCritical, etException, etDebug, etTrace, etDone, etCustom1, etCustom2);
  TLogLevel = set of TEventType;
  {$IFDEF DELPHIXE7_UP}
  TEventTypeNames = array of string;
  {$ELSE}
  TEventTypeNames = array[0..11] of string;
  {$ENDIF}

  ELogger = class(Exception);

const
  LOG_ONLYERRORS = [etHeader,etInfo,etError,etCritical,etException];
  LOG_ERRORSANDWARNINGS = [etHeader,etInfo,etWarning,etError,etCritical,etException];
  LOG_BASIC = [etInfo,etSuccess,etWarning,etError,etCritical,etException];
  LOG_ALL = [etHeader,etInfo,etSuccess,etDone,etWarning,etError,etCritical,etException,etCustom1,etCustom2];
  LOG_TRACE = [etHeader,etInfo,etSuccess,etDone,etWarning,etError,etCritical,etException,etTrace];
  LOG_DEBUG = [etHeader,etInfo,etSuccess,etDone,etWarning,etError,etCritical,etException,etTrace,etDebug];
  LOG_VERBOSE : TLogLevel = [Low(TEventType)..high(TEventType)];
  {$IFDEF DELPHIXE7_UP}
  DEF_EVENTTYPENAMES : TEventTypeNames = ['','INFO','SUCC','WARN','ERROR','CRITICAL','EXCEPT','DEBUG','TRACE','DONE','CUST1','CUST2'];
  {$ELSE}
  DEF_EVENTTYPENAMES : TEventTypeNames = ('','INFO','SUCC','WARN','ERROR','CRITICAL','EXCEPT','DEBUG','TRACE','DONE','CUST1','CUST2');
  {$ENDIF}
  HTMBR = '<BR>';
  DEF_QUEUE_SIZE = 10;
  DEF_QUEUE_PUSH_TIMEOUT = 1500;
  DEF_QUEUE_POP_TIMEOUT = 200;
  DEF_WAIT_FLUSH_LOG = 30;
  DEF_USER_AGENT = 'Quick.Logger Agent';

type

  TLogProviderStatus = (psNone, psStopped, psInitializing, psRunning, psDraining, psStopping, psRestarting);

  {$IFNDEF FPC}
    {$IF Defined(ANDROID) OR Defined(LINUX)}
    TSystemTime = TDateTime;
    {$ENDIF}
  {$ENDIF}

  TLogInfoField = (iiAppName, iiHost, iiUserName, iiEnvironment, iiPlatform, iiOSVersion);

  TIncludedLogInfo = set of TLogInfoField;

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

  TLogQueue = class(TThreadedQueueList<TLogItem>);

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
    function GetLogLevel : TLogLevel;
    function IsEnabled : Boolean;
    function GetVersion : string;
    function GetName : string;
    {$IFDEF DELPHIXE8_UP}
    {$IFNDEF ANDROID}
    function ToJson : string;
    procedure FromJson(const aJson : string);
    {$ENDIF}
    {$ENDIF}
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
    fFirstSent : TDateTime;
    fLastSent : TDateTime;
    fTimeRange : TSendLimitTimeRange;
    fLimitEventTypes : TLogLevel;
    fNumBlocked : Int64;
    fMaxSent: Integer;
  public
    constructor Create;
    property TimeRange : TSendLimitTimeRange read fTimeRange write fTimeRange;
    property LimitEventTypes : TLogLevel read fLimitEventTypes write fLimitEventTypes;
    property MaxSent : Integer read fMaxSent write fMaxSent;
    function IsLimitReached(cEventType : TEventType): Boolean;
  end;

  {$IFDEF FPC}
  TQueueErrorEvent = procedure(const msg : string) of object;
  TFailToLogEvent = procedure(const aProviderName : string) of object;
  TStartEvent = procedure(const aProviderName : string) of object;
  TRestartEvent = procedure(const aProviderName : string) of object;
  TCriticalErrorEvent = procedure(const aProviderName, ErrorMessage : string) of object;
  TSendLimitsEvent = procedure(const aProviderName : string) of object;
  TStatusChangedEvent = procedure(aProviderName : string; status : TLogProviderStatus) of object;
  {$ELSE}
  TQueueErrorEvent = reference to procedure(const msg : string);
  TFailToLogEvent = reference to procedure(const aProviderName : string);
  TStartEvent = reference to procedure(const aProviderName : string);
  TRestartEvent = reference to procedure(const aProviderName : string);
  TCriticalErrorEvent = reference to procedure(const aProviderName, ErrorMessage : string);
  TSendLimitsEvent = reference to procedure(const aProviderName : string);
  TStatusChangedEvent = reference to procedure(aProviderName : string; status : TLogProviderStatus);
  {$ENDIF}

  TLogProviderBase = class(TInterfacedObject,ILogProvider)
  protected
    fThreadLog : TThreadLog;
  private
    fName : string;
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
    fAppName : string;
    fEnvironment : string;
    fPlatformInfo : string;
    fEventTypeNames : TEventTypeNames;
    fSendLimits : TLogSendLimit;
    fOnFailToLog: TFailToLogEvent;
    fOnRestart: TRestartEvent;
    fOnCriticalError : TCriticalErrorEvent;
    fOnStatusChanged : TStatusChangedEvent;
    fOnQueueError: TQueueErrorEvent;
    fOnSendLimits: TSendLimitsEvent;
    fIncludedInfo : TIncludedLogInfo;
    fSystemInfo : TSystemInfo;
    fCustomMsgOutput : Boolean;
    procedure SetTimePrecission(Value : Boolean);
    procedure SetEnabled(aValue : Boolean);
    function GetQueuedLogItems : Integer;
    procedure EnQueueItem(cLogItem : TLogItem);
    function GetEventTypeName(cEventType : TEventType) : string;
    procedure SetEventTypeName(cEventType: TEventType; const cValue : string);
    function IsSendLimitReached(cEventType : TEventType): Boolean;
  protected
    function LogItemToJsonObject(cLogItem: TLogItem): TJSONObject; overload;
    function LogItemToJson(cLogItem : TLogItem) : string; overload;
    function LogItemToHtml(cLogItem: TLogItem): string;
    function LogItemToText(cLogItem: TLogItem): string;
    procedure IncAndCheckErrors;
    procedure SetStatus(cStatus : TLogProviderStatus);
    function GetLogLevel : TLogLevel;
    property SystemInfo : TSystemInfo read fSystemInfo;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Init; virtual;
    procedure Restart; virtual; abstract;
    procedure Stop;
    procedure Drain;
    procedure WriteLog(cLogItem : TLogItem); virtual; abstract;
    function IsQueueable : Boolean;
    property Name : string read fName write fName;
    property LogLevel : TLogLevel read fLogLevel write fLogLevel;
    {$IFDEF DELPHIXE7_UP}[TNotSerializableProperty]{$ENDIF}
    property FormatSettings : TFormatSettings read fFormatSettings write fFormatSettings;
    property TimePrecission : Boolean read fTimePrecission write SetTimePrecission;
    {$IFDEF DELPHIXE7_UP}[TNotSerializableProperty]{$ENDIF}
    property Fails : Integer read fFails write fFails;
    property MaxFailsToRestart : Integer read fMaxFailsToRestart write fMaxFailsToRestart;
    property MaxFailsToStop : Integer read fMaxFailsToStop write fMaxFailsToStop;
    property CustomMsgOutput : Boolean read fCustomMsgOutput write fCustomMsgOutput;
    property OnFailToLog : TFailToLogEvent read fOnFailToLog write fOnFailToLog;
    property OnRestart : TRestartEvent read fOnRestart write fOnRestart;
    property OnQueueError : TQueueErrorEvent read fOnQueueError write fOnQueueError;
    property OnCriticalError : TCriticalErrorEvent read fOnCriticalError write fOnCriticalError;
    property OnStatusChanged : TStatusChangedEvent read fOnStatusChanged write fOnStatusChanged;
    property OnSendLimits : TSendLimitsEvent read fOnSendLimits write fOnSendLimits;
    {$IFDEF DELPHIXE7_UP}[TNotSerializableProperty]{$ENDIF}
    property QueueCount : Integer read GetQueuedLogItems;
    property UsesQueue : Boolean read fUsesQueue write fUsesQueue;
    property Enabled : Boolean read fEnabled write SetEnabled;
    property EventTypeName[cEventType : TEventType] : string read GetEventTypeName write SetEventTypeName;
    property SendLimits : TLogSendLimit read fSendLimits write fSendLimits;
    property AppName : string read fAppName write fAppName;
    property Environment : string read fEnvironment write fEnvironment;
    property PlatformInfo : string read fPlatformInfo write fPlatformInfo;
    property IncludedInfo : TIncludedLogInfo read fIncludedInfo write fIncludedInfo;
    function Status : TLogProviderStatus;
    function StatusAsString : string; overload;
    class function StatusAsString(cStatus : TLogProviderStatus) : string; overload;
    function GetVersion : string;
    function IsEnabled : Boolean;
    function GetName : string;
    {$IFDEF DELPHIXE8_UP}
    {$IFNDEF ANDROID}
    function ToJson : string;
    procedure FromJson(const aJson : string);
    {$ENDIF}
    {$ENDIF}
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
    fWaitForFlushBeforeExit : Integer;
    fOnQueueError: TQueueErrorEvent;
    function GetQueuedLogItems : Integer;
    procedure EnQueueItem(cEventDate : TSystemTime; const cMsg : string; cEventType : TEventType);
    procedure HandleException(E : Exception);
  public
    constructor Create;
    destructor Destroy; override;
    property Providers : TLogProviderList read fProviders write fProviders;
    property WaitForFlushBeforeExit : Integer read fWaitForFlushBeforeExit write fWaitForFlushBeforeExit;
    property QueueCount : Integer read GetQueuedLogItems;
    property OnQueueError : TQueueErrorEvent read fOnQueueError write fOnQueueError;
    procedure Add(const cMsg : string; cEventType : TEventType); overload;
    procedure Add(const cMsg : string; cValues : array of {$IFDEF FPC}const{$ELSE}TVarRec{$ENDIF}; cEventType : TEventType); overload;
  end;

  procedure Log(const cMsg : string; cEventType : TEventType); overload;
  procedure Log(const cMsg : string; cValues : array of {$IFDEF FPC}const{$ELSE}TVarRec{$ENDIF}; cEventType : TEventType); overload;

var
  Logger : TLogger;
  GlobalLoggerHandleException : procedure(E : Exception) of object;

implementation


{$IFNDEF MSWINDOWS}
procedure GetLocalTime(var vlocaltime : TDateTime);
begin
  vlocaltime := Now();
end;
{$ENDIF}


procedure Log(const cMsg : string; cEventType : TEventType); overload;
begin
  Logger.Add(cMsg,cEventType);
end;

procedure Log(const cMsg : string; cValues : array of {$IFDEF FPC}const{$ELSE}TVarRec{$ENDIF}; cEventType : TEventType); overload;
begin
  Logger.Add(cMsg,cValues,cEventType);
end;


{ TLoggerProviderBase }

constructor TLogProviderBase.Create;
begin
  fName := Self.ClassName;
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
  fEnvironment := '';
  fPlatformInfo := '';
  fIncludedInfo := [iiAppName,iiHost];
  fSystemInfo := Quick.SysInfo.SystemInfo;
  fAppName := fSystemInfo.AppName;
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
  SetStatus(TLogProviderStatus.psDraining);
  fEnabled := False;
  while fLogQueue.QueueSize > 0 do
  begin
    fLogQueue.PopItem.Free;
    Sleep(0);
  end;
  SetStatus(TLogProviderStatus.psStopped);
end;

procedure TLogProviderBase.IncAndCheckErrors;
begin
  Inc(fFails);
  if Assigned(fOnFailToLog) then fOnFailToLog(fName);

  if (fMaxFailsToStop > 0) and (fFails > fMaxFailsToStop) then
  begin
    //flush queue and stop provider from receiving new items
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('drain: %s (%d)',[Self.ClassName,fFails]));
    {$ENDIF}
    Drain;
    if Assigned(fOnCriticalError) then fOnCriticalError(fName,'Max fails to Stop reached!');
  end
  else if fFails > fMaxFailsToRestart then
  begin
    //try to restart provider
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('restart: %s (%d)',[Self.ClassName,fFails]));
    {$ENDIF}
    Restart;
    SetStatus(TLogProviderStatus.psRestarting);
    if Assigned(fOnRestart) then fOnRestart(fName);
  end;
end;

function TLogProviderBase.Status : TLogProviderStatus;
begin
  Result := fStatus;
end;

function TLogProviderBase.StatusAsString : string;
begin
  Result := StatusAsString(fStatus);
end;

class function TLogProviderBase.StatusAsString(cStatus : TLogProviderStatus) : string;
const
  {$IFDEF DELPHIXE7_UP}
  LogProviderStatusStr : array of string = ['Nothing','Stopped','Initializing','Running','Draining','Stopping','Restarting'];
  {$ELSE}
  LogProviderStatusStr : array[0..6] of string = ('Nothing','Stopped','Initializing','Running','Draining','Stopping','Restarting');
  {$ENDIF}
begin
  Result := LogProviderStatusStr[Integer(cStatus)];
end;


procedure TLogProviderBase.Init;
begin
  if not(fStatus in [psNone,psStopped]) then Exit;
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('init thread: %s',[Self.ClassName]));
  {$ENDIF}
  SetStatus(TLogProviderStatus.psInitializing);
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
  if Result and Assigned(fOnSendLimits) then fOnSendLimits(fName);
end;

function TLogProviderBase.LogItemToJsonObject(cLogItem: TLogItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('timestamp', DateTimeToGMT(cLogItem.EventDate));
  Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('type',EventTypeName[cLogItem.EventType]);
  if iiHost in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('host',SystemInfo.HostName);
  if iiAppName in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('application',fAppName);
  if iiEnvironment in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('environment',fEnvironment);
  if iiPlatform in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('platform',fPlatformInfo);
  if iiOSVersion in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('OS',SystemInfo.OSVersion);
  if iiUserName in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('user',SystemInfo.UserName);
  Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('message',cLogItem.Msg);
  Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('level',Integer(cLogItem.EventType).ToString);
end;

function TLogProviderBase.LogItemToJson(cLogItem: TLogItem): string;
var
  json : TJSONObject;
begin
  json := LogItemToJsonObject(cLogItem);
  try
    {$IFDEF DELPHIXE8_UP}
    Result := json.ToJSON
    {$ELSE}
      {$IFDEF FPC}
      Result := json.AsJSON;
      {$ELSE}
      Result := json.ToString;
      {$ENDIF}
    {$ENDIF}
  finally
    json.Free;
  end;
end;

function TLogProviderBase.LogItemToHtml(cLogItem: TLogItem): string;
var
  msg : TStringList;
begin
  msg := TStringList.Create;
  try
    msg.Add(Format('<B>EventDate:</B> %s%s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),HTMBR]));
    msg.Add(Format('<B>Type:</B> %s%s',[EventTypeName[cLogItem.EventType],HTMBR]));
    if iiAppName in IncludedInfo then msg.Add(Format('<B>Application:</B> %s%s',[SystemInfo.AppName,HTMBR]));
    if iiHost in IncludedInfo then msg.Add(Format('<B>Host:</B> %s%s ',[SystemInfo.HostName,HTMBR]));
    if iiUserName in IncludedInfo then msg.Add(Format('<B>User:</B> %s%s',[SystemInfo.UserName,HTMBR]));
    if iiOSVersion in IncludedInfo then msg.Add(Format('<B>OS:</B> %s%s',[SystemInfo.OsVersion,HTMBR]));
    if iiEnvironment in IncludedInfo then msg.Add(Format('<B>Environment:</B> %s%s',[Environment,HTMBR]));
    if iiPlatform in IncludedInfo then msg.Add(Format('<B>Platform:</B> %s%s',[PlatformInfo,HTMBR]));
    msg.Add(Format('<B>Message:</B> %s%s',[cLogItem.Msg,HTMBR]));
    Result := msg.Text;
  finally
    msg.Free;
  end;
end;

function TLogProviderBase.LogItemToText(cLogItem: TLogItem): string;
var
  msg : TStringList;
begin
  msg := TStringList.Create;
  try
    msg.Add(Format('EventDate: %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings)]));
    msg.Add(Format('Type: %s',[EventTypeName[cLogItem.EventType]]));
    if iiAppName in IncludedInfo then msg.Add(Format('Application: %s',[SystemInfo.AppName]));
    if iiHost in IncludedInfo then msg.Add(Format('Host: %s',[SystemInfo.HostName]));
    if iiUserName in IncludedInfo then msg.Add(Format('User: %s',[SystemInfo.UserName]));
    if iiOSVersion in IncludedInfo then msg.Add(Format('OS: %s',[SystemInfo.OsVersion]));
    if iiEnvironment in IncludedInfo then msg.Add(Format('Environment: %s',[Environment]));
    if iiPlatform in IncludedInfo then msg.Add(Format('Platform: %s',[PlatformInfo]));
    msg.Add(Format('Message: %s',[cLogItem.Msg]));
    Result := msg.Text;
  finally
    msg.Free;
  end;
end;

procedure TLogProviderBase.Stop;
begin
  if (fStatus = psStopped) or (fStatus = psStopping) then Exit;

  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('stopping thread: %s',[Self.ClassName]));
  {$ENDIF}
  SetStatus(TLogProviderStatus.psStopping);
  if Assigned(fThreadLog) then
  begin
    fThreadLog.Terminate;
    fThreadLog.WaitFor;
    fThreadLog.Free;
  end;
  SetStatus(TLogProviderStatus.psStopped);
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('stopped thread: %s',[Self.ClassName]));
  {$ENDIF}
end;

{$IFDEF DELPHIXE8_UP}
  {$IFNDEF ANDROID}
  function TLogProviderBase.ToJson: string;
  var
    serializer : TJsonSerializer;
  begin
    serializer := TJsonSerializer.Create(slPublicProperty);
    try
      Result := serializer.ObjectToJson(Self);
    finally
      serializer.Free;
    end;
  end;

  procedure TLogProviderBase.FromJson(const aJson: string);
  var
    serializer : TJsonSerializer;
  begin
    serializer := TJsonSerializer.Create(slPublicProperty);
    try
      Self := TLogProviderBase(serializer.JsonToObject(Self,aJson));
    finally
      serializer.Free;
    end;
  end;
  {$ENDIF}
{$ENDIF}

procedure TLogProviderBase.EnQueueItem(cLogItem : TLogItem);
begin
  if fLogQueue.PushItem(cLogItem) <> TWaitResult.wrSignaled then
  begin
    FreeAndNil(cLogItem);
    if Assigned(fOnQueueError) then fOnQueueError(Format('Logger provider "%s" insertion timeout!',[Self.ClassName]));
    //raise ELogger.Create(Format('Logger provider "%s" insertion timeout!',[Self.ClassName]));
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('insertion timeout: %s',[Self.ClassName]));
    {$ENDIF}
  {$IFDEF LOGGER_DEBUG2}
  end else Writeln(Format('pushitem %s (queue: %d): %s',[Self.ClassName,fLogQueue.QueueSize,cLogItem.fMsg]));
  {$ELSE}
  end;
  {$ENDIF}
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

function TLogProviderBase.GetVersion: string;
begin
  Result := QLVERSION;
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
  if Assigned(OnStatusChanged) then OnStatusChanged(fName,cStatus);
end;

procedure TLogProviderBase.SetTimePrecission(Value: Boolean);
begin
  fTimePrecission := Value;
  if fTimePrecission then fFormatSettings.ShortDateFormat := StringReplace(fFormatSettings.ShortDateFormat,'HH:NN:SS','HH:NN:SS.ZZZ',[rfIgnoreCase])
    else if fFormatSettings.ShortDateFormat.Contains('ZZZ') then fFormatSettings.ShortDateFormat := StringReplace(fFormatSettings.ShortDateFormat,'HH:NN:SS.ZZZ','HH:NN:SS',[rfIgnoreCase]);
end;

function TLogProviderBase.GetLogLevel : TLogLevel;
begin
  Result := fLogLevel;
end;

function TLogProviderBase.GetName: string;
begin
  Result := fName;
end;

function TLogProviderBase.IsEnabled : Boolean;
begin
  Result := fEnabled;
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
      {$IFDEF LOGGER_DEBUG2}
      Writeln(Format('popitem logger: %s',[logitem.Msg]));
      {$ENDIF}
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
    {$IFDEF DELPHIXE7_UP}
    {$ELSE}
      {$IFNDEF LINUX}
      ProcessMessages;
      {$ENDIF}
    {$ENDIF}
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
          {$IFDEF LOGGER_DEBUG2}
          Writeln(Format('popitem %s: %s',[Self.ClassName,logitem.Msg]));
          {$ENDIF}
          try
            for provider in fProviders do
            begin
              //send LogItem to provider if Provider Enabled and accepts LogLevel
              if (provider.IsEnabled) and (logitem.EventType in provider.GetLogLevel) then
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
                    if not Terminated then provider.IncAndCheckErrors;
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
      {$IFDEF DELPHIXE7_UP}
      {$ELSE}
        {$IFNDEF LINUX}
        ProcessMessages;
        {$ENDIF}
      {$ENDIF}
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
  fWaitForFlushBeforeExit := DEF_WAIT_FLUSH_LOG;
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
    Sleep(0);
  until (fThreadProviderLog.LogQueue.QueueSize = 0) or (SecondsBetween(Now(),FinishTime) > fWaitForFlushBeforeExit);
  //finalize queue thread
  fThreadProviderLog.Terminate;
  fThreadProviderLog.WaitFor;
  fThreadProviderLog.Free;
  //if Assigned(fProviders) then fProviders.Free;

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
  {$IFDEF FPCLINUX}
  DateTimeToSystemTime(Now(),SystemTime);
  {$ELSE}
  GetLocalTime(SystemTime);
  {$ENDIF}
  Self.EnQueueItem(SystemTime,cMsg,cEventType);
end;

procedure TLogger.Add(const cMsg : string; cValues : array of {$IFDEF FPC}const{$ELSE}TVarRec{$ENDIF}; cEventType : TEventType);
var
  SystemTime : TSystemTime;
begin
  {$IFDEF FPCLINUX}
  DateTimeToSystemTime(Now(),SystemTime);
  {$ELSE}
  GetLocalTime(SystemTime);
  {$ENDIF}
  Self.EnQueueItem(SystemTime,Format(cMsg,cValues),cEventType);
end;

procedure TLogger.EnQueueItem(cEventDate : TSystemTime; const cMsg : string; cEventType : TEventType);
var
  logitem : TLogItem;
begin
  logitem := TLogItem.Create;
  logitem.EventType := cEventType;
  logitem.Msg := cMsg;
  {$IF DEFINED(ANDROID) OR DEFINED(DELPHILINUX)}
  logitem.EventDate := cEventDate;
  {$ELSE}
  logitem.EventDate := SystemTimeToDateTime(cEventDate);
  {$ENDIF}

  if fLogQueue.PushItem(logitem) <> TWaitResult.wrSignaled then
  begin
    FreeAndNil(logitem);
    if Assigned(fOnQueueError) then fOnQueueError('Logger insertion timeout!');
    //raise ELogger.Create('Logger insertion timeout!');
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('insertion timeout: %s',[Self.ClassName]));
    {$ENDIF}
  {$IFDEF LOGGER_DEBUG2}
  end else Writeln(Format('pushitem logger (queue: %d): %s',[fLogQueue.QueueSize,cMsg]));
  {$ELSE}
  end;
  {$ENDIF}
end;

procedure TLogger.HandleException(E : Exception);
var
  SystemTime : TSystemTime;
begin
  {$IFDEF FPCLINUX}
  DateTimeToSystemTime(Now(),SystemTime);
  {$ELSE}
  GetLocalTime(SystemTime);
  {$ENDIF}
  Self.EnQueueItem(SystemTime,Format('(%s) : %s',[E.ClassName,E.Message]),etException);
end;

{ TLogSendLimit }

constructor TLogSendLimit.Create;
begin
  inherited;
  fTimeRange := slNoLimit;
  fMaxSent := 0;
  fNumBlocked := 0;
  fFirstSent := 0;
  fLastSent := 0;
  fCurrentNumSent := 0;
end;

function TLogSendLimit.IsLimitReached(cEventType : TEventType): Boolean;
var
  reset : Boolean;
begin
  //check sent number in range
  if (fTimeRange = slNoLimit) or (not (cEventType in fLimitEventTypes)) then
  begin
    fLastSent := Now();
    Result := False;
    Exit;
  end;

  if fCurrentNumSent < fMaxSent then
  begin
    Inc(fCurrentNumSent);
    fLastSent := Now();
    if fFirstSent = 0 then fFirstSent := Now();
    Result := False;
  end
  else
  begin
    reset := False;
    case fTimeRange of
      slByDay : if HoursBetween(Now(),fFirstSent) > 24 then reset := True;
      slByHour : if MinutesBetween(Now(),fFirstSent) > 60 then reset := True;
      slByMinute : if SecondsBetween(Now(),fFirstSent) > 60 then reset := True;
      slBySecond : if MilliSecondsBetween(Now(),fFirstSent) > 999 then reset := True;
    end;
    if reset then
    begin
      fCurrentNumSent := 0;
      fFirstSent := Now();
      Inc(fCurrentNumSent);
      fLastSent := Now();
      Result := False;
    end
    else
    begin
      Inc(fNumBlocked);
      Result := True;
    end;
  end;
end;

initialization
  Logger := TLogger.Create;


finalization
  Logger.Free;

end.
