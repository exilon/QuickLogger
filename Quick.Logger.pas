{ ***************************************************************************

  Copyright (c) 2016-2022 Kike Pérez

  Unit        : Quick.Logger
  Description : Threadsafe Multi Log File, Console, Email, etc...
  Author      : Kike Pérez
  Version     : 1.42
  Created     : 12/10/2017
  Modified    : 24/01/2022

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
    {$IFDEF DELPHIXE7_UP}
    {$ELSE}
    SyncObjs,
    {$ENDIF}
  {$ENDIF}
  Quick.Logger.Intf,
  Quick.JSON.Utils,
  Quick.Json.Serializer,
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
  QLVERSION = '1.46';

type

  TEventType = (etHeader, etInfo, etSuccess, etWarning, etError, etCritical, etException, etDebug, etTrace, etDone, etCustom1, etCustom2);
  TLogLevel = set of TEventType;
  {$IFDEF DELPHIXE7_UP}
  TEventTypeNames = array of string;
  {$ELSE}
  TEventTypeNames = array[0..11] of string;
  {$ENDIF}

  ELogger = class(Exception);
  ELoggerInitializationError = class(Exception);
  ELoggerLoadProviderError = class(Exception);
  ELoggerSaveProviderError = class(Exception);

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
    {$IF Defined(NEXTGEN) OR Defined(OSX) OR Defined(LINUX)}
    TSystemTime = TDateTime;
    {$ENDIF}
  {$ENDIF}

  TLogInfoField = (iiAppName, iiHost, iiUserName, iiEnvironment, iiPlatform, iiOSVersion, iiExceptionInfo, iiExceptionStackTrace, iiThreadId, iiProcessId);

  TIncludedLogInfo = set of TLogInfoField;

  TProviderErrorEvent = procedure(const aProviderName, aError : string) of object;

  {$IFNDEF DELPHIRX10_UP}
  TThreadID = DWORD;
  {$ENDIF}

  TLogItem = class
  private
    fEventType : TEventType;
    fMsg : string;
    fEventDate : TDateTime;
    fThreadId : TThreadID;
  public
    constructor Create;
    property EventType : TEventType read fEventType write fEventType;
    property Msg : string read fMsg write fMsg;
    property EventDate : TDateTime read fEventDate write fEventDate;
    property ThreadId : TThreadID read fThreadId write fThreadId;
    function EventTypeName : string;
    function Clone : TLogItem; virtual;
  end;

  TLogExceptionItem = class(TLogItem)
  private
    fException : string;
    fStackTrace : string;
  public
    property Exception : string read fException write fException;
    property StackTrace : string read fStackTrace write fStackTrace;
    function Clone : TLogItem; override;
  end;

  TLogQueue = class(TThreadedQueueList<TLogItem>);

  ILogTags = interface
  ['{046ED03D-9EE0-49BC-BBD7-FA108EA1E0AA}']
    function GetTag(const aKey : string) : string;
    procedure SetTag(const aKey : string; const aValue : string);
    function TryGetValue(const aKey : string; out oValue : string) : Boolean;
    procedure Add(const aKey, aValue : string);
    property Items[const Key: string]: string read GetTag write SetTag; default;
  end;

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
    procedure SetLogTags(cLogTags : ILogTags);
    function IsSendLimitReached(cEventType : TEventType): Boolean;
    function GetLogLevel : TLogLevel;
    function IsEnabled : Boolean;
    function GetVersion : string;
    function GetName : string;
    function GetQueuedLogItems : Integer;
    {$IF DEFINED(DELPHIXE7_UP)}// AND NOT DEFINED(NEXTGEN)}
    function ToJson(aIndent : Boolean = True) : string;
    procedure FromJson(const aJson : string);
    procedure SaveToFile(const aJsonFile : string);
    procedure LoadFromFile(const aJsonFile : string);
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

  TJsonOutputOptions = class
  private
    fUseUTCTime : Boolean;
    fTimeStampName : string;
  public
    property UseUTCTime : Boolean read fUseUTCTime write fUseUTCTime;
    property TimeStampName : string read fTimeStampName write fTimeStampName;
  end;

  TLogTags = class(TInterfacedObject,ILogTags)
  private
    fTags : TDictionary<string,string>;
    function GetTag(const aKey : string) : string;
    procedure SetTag(const aKey : string; const aValue : string);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[const Key: string]: string read GetTag write SetTag; default;
    function TryGetValue(const aKey : string; out oValue : string) : Boolean;
    procedure Add(const aKey, aValue : string);
  end;

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
    fRestartTimes : Integer;
    fFailsToRestart : Integer;
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
    fIncludedTags : TArray<string>;
    fSystemInfo : TSystemInfo;
    fCustomMsgOutput : Boolean;
    fOnNotifyError : TProviderErrorEvent;
    procedure SetTimePrecission(Value : Boolean);
    procedure SetEnabled(aValue : Boolean);
    function GetQueuedLogItems : Integer;
    procedure EnQueueItem(cLogItem : TLogItem);
    function GetEventTypeName(cEventType : TEventType) : string;
    procedure SetEventTypeName(cEventType: TEventType; const cValue : string);
    function IsSendLimitReached(cEventType : TEventType): Boolean;
    procedure SetMaxFailsToRestart(const Value: Integer);
  protected
    fJsonOutputOptions : TJsonOutputOptions;
    fCustomTags : ILogTags;
    fCustomFormatOutput : string;
    function LogItemToLine(cLogItem : TLogItem; aShowTimeStamp, aShowEventTypes : Boolean) : string; overload;
    function LogItemToJsonObject(cLogItem: TLogItem): TJSONObject; overload;
    function LogItemToJson(cLogItem : TLogItem) : string; overload;
    function LogItemToHtml(cLogItem: TLogItem): string;
    function LogItemToText(cLogItem: TLogItem): string;
    function LogItemToFormat(cLogItem : TLogItem) : string;
    {$IFDEF DELPHIXE8_UP}
    function LogItemToFormat2(cLogItem : TLogItem) : string;
    {$ENDIF}
    function ResolveFormatVariable(const cToken : string; cLogItem: TLogItem) : string;
    procedure IncAndCheckErrors;
    procedure SetStatus(cStatus : TLogProviderStatus);
    procedure SetLogTags(cLogTags : ILogTags);
    function GetLogLevel : TLogLevel;
    property SystemInfo : TSystemInfo read fSystemInfo;
    procedure NotifyError(const aError : string);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Init; virtual;
    procedure Restart; virtual; abstract;
    procedure Stop; virtual;
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
    property MaxFailsToRestart : Integer read fMaxFailsToRestart write SetMaxFailsToRestart;
    property MaxFailsToStop : Integer read fMaxFailsToStop write fMaxFailsToStop;
    property CustomMsgOutput : Boolean read fCustomMsgOutput write fCustomMsgOutput;
    property CustomFormatOutput : string read fCustomFormatOutput write fCustomFormatOutput;
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
    property IncludedTags : TArray<string> read fIncludedTags write fIncludedTags;
    function Status : TLogProviderStatus;
    function StatusAsString : string; overload;
    class function StatusAsString(cStatus : TLogProviderStatus) : string; overload;
    function GetVersion : string;
    function IsEnabled : Boolean;
    function GetName : string;
    {$IF DEFINED(DELPHIXE7_UP)}// AND NOT DEFINED(NEXTGEN)}
    function ToJson(aIndent : Boolean = True) : string;
    procedure FromJson(const aJson : string);
    procedure SaveToFile(const aJsonFile : string);
    procedure LoadFromFile(const aJsonFile : string);
    {$ENDIF}
  end;

  {$IF DEFINED(DELPHIXE7_UP)}// AND NOT DEFINED(NEXTGEN)}
  TLogProviderList = class(TList<ILogProvider>)
  public
    function ToJson(aIndent : Boolean = True) : string;
    procedure FromJson(const aJson : string);
    procedure LoadFromFile(const aJsonFile : string);
    procedure SaveToFile(const aJsonFile : string);
  end;
  {$ELSE}
  TLogProviderList = TList<ILogProvider>;
  {$ENDIF}

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

  TLogger = class(TInterfacedObject,ILogger)
  private
    fThreadProviderLog : TThreadProviderLog;
    fLogQueue : TLogQueue;
    fProviders : TLogProviderList;
    fCustomTags : ILogTags;
    fWaitForFlushBeforeExit : Integer;
    fOnQueueError: TQueueErrorEvent;
    fOwnErrorsProvider : TLogProviderBase;
    fOnProviderError : TProviderErrorEvent;
    function GetQueuedLogItems : Integer;
    procedure EnQueueItem(cEventDate : TSystemTime; const cMsg : string; cEventType : TEventType); overload;
    procedure EnQueueItem(cEventDate : TSystemTime; const cMsg : string; const cException, cStackTrace : string; cEventType : TEventType); overload;
    procedure EnQueueItem(cLogItem : TLogItem); overload;
    procedure OnGetHandledException(E : Exception);
    procedure OnGetRuntimeError(const ErrorName : string; ErrorCode : Byte; ErrorPtr : Pointer);
    procedure OnGetUnhandledException(ExceptObject: TObject; ExceptAddr: Pointer);
    procedure NotifyProviderError(const aProviderName, aError : string);
    procedure SetOwnErrorsProvider(const Value: TLogProviderBase);
    {$IFNDEF FPC}
    procedure OnProviderListNotify(Sender: TObject; const Item: ILogProvider; Action: TCollectionNotification);
    {$ELSE}
    procedure OnProviderListNotify(ASender: TObject; constref AItem: ILogProvider; AAction: TCollectionNotification);
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    property Providers : TLogProviderList read fProviders write fProviders;
    property RedirectOwnErrorsToProvider : TLogProviderBase read fOwnErrorsProvider write SetOwnErrorsProvider;
    property WaitForFlushBeforeExit : Integer read fWaitForFlushBeforeExit write fWaitForFlushBeforeExit;
    property OnProviderError : TProviderErrorEvent read fOnProviderError write fOnProviderError;
    property QueueCount : Integer read GetQueuedLogItems;
    property OnQueueError : TQueueErrorEvent read fOnQueueError write fOnQueueError;
    property CustomTags : ILogTags read fCustomTags;
    function ProvidersQueueCount : Integer;
    function IsQueueEmpty : Boolean;
    class function GetVersion : string;
    procedure Add(const cMsg : string; cEventType : TEventType); overload;
    procedure Add(const cMsg, cException, cStackTrace : string; cEventType : TEventType); overload;
    procedure Add(const cMsg : string; cValues : array of {$IFDEF FPC}const{$ELSE}TVarRec{$ENDIF}; cEventType : TEventType); overload;
    //simplify logging add
    procedure Info(const cMsg : string); overload;
    procedure Info(const cMsg : string; cValues : array of const); overload;
    procedure Warn(const cMsg : string); overload;
    procedure Warn(const cMsg : string; cValues : array of const); overload;
    procedure Error(const cMsg : string); overload;
    procedure Error(const cMsg : string; cValues : array of const); overload;
    procedure Critical(const cMsg : string); overload;
    procedure Critical(const cMsg : string; cValues : array of const); overload;
    procedure Succ(const cMsg : string); overload;
    procedure Succ(const cMsg : string; cValues : array of const); overload;
    procedure Done(const cMsg : string); overload;
    procedure Done(const cMsg : string; cValues : array of const); overload;
    procedure Debug(const cMsg : string); overload;
    procedure Debug(const cMsg : string; cValues : array of const); overload;
    procedure Trace(const cMsg : string); overload;
    procedure Trace(const cMsg : string; cValues : array of const); overload;
    procedure &Except(const cMsg : string); overload;
    procedure &Except(const cMsg : string; cValues : array of const); overload;
    procedure &Except(const cMsg, cException, cStackTrace : string); overload;
    procedure &Except(const cMsg : string; cValues: array of const; const cException, cStackTrace: string); overload;
  end;

  procedure Log(const cMsg : string; cEventType : TEventType); overload;
  procedure Log(const cMsg : string; cValues : array of {$IFDEF FPC}const{$ELSE}TVarRec{$ENDIF}; cEventType : TEventType); overload;

var
  Logger : TLogger;
  GlobalLoggerHandledException : procedure(E : Exception) of object;
  GlobalLoggerRuntimeError : procedure(const ErrorName : string; ErrorCode : Byte; ErrorPtr : Pointer) of object;
  GlobalLoggerUnhandledException : procedure(ExceptObject: TObject; ExceptAddr: Pointer) of object;

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
  {$IFDEF DELPHIXE7_UP}
  fIncludedTags := [];
  {$ELSE}
  fIncludedTags := nil;
  {$ENDIF}
  fFails := 0;
  fRestartTimes := 0;
  fMaxFailsToRestart := 2;
  fMaxFailsToStop := 0;
  fFailsToRestart := fMaxFailsToRestart - 1;
  fEnabled := False;
  fUsesQueue := True;
  fEventTypeNames := DEF_EVENTTYPENAMES;
  fLogQueue := TLogQueue.Create(DEF_QUEUE_SIZE,DEF_QUEUE_PUSH_TIMEOUT,DEF_QUEUE_POP_TIMEOUT);
  fEnvironment := '';
  fPlatformInfo := '';
  fIncludedInfo := [iiAppName,iiHost];
  fSystemInfo := Quick.SysInfo.SystemInfo;
  fJsonOutputOptions := TJsonOutputOptions.Create;
  fJsonOutputOptions.UseUTCTime := False;
  fJsonOutputOptions.TimeStampName := 'timestamp';
  fAppName := fSystemInfo.AppName;
end;

destructor TLogProviderBase.Destroy;
begin
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('destroy object: %s',[Self.ClassName]));
  Writeln(Format('%s.Queue = %d',[Self.ClassName,fLogQueue.QueueSize]));
  {$ENDIF}
  if Assigned(fLogQueue) then fLogQueue.Free;
  if Assigned(fSendLimits) then fSendLimits.Free;
  if Assigned(fJsonOutputOptions) then fJsonOutputOptions.Free;
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
  //NotifyError(Format('Provider stopped!',[fMaxFailsToStop]));
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
    NotifyError(Format('Max fails (%d) to Stop reached! It will be Drained & Stopped now!',[fMaxFailsToStop]));
    if Assigned(fOnCriticalError) then fOnCriticalError(fName,'Max fails to Stop reached!');
  end
  else if fFailsToRestart = 0 then
  begin
    //try to restart provider
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('restart: %s (%d)',[Self.ClassName,fFails]));
    {$ENDIF}
    NotifyError(Format('Max fails (%d) to Restart reached! Restarting...',[fMaxFailsToRestart]));
    SetStatus(TLogProviderStatus.psRestarting);
    try
      Restart;
    except
      on E : Exception do
      begin
        NotifyError(Format('Failed to restart: %s',[e.Message]));
        //set as running to try again
        SetStatus(TLogProviderStatus.psRunning);
        Exit;
      end;
    end;
    Inc(fRestartTimes);
    NotifyError(Format('Provider Restarted. This occurs for %d time(s)',[fRestartTimes]));
    fFailsToRestart := fMaxFailsToRestart-1;
    if Assigned(fOnRestart) then fOnRestart(fName);
  end
  else
  begin
    Dec(fFailsToRestart);
    NotifyError(Format('Failed %d time(s). Fails to restart %d/%d',[fFails,fFailsToRestart,fMaxFailsToRestart]));
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
  if not(fStatus in [psNone,psStopped,psRestarting]) then Exit;
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('init thread: %s',[Self.ClassName]));
  {$ENDIF}
  SetStatus(TLogProviderStatus.psInitializing);
  if fUsesQueue then
  begin
    if not Assigned(fThreadLog) then
    begin
      fThreadLog := TThreadLog.Create;
      fThreadLog.LogQueue := fLogQueue;
      fThreadLog.Provider := Self;
      fThreadLog.Start;
    end;
  end;
  SetStatus(TLogProviderStatus.psRunning);
  fEnabled := True;
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
var
  tagName : string;
  tagValue : string;
