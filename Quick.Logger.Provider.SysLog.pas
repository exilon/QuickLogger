{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.SysLog
  Description : Log to SysLog server
  Author      : Kike Pérez
  Version     : 1.22
  Created     : 15/06/2018
  Modified    : 14/09/2019

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
unit Quick.Logger.Provider.SysLog;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  IdSysLog,
  IdSysLogMessage,
  Quick.Commons,
  Quick.Logger;

type
  TSyslogFacility = TIdSyslogFacility;

  TLogSysLogProvider = class (TLogProviderBase)
  private
    fHost : string;
    fPort : Integer;
    fSysLog : TIdSysLog;
    fFacility : TSyslogFacility;
  public
    constructor Create; override;
    destructor Destroy; override;
    property Host : string read fHost write fHost;
    property Port : Integer read fPort write fPort;
    property Facility : TSyslogFacility read fFacility write fFacility;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogSysLogProvider : TLogSysLogProvider;

implementation

constructor TLogSysLogProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fHost := '127.0.0.1';
  fPort := 514;
  fFacility := TSyslogFacility.sfUserLevel;
end;

destructor TLogSysLogProvider.Destroy;
begin
  if Assigned(fSysLog) then
  begin
    try
      if fSysLog.Connected then fSysLog.Disconnect;
    except
      //hide disconnection excepts
    end;
    fSysLog.Free;
  end;
  inherited;
end;

procedure TLogSysLogProvider.Init;
begin
  inherited;
  fSysLog := TIdSysLog.Create(nil);
  fSysLog.Host := fHost;
  fSysLog.Port := fPort;
  try
    fSysLog.Connect;
  except
    on E : Exception do raise Exception.CreateFmt('SysLogProvider: %s',[e.message]);
  end;
end;

procedure TLogSysLogProvider.Restart;
begin
  Stop;
  if Assigned(fSysLog) then
  begin
    if fSysLog.Connected then fSysLog.Disconnect;
    fSysLog.Free;
  end;
  Init;
end;

procedure TLogSysLogProvider.WriteLog(cLogItem : TLogItem);
var
  msg : TIdSysLogMessage;
begin
  if not fSysLog.Connected then fSysLog.Connect;

  msg := TIdSysLogMessage.Create(nil);
  try
    msg.TimeStamp := cLogItem.EventDate;
    msg.Hostname := SystemInfo.HostName;
    msg.Facility := fFacility;
    msg.Msg.Process := SystemInfo.AppName;
    case cLogItem.EventType of
      etHeader: msg.Severity := TIdSyslogSeverity.slInformational;
      etInfo: msg.Severity := TIdSyslogSeverity.slInformational;
      etSuccess: msg.Severity := TIdSyslogSeverity.slNotice;
      etWarning: msg.Severity := TIdSyslogSeverity.slWarning;
      etError: msg.Severity := TIdSyslogSeverity.slError;
      etCritical: msg.Severity := TIdSyslogSeverity.slCritical;
      etException: msg.Severity := TIdSyslogSeverity.slAlert;
      etDebug: msg.Severity := TIdSyslogSeverity.slDebug;
      etTrace: msg.Severity := TIdSyslogSeverity.slInformational;
      etDone: msg.Severity := TIdSyslogSeverity.slNotice;
      etCustom1: msg.Severity := TIdSyslogSeverity.slEmergency;
      etCustom2: msg.Severity := TIdSyslogSeverity.slInformational;
    end;
    if CustomMsgOutput then msg.Msg.Text := cLogItem.Msg
      else msg.Msg.Text := LogItemToLine(cLogItem,False,True);
    fSysLog.SendLogMessage(msg,False);
  finally
    msg.Free;
  end;
end;

initialization
  GlobalLogSysLogProvider := TLogSysLogProvider.Create;

finalization
  if Assigned(GlobalLogSysLogProvider) and (GlobalLogSysLogProvider.RefCount = 0) then GlobalLogSysLogProvider.Free;

end.
