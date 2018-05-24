{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Events
  Description : Log Email Provider
  Author      : Kike Pérez
  Version     : 1.21
  Created     : 16/10/2017
  Modified    : 24/05/2018

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
unit Quick.Logger.Provider.Events;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  Quick.Commons,
  Quick.Logger;

type

  {$IFDEF FPC}
  TLoggerEvent = procedure(LogItem : TLogItem) of object;
  {$ELSE}
  TLoggerEvent = reference to procedure(LogItem : TLogItem);
  {$ENDIF}

  TLogEventsProvider = class (TLogProviderBase)
  private
    fOnAny : TLoggerEvent;
    fOnInfo : TLoggerEvent;
    fOnSuccess : TLoggerEvent;
    fOnWarning : TLoggerEvent;
    fOnError : TLoggerEvent;
    fOnCritical : TLoggerEvent;
    fOnException : TLoggerEvent;
    fOnDebug : TLoggerEvent;
    fOnTrace : TLoggerEvent;
    fOnCustom1 : TLoggerEvent;
    fOnCustom2 : TLoggerEvent;
  public
    constructor Create; override;
    destructor Destroy; override;
    property OnAny : TLoggerEvent read fOnAny write fOnAny;
    property OnInfo : TLoggerEvent read fOnInfo write fOnInfo;
    property OnSuccess : TLoggerEvent read fOnSuccess write fOnSuccess;
    property OnWarning : TLoggerEvent read fOnWarning write fOnWarning;
    property OnError : TLoggerEvent read fOnError write fOnError;
    property OnCritical : TLoggerEvent read fOnCritical write fOnCritical;
    property OnException : TLoggerEvent read fOnException write fOnException;
    property OnDebug : TLoggerEvent read fOnDebug write fOnDebug;
    property OnTrace : TLoggerEvent read fOnTrace write fOnTrace;
    property OnCustom1 : TLoggerEvent read fOnCustom1 write fOnCustom1;
    property OnCustom2 : TLoggerEvent read fOnCustom2 write fOnCustom2;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogEventsProvider : TLogEventsProvider;

implementation

constructor TLogEventsProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
end;

destructor TLogEventsProvider.Destroy;
begin
  fOnAny := nil;
  fOnInfo := nil;
  fOnWarning := nil;
  fOnError := nil;
  fOnDebug := nil;
  fOnTrace := nil;
  fOnSuccess := nil;
  fOnCritical := nil;
  fOnException := nil;
  fOnCustom1 := nil;
  fOnCustom2 := nil;
  inherited;
end;

procedure TLogEventsProvider.Init;
begin
  inherited;
end;

procedure TLogEventsProvider.Restart;
begin
  Stop;
  Init;
end;

procedure TLogEventsProvider.WriteLog(cLogItem : TLogItem);
begin
  case cLogItem.EventType of
    etInfo : if Assigned(fOnInfo) then fOnInfo(cLogItem);
    etSuccess : if Assigned(fOnSuccess) then fOnSuccess(cLogItem);
    etWarning : if Assigned(fOnWarning) then fOnWarning(cLogItem);
    etError : if Assigned(fOnError) then fOnError(cLogItem);
    etCritical : if Assigned(fOnCritical) then fOnCritical(cLogItem);
    etException : if Assigned(fOnException) then fOnException(cLogItem);
    etTrace : if Assigned(fOnTrace) then fOnTrace(cLogItem);
    etDebug : if Assigned(fOnDebug) then fOnDebug(cLogItem);
    etCustom1 : if Assigned(fOnCustom1) then fOnCustom1(cLogItem);
    etCustom2 : if Assigned(fOnCustom2) then fOnCustom2(cLogItem);
    else if cLogItem.EventType <> etHeader then
      raise ELogger.Create(Format('[TLogEventsProvider] : Not defined "%s" event',[EventTypeName[cLogItem.EventType]]));
  end;
  if Assigned(fOnAny) then fOnAny(cLogItem);
end;

initialization
  GlobalLogEventsProvider := TLogEventsProvider.Create;

finalization
  if Assigned(GlobalLogEventsProvider) and (GlobalLogEventsProvider.RefCount = 0) then GlobalLogEventsProvider.Free;

end.