begin
  Result := TJSONObject.Create;
  if fJsonOutputOptions.UseUTCTime then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}(fJsonOutputOptions.TimeStampName,DateTimeToJsonDate(LocalTimeToUTC(cLogItem.EventDate)))
    else Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}(fJsonOutputOptions.TimeStampName,DateTimeToJsonDate(cLogItem.EventDate));
  Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('type',EventTypeName[cLogItem.EventType]);
  if iiHost in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('host',SystemInfo.HostName);
  if iiAppName in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('application',fAppName);
  if iiEnvironment in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('environment',fEnvironment);
  if iiPlatform in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('platform',fPlatformInfo);
  if iiOSVersion in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('OS',SystemInfo.OSVersion);
  if iiUserName in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('user',SystemInfo.UserName);
  if iiThreadId in IncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('threadid',cLogItem.ThreadId.ToString);
  if iiProcessId in IncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('pid',SystemInfo.ProcessId.ToString);

  if cLogItem is TLogExceptionItem then
  begin
    if iiExceptionInfo in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('exception',TLogExceptionItem(cLogItem).Exception);
    if iiExceptionStackTrace in fIncludedInfo then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('stacktrace',TLogExceptionItem(cLogItem).StackTrace);
  end;
  Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('message',cLogItem.Msg);
  Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('level',Integer(cLogItem.EventType).ToString);

  for tagName in IncludedTags do
  begin
    if fCustomTags.TryGetValue(tagName,tagValue) then Result.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}(tagName,tagValue);
  end;
