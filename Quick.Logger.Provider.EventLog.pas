{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.EventLog
  Description : Log Windows EventLog Provider
  Author      : Kike Pérez
  Version     : 1.22
  Created     : 02/10/2017
  Modified    : 02/03/2020

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
unit Quick.Logger.Provider.EventLog;

{$i QuickLib.inc}

interface

uses
  Classes,
  Windows,
  {$IFNDEF MSWINDOWS}
  Only compatible with Microsoft Windows
  {$ENDIF}
  SysUtils,
  Quick.Commons,
  Quick.Logger;

type

  TLogEventLogProvider = class (TLogProviderBase)
  private
    fSource : string;
  public
    constructor Create; override;
    destructor Destroy; override;
    property Source : string read fSource write fSource;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

{$IFDEF FPC}
const
  EVENTLOG_SUCCESS = 0;
{$ENDIF}

var
  GlobalLogEventLogProvider : TLogEventLogProvider;

implementation

constructor TLogEventLogProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fSource := ExtractFileNameWithoutExt(ParamStr(0));
end;

destructor TLogEventLogProvider.Destroy;
begin
  inherited;
end;

procedure TLogEventLogProvider.Init;
begin
  inherited;
end;

procedure TLogEventLogProvider.Restart;
begin
  Stop;
  Init;
end;

procedure TLogEventLogProvider.WriteLog(cLogItem : TLogItem);
var
  h: THandle;
  p : Pointer;
  eType : Integer;
begin
  p := PWideChar(cLogItem.Msg);
  h := RegisterEventSource(nil,{$IFDEF FPC}PChar{$ELSE}PWideChar{$ENDIF}(fSource));
  try
    case cLogItem.EventType of
      etSuccess,
      etDone : eType := EVENTLOG_SUCCESS;
      etWarning : eType := EVENTLOG_WARNING_TYPE;
      etError,
      etCritical,
      etException : eType := EVENTLOG_ERROR_TYPE;
      else eType := EVENTLOG_INFORMATION_TYPE;
    end;
    if h <> 0 then
    begin
      ReportEvent(h,
          eType, //event type
          0,  //category
          0, //event id
          nil, //user security id
          1, //one substitution string
          0, //data
          @p, //pointer to msg
          nil); //pointer to data
    end;
  finally
    DeregisterEventSource(h);
  end;
end;

initialization
  GlobalLogEventLogProvider := TLogEventLogProvider.Create;

finalization
  if Assigned(GlobalLogEventLogProvider) and (GlobalLogEventLogProvider.RefCount = 0) then GlobalLogEventLogProvider.Free;

end.