end;

function TLogProviderBase.LogItemToLine(cLogItem : TLogItem; aShowTimeStamp, aShowEventTypes : Boolean) : string;
var
  tagName : string;
  tagValue : string;
begin
  Result := '';
  if aShowTimeStamp then Result := DateTimeToStr(cLogItem.EventDate,FormatSettings);
  if aShowEventTypes then Result := Format('%s [%s]',[Result,EventTypeName[cLogItem.EventType]]);
  Result := Result + ' ' + cLogItem.Msg;
  if iiThreadId in IncludedInfo then Result := Format('%s [ThreadId: %d]',[Result,cLogItem.ThreadId]);
  if iiProcessId in IncludedInfo then Result := Format('%s [PID: %d]',[Result,SystemInfo.ProcessId]);

  for tagName in IncludedTags do
  begin
    if fCustomTags.TryGetValue(tagName,tagValue) then Result := Format('%s [%s: %s]',[Result,tagName,tagValue]);
  end;
end;

function TLogProviderBase.LogItemToJson(cLogItem: TLogItem): string;
var
  json : TJSONObject;
begin
  json := LogItemToJsonObject(cLogItem);
  try
    {$IFDEF DELPHIXE7_UP}
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

function TLogProviderBase.ResolveFormatVariable(const cToken : string; cLogItem: TLogItem) : string;
begin
  //try process token as tag
  if not fCustomTags.TryGetValue(cToken,Result) then
  begin
    //try process token as variable
    if cToken = 'DATETIME' then Result := DateTimeToStr(cLogItem.EventDate,FormatSettings)
    else if cToken = 'DATE' then Result := DateToStr(cLogItem.EventDate)
    else if cToken = 'TIME' then Result := TimeToStr(cLogItem.EventDate)
    else if cToken = 'LEVEL' then Result := cLogItem.EventTypeName
    else if cToken = 'LEVELINT' then Result := Integer(cLogItem.EventType).ToString
    else if cToken = 'MESSAGE' then Result := cLogItem.Msg
    else if cToken = 'ENVIRONMENT' then Result := Self.Environment
    else if cToken = 'PLATFORM' then Result := Self.PlatformInfo
    else if cToken = 'APPNAME' then Result := Self.AppName
    else if cToken = 'APPVERSION' then Result := Self.SystemInfo.AppVersion
    else if cToken = 'APPPATH' then Result := Self.SystemInfo.AppPath
    else if cToken = 'HOSTNAME' then Result := Self.SystemInfo.HostName
    else if cToken = 'USERNAME' then Result := Self.SystemInfo.UserName
    else if cToken = 'OSVERSION' then Result := Self.SystemInfo.OsVersion
    else if cToken = 'CPUCORES' then Result := Self.SystemInfo.CPUCores.ToString
    else if cToken = 'THREADID' then Result := cLogItem.ThreadId.ToString
    else if cToken = 'PROCESSID' then Result := SystemInfo.ProcessId.ToString
    else Result := '%error%';
  end;
end;

{$IFDEF DELPHIXE8_UP}
function TLogProviderBase.LogItemToFormat2(cLogItem: TLogItem): string;
var
  line : string;
  newline : string;
  token : string;
  tokrep : string;
begin
  if CustomFormatOutput.IsEmpty then Exit(cLogItem.Msg);
  //resolve log format
  Result := '';
  for line in fCustomFormatOutput.Split([sLineBreak]) do
  begin
    newline := line;
    repeat
      token := GetSubString(newline,'%{','}');
      if not token.IsEmpty then
      begin
        tokrep := ResolveFormatVariable(token.ToUpper,cLogItem);
        //replace token
        newline := StringReplace(newline,'%{'+token+'}',tokrep,[rfReplaceAll]);
      end;
    until token.IsEmpty;
    Result := Result + newline;
  end;
end;
{$ENDIF}

function TLogProviderBase.LogItemToFormat(cLogItem: TLogItem): string;
var
  idx : Integer;
  st : Integer;
  et : Integer;
  token : string;
begin
  if CustomFormatOutput.IsEmpty then Exit(cLogItem.Msg);
  //resolve log format
  Result := '';
  idx := 1;
  st := Low(string);
  et := Low(string);
  while st < fCustomFormatOutput.Length do
  begin
    if (fCustomFormatOutput[st] = '%') and (fCustomFormatOutput[st+1] = '{') then
    begin
      et := st + 2;
      while et < fCustomFormatOutput.Length do
      begin
        Inc(et);
        if fCustomFormatOutput[et] = '}' then
        begin
          Result := Result + Copy(fCustomFormatOutput,idx,st-idx);
          token := Copy(fCustomFormatOutput,st + 2,et-st-2);
          Result := Result + ResolveFormatVariable(token,cLogItem);
          idx := et + 1;
          st := idx;
          Break;
        end;
      end;
    end
    else Inc(st);
  end;
  if et < st then Result := Result + Copy(fCustomFormatOutput,et+1,st-et + 1);
end;

function TLogProviderBase.LogItemToHtml(cLogItem: TLogItem): string;
var
  msg : TStringList;
  tagName : string;
  tagValue : string;
begin
  msg := TStringList.Create;
  try
    msg.Add('<html><body>');
    msg.Add(Format('<B>EventDate:</B> %s%s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),HTMBR]));
    msg.Add(Format('<B>Type:</B> %s%s',[EventTypeName[cLogItem.EventType],HTMBR]));
    if iiAppName in IncludedInfo then msg.Add(Format('<B>Application:</B> %s%s',[SystemInfo.AppName,HTMBR]));
    if iiHost in IncludedInfo then msg.Add(Format('<B>Host:</B> %s%s ',[SystemInfo.HostName,HTMBR]));
    if iiUserName in IncludedInfo then msg.Add(Format('<B>User:</B> %s%s',[SystemInfo.UserName,HTMBR]));
    if iiOSVersion in IncludedInfo then msg.Add(Format('<B>OS:</B> %s%s',[SystemInfo.OsVersion,HTMBR]));
    if iiEnvironment in IncludedInfo then msg.Add(Format('<B>Environment:</B> %s%s',[Environment,HTMBR]));
    if iiPlatform in IncludedInfo then msg.Add(Format('<B>Platform:</B> %s%s',[PlatformInfo,HTMBR]));
    if iiThreadId in IncludedInfo then msg.Add(Format('<B>ThreadId:</B> %d',[cLogItem.ThreadId]));
    if iiProcessId in IncludedInfo then msg.Add(Format('<B>PID:</B> %d',[SystemInfo.ProcessId]));
    for tagName in IncludedTags do
    begin
      if fCustomTags.TryGetValue(tagName,tagValue) then msg.Add(Format('<B>%s</B> %s',[tagName,tagValue]));
    end;
    msg.Add(Format('<B>Message:</B> %s%s',[cLogItem.Msg,HTMBR]));
    msg.Add('</body></html>');
    Result := msg.Text;
  finally
    msg.Free;
  end;
end;

function TLogProviderBase.LogItemToText(cLogItem: TLogItem): string;
var
  msg : TStringList;
  tagName : string;
  tagValue : string;
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
    if iiThreadId in IncludedInfo then msg.Add(Format('ThreadId: %d',[cLogItem.ThreadId]));
    if iiProcessId in IncludedInfo then msg.Add(Format('PID: %d',[SystemInfo.ProcessId]));
    for tagName in IncludedTags do
    begin
      if fCustomTags.TryGetValue(tagName,tagValue) then msg.Add(Format('%s: %s',[tagName,tagValue]));
    end;
    msg.Add(Format('Message: %s',[cLogItem.Msg]));
    Result := msg.Text;
  finally
    msg.Free;
  end;
end;

procedure TLogProviderBase.NotifyError(const aError: string);
begin
  if Assigned(fOnNotifyError) then fOnNotifyError(fName,aError);
end;

procedure TLogProviderBase.Stop;
begin
  if (fStatus = psStopped) or (fStatus = psStopping) then Exit;

  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('stopping thread: %s',[Self.ClassName]));
  {$ENDIF}
  fEnabled := False;
  SetStatus(TLogProviderStatus.psStopping);
  if Assigned(fThreadLog) then
  begin
    if not fThreadLog.Terminated then
    begin
      fThreadLog.Terminate;
      fThreadLog.WaitFor;
    end;
    fThreadLog.Free;
    fThreadLog := nil;
  end;
  SetStatus(TLogProviderStatus.psStopped);
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('stopped thread: %s',[Self.ClassName]));
  {$ENDIF}
end;

{$IF DEFINED(DELPHIXE7_UP)}// AND NOT DEFINED(NEXTGEN)}
  function TLogProviderBase.ToJson(aIndent : Boolean = True) : string;
  var
    serializer : TJsonSerializer;
  begin
    serializer := TJsonSerializer.Create(slPublicProperty);
    try
      Result := serializer.ObjectToJson(Self,aIndent);
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
      if fEnabled then Self.Restart;
    finally
      serializer.Free;
    end;
  end;

  procedure TLogProviderBase.SaveToFile(const aJsonFile : string);
  var
    json : TStringList;
  begin
    json := TStringList.Create;
    try
      json.Text := Self.ToJson;
      json.SaveToFile(aJsonFile);
    finally
      json.Free;
    end;
  end;

  procedure TLogProviderBase.LoadFromFile(const aJsonFile : string);
  var
    json : TStringList;
  begin
    json := TStringList.Create;
    try
      json.LoadFromFile(aJsonFile);
      Self.FromJson(json.Text);
    finally
      json.Free;
    end;
  end;
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

procedure TLogProviderBase.SetLogTags(cLogTags: ILogTags);
begin
  fCustomTags := cLogTags;
end;

procedure TLogProviderBase.SetMaxFailsToRestart(const Value: Integer);
begin
  if Value > 0 then fMaxFailsToRestart := Value
    else fMaxFailsToRestart := 1;
  fFailsToRestart := fMaxFailsToRestart-1;
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
var
  errormsg : string;
begin
  if (aValue <> fEnabled) then
  begin
    if aValue then
    begin
      try
        Init;
      except
        on E : Exception do
        begin
          errormsg := Format('LoggerProvider "%s" initialization error (%s)',[Self.Name,e.Message]);
          NotifyError(errormsg);
          if Assigned(fOnCriticalError) then fOnCriticalError(Self.Name,errormsg);
          //  else raise ELoggerInitializationError.Create(errormsg);
        end;
      end;
    end
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
            on E : Exception do
            begin
              {$IFDEF LOGGER_DEBUG}
              Writeln(Format('fail: %s (%d)',[TLogProviderBase(fProvider).ClassName,TLogProviderBase(fProvider).Fails + 1]));
              {$ENDIF}
              TLogProviderBase(fProvider).NotifyError(e.message);
              //check if there are many errors and needs to restart or stop provider
              if not Terminated then fProvider.IncAndCheckErrors;
            end;
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
  {$IFDEF LOGGER_DEBUG}
  Writeln(Format('Logger.Queue = %d',[fLogQueue.QueueSize]));
  {$ENDIF}
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
                    on E : Exception do
                    begin
                      {$IFDEF LOGGER_DEBUG}
                      Writeln(Format('fail: %s (%d)',[TLogProviderBase(provider).ClassName,TLogProviderBase(provider).Fails + 1]));
                      {$ENDIF}
                      TLogProviderBase(provider).NotifyError(e.message);
                      //try to restart provider
                      if not Terminated then provider.IncAndCheckErrors;
                    end;
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
  Result.ThreadId := Self.ThreadId;
  Result.Msg := Self.Msg;
end;

{  TLogItemException  }

function TLogExceptionItem.Clone : TLogItem;
begin
  Result := TLogExceptionItem.Create;
  Result.EventType := Self.EventType;
  Result.EventDate := Self.EventDate;
  Result.Msg := Self.Msg;
  TLogExceptionItem(Result).Exception := Self.Exception;
  TLogExceptionItem(Result).StackTrace := Self.StackTrace;
end;


{ TLogger }

constructor TLogger.Create;
begin
  inherited;
  GlobalLoggerHandledException := OnGetHandledException;
  GlobalLoggerRuntimeError := OnGetRuntimeError;
  GlobalLoggerUnhandledException := OnGetUnhandledException;
  fWaitForFlushBeforeExit := DEF_WAIT_FLUSH_LOG;
  fLogQueue := TLogQueue.Create(DEF_QUEUE_SIZE,DEF_QUEUE_PUSH_TIMEOUT,DEF_QUEUE_POP_TIMEOUT);
  fCustomTags := TLogTags.Create;
  fProviders := TLogProviderList.Create;
  fProviders.OnNotify := OnProviderListNotify;
  fThreadProviderLog := TThreadProviderLog.Create;
  fThreadProviderLog.LogQueue := fLogQueue;
  fThreadProviderLog.Providers := fProviders;
  fThreadProviderLog.Start;
end;

destructor TLogger.Destroy;
var
  FinishTime : TDateTime;
begin
  GlobalLoggerHandledException := nil;
  GlobalLoggerRuntimeError := nil;
  GlobalLoggerUnhandledException := nil;
  FinishTime := Now();
  //wait for main queue and all providers queues finish to flush or max time reached
  try
    while (not Self.IsQueueEmpty) and (SecondsBetween(Now(),FinishTime) < fWaitForFlushBeforeExit) do
    begin
      {$IFDEF MSWINDOWS}
      ProcessMessages;
      {$ELSE}
      Sleep(250);
      {$ENDIF}
    end;
  except
    {$IFDEF LOGGER_DEBUG}
    on E : Exception do Writeln(Format('fail waiting for flush: %s',[e.Message]));
    {$ENDIF}
  end;
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

class function TLogger.GetVersion: string;
begin
  Result := QLVERSION;
end;

function TLogger.IsQueueEmpty: Boolean;
begin
  Result := (QueueCount = 0) and (ProvidersQueueCount = 0);
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

procedure TLogger.Add(const cMsg, cException, cStackTrace : string; cEventType : TEventType);
var
  SystemTime : TSystemTime;
begin
  {$IFDEF FPCLINUX}
  DateTimeToSystemTime(Now(),SystemTime);
  {$ELSE}
  GetLocalTime(SystemTime);
  {$ENDIF}
  Self.EnQueueItem(SystemTime,cMsg,cException,cStackTrace,cEventType);
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
  {$IF DEFINED(NEXTGEN) OR DEFINED(OSX) OR DEFINED(DELPHILINUX)}
  logitem.EventDate := cEventDate;
  {$ELSE}
  logitem.EventDate := SystemTimeToDateTime(cEventDate);
  {$ENDIF}
  Self.EnQueueItem(logitem);
end;

procedure TLogger.EnQueueItem(cEventDate : TSystemTime; const cMsg : string; const cException, cStackTrace : string; cEventType : TEventType);
var
  logitem : TLogExceptionItem;
begin
  logitem := TLogExceptionItem.Create;
  logitem.EventType := cEventType;
  logitem.Msg := cMsg;
  logitem.Exception := cException;
  logitem.StackTrace := cStackTrace;
  {$IF DEFINED(NEXTGEN) OR DEFINED(OSX) OR DEFINED(DELPHILINUX)}
  logitem.EventDate := cEventDate;
  {$ELSE}
  logitem.EventDate := SystemTimeToDateTime(cEventDate);
  {$ENDIF}
  Self.EnQueueItem(logitem);
end;

procedure TLogger.EnQueueItem(cLogItem : TLogItem);
begin
  {$IFDEF MSWINDOWS}
  cLogItem.ThreadId := GetCurrentThreadId;
  {$ELSE}
  cLogItem.ThreadId := TThread.CurrentThread.ThreadID;
  {$ENDIF}
  if fLogQueue.PushItem(cLogItem) <> TWaitResult.wrSignaled then
  begin
    FreeAndNil(cLogItem);
    if Assigned(fOnQueueError) then fOnQueueError('Logger insertion timeout!');
    //raise ELogger.Create('Logger insertion timeout!');
    {$IFDEF LOGGER_DEBUG}
    Writeln(Format('insertion timeout: %s',[Self.ClassName]));
    {$ENDIF}
  {$IFDEF LOGGER_DEBUG2}
  end else Writeln(Format('pushitem logger (queue: %d): %s',[fLogQueue.QueueSize,cLogItem.Msg]));
  {$ELSE}
  end;
  {$ENDIF}
end;

procedure TLogger.Info(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etInfo);
end;

procedure TLogger.Info(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etInfo);
end;

procedure TLogger.Critical(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etCritical);
end;

procedure TLogger.Critical(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etCritical);
end;

procedure TLogger.Succ(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etSuccess);
end;

procedure TLogger.Succ(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etSuccess);
end;

procedure TLogger.Warn(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etWarning);
end;

procedure TLogger.Warn(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etWarning);
end;

procedure TLogger.Debug(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etDebug);
end;

procedure TLogger.Debug(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etDebug);
end;

procedure TLogger.Trace(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etTrace);
end;

procedure TLogger.Trace(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etTrace);
end;

procedure TLogger.Done(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etDone);
end;

procedure TLogger.Done(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etDone);
end;

procedure TLogger.Error(const cMsg: string);
begin
  Self.Add(cMsg,TEventType.etError);
end;

procedure TLogger.Error(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etError);
end;

procedure TLogger.&Except(const cMsg : string);
begin
  Self.Add(cMsg,TEventType.etException);
end;

procedure TLogger.&Except(const cMsg: string; cValues: array of const);
begin
  Self.Add(cMsg,cValues,TEventType.etException);
end;

procedure TLogger.&Except(const cMsg, cException, cStackTrace: string);
begin
  Self.Add(cMsg,cException,cStackTrace,TEventType.etException);
end;

procedure TLogger.&Except(const cMsg : string; cValues: array of const; const cException, cStackTrace: string);
begin
  Self.Add(Format(cMsg,cValues),cException,cStackTrace,TEventType.etException);
end;

procedure TLogger.OnGetHandledException(E : Exception);
var
  SystemTime : TSystemTime;
begin
  {$IFDEF FPCLINUX}
  DateTimeToSystemTime(Now(),SystemTime);
  {$ELSE}
  GetLocalTime(SystemTime);
  {$ENDIF}
  {$IFDEF FPC}
  Self.EnQueueItem(SystemTime,Format('(%s) : %s',[E.ClassName,E.Message]),E.ClassName,'',etException);
  {$ELSE}
  Self.EnQueueItem(SystemTime,Format('(%s) : %s',[E.ClassName,E.Message]),E.ClassName,E.StackTrace,etException);
  {$ENDIF}
end;

procedure TLogger.OnGetRuntimeError(const ErrorName : string; ErrorCode : Byte; ErrorPtr : Pointer);
var
  SystemTime : TSystemTime;
begin
  {$IFDEF FPCLINUX}
  DateTimeToSystemTime(Now(),SystemTime);
  {$ELSE}
  GetLocalTime(SystemTime);
  {$ENDIF}
  Self.EnQueueItem(SystemTime,Format('Runtime error %d (%s) risen at $%X',[Errorcode,errorname,Integer(ErrorPtr)]),'RuntimeError','',etException);
end;

procedure TLogger.OnGetUnhandledException(ExceptObject : TObject; ExceptAddr : Pointer);
var
  SystemTime : TSystemTime;
begin
  {$IFDEF FPCLINUX}
  DateTimeToSystemTime(Now(),SystemTime);
  {$ELSE}
  GetLocalTime(SystemTime);
  {$ENDIF}
  if ExceptObject is Exception then Self.EnQueueItem(SystemTime,Format('Unhandled Exception (%s) : %s',[Exception(ExceptObject).ClassName,Exception(ExceptObject).Message]),
                                                     Exception(ExceptObject).ClassName,
                                                     {$IFDEF FPC}'',{$ELSE}Exception(ExceptObject).StackTrace,{$ENDIF}
                                                     etException)
    else Self.EnQueueItem(SystemTime,Format('Unhandled Exception (%s) at $%X',[ExceptObject.ClassName,Integer(ExceptAddr)]),'Exception','',etException);
end;

{$IFNDEF FPC}
procedure TLogger.OnProviderListNotify(Sender: TObject; const Item: ILogProvider; Action: TCollectionNotification);
begin
  if Action = TCollectionNotification.cnAdded then Item.SetLogTags(fCustomTags);
end;
{$ELSE}
procedure TLogger.OnProviderListNotify(ASender: TObject; constref AItem: ILogProvider; AAction: TCollectionNotification);
begin
  if AAction = TCollectionNotification.cnAdded then AItem.SetLogTags(fCustomTags);
end;
{$ENDIF}

function TLogger.ProvidersQueueCount: Integer;
var
  provider : ILogProvider;
begin
  Result := 0;
  for provider in fProviders do
  begin
    Result := Result + provider.GetQueuedLogItems;
  end;
end;

procedure TLogger.NotifyProviderError(const aProviderName, aError: string);
var
  logitem : TLogItem;
begin
  if Assigned(fOwnErrorsProvider) then
  begin
    logitem := TLogItem.Create;
    logitem.EventType := etError;
    logitem.EventDate := Now();
    logitem.Msg := Format('LOGGER "%s": %s',[aProviderName,aError]);
    fOwnErrorsProvider.EnQueueItem(logitem);
  end;
  if Assigned(fOnProviderError) then fOnProviderError(aProviderName,aError);
end;

procedure TLogger.SetOwnErrorsProvider(const Value: TLogProviderBase);
var
  provider : ILogProvider;
begin
  fOwnErrorsProvider := Value;
  for provider in fProviders do
  begin
    //redirect provider errors to logger
    TLogProviderBase(provider).fOnNotifyError := NotifyProviderError;
  end;
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

{ TLogProviderList }

{$IF DEFINED(DELPHIXE7_UP)}// AND NOT DEFINED(NEXTGEN)}
function TLogProviderList.ToJson(aIndent : Boolean = True) : string;
var
  iprovider : ILogProvider;
begin
  Result := '{';
  for iprovider in Self do
  begin
    Result := Result + '"' + iprovider.GetName + '": ';
    Result := Result + iprovider.ToJson(False);
    Result := Result + ',';
  end;
  if Result.EndsWith(',') then Result := RemoveLastChar(Result);
  Result := Result + '}';
  if aIndent then Result := TJsonUtils.JsonFormat(Result);
end;

procedure TLogProviderList.FromJson(const aJson : string);
var
  iprovider : ILogProvider;
  jobject : TJSONObject;
  jvalue : TJSONValue;
begin
  try
    jobject := TJSONObject.ParseJSONValue(aJson) as TJSONObject;
    try
      for iprovider in Self do
      begin
        jvalue := jobject.GetValue(iprovider.GetName);
        if Assigned(jvalue) then
          iprovider.FromJson(jvalue.ToJSON);
      end;
    finally
      jobject.Free;
    end;
  except
    on E : Exception do
    begin
      if iprovider <> nil then raise ELoggerLoadProviderError.CreateFmt('Error loading provider "%s" from json: %s',[iprovider.GetName,e.message])
        else raise ELoggerLoadProviderError.CreateFmt('Error loading providers from json: %s',[e.message]);
    end;
  end;
end;

procedure TLogProviderList.LoadFromFile(const aJsonFile : string);
var
  json : TStringList;
begin
  json := TStringList.Create;
  try
    json.LoadFromFile(aJsonFile);
    Self.FromJson(json.Text);
  finally
    json.Free;
  end;
end;

procedure TLogProviderList.SaveToFile(const aJsonFile : string);
var
  json : TStringList;
begin
  json := TStringList.Create;
  try
    json.Text := Self.ToJson;
    json.SaveToFile(aJsonFile);
  finally
    json.Free;
  end;
end;
{$ENDIF}

{ TLogTags }

constructor TLogTags.Create;
begin
  fTags := TDictionary<string,string>.Create;
end;

destructor TLogTags.Destroy;
begin
  fTags.Free;
  inherited;
end;

procedure TLogTags.Add(const aKey, aValue: string);
begin
  fTags.Add(aKey.ToUpper,aValue);
end;

function TLogTags.GetTag(const aKey: string): string;
begin
  if not fTags.TryGetValue(aKey,Result) then raise Exception.CreateFmt('Log Tag "%s" not found!',[aKey]);
end;

procedure TLogTags.SetTag(const aKey, aValue: string);
begin
  fTags.AddOrSetValue(aKey.ToUpper,aValue);
end;

function TLogTags.TryGetValue(const aKey : string; out oValue : string) : Boolean;
begin
  Result := fTags.TryGetValue(aKey.ToUpper,oValue);
end;

initialization
  Logger := TLogger.Create;


finalization
  Logger.Free;

end.
