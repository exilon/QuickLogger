{ ***************************************************************************

  Copyright (c) 2016-2022 Kike Pérez / Jens Fudickar

  Unit        : Quick.Logger.Provider.StringList
  Description : Log StringList Provider
  Author      : Jens Fudickar
  Version     : 1.23
  Created     : 12/28/2023
  Modified    : 12/28/2023

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
unit Quick.Logger.Provider.StringList;

interface

{$I QuickLib.inc}

uses
  System.Classes,
{$IFDEF MSWINDOWS}
  WinApi.Windows,
{$IFDEF DELPHIXE8_UP}
  Quick.Json.Serializer,
{$ENDIF}
{$ENDIF}
{$IFDEF DELPHILINUX}
  Quick.SyncObjs.Linux.Compatibility,
{$ENDIF}
  System.SysUtils,
  Generics.Collections,
  Quick.Commons,
  Quick.Logger;

type

  TLogStringListProvider = class(TLogProviderBase)
  private
    fintLogList: TStrings;
    fLogList: TStrings;
    fMaxSize: Int64;
    fShowEventTypes: Boolean;
    fShowTimeStamp: Boolean;
    function GetLogList: TStrings;
  public
    constructor Create; override;
    destructor Destroy; override;
{$IFDEF DELPHIXE8_UP}[TNotSerializableProperty]
{$ENDIF}
    property LogList: TStrings read GetLogList write fLogList;
    property MaxSize: Int64 read fMaxSize write fMaxSize;
    property ShowEventTypes: Boolean read fShowEventTypes write fShowEventTypes;
    property ShowTimeStamp: Boolean read fShowTimeStamp write fShowTimeStamp;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog (cLogItem: TLogItem); override;
    procedure Clear;
  end;

var
  GlobalLogStringListProvider: TLogStringListProvider;

implementation

var
  CS: TRTLCriticalSection;

constructor TLogStringListProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fMaxSize := 0;
{$IF Defined(MSWINDOWS) OR Defined(DELPHILINUX)}
  InitializeCriticalSection (CS);
{$ELSE}
  InitCriticalSection (CS);
{$ENDIF}
  fShowEventTypes := False;
  fShowTimeStamp := False;
  fintLogList := TStringList.Create;
end;

destructor TLogStringListProvider.Destroy;
begin
  EnterCriticalSection (CS);
  try
    if Assigned (fintLogList) then
      fintLogList.Free;
  finally
    LeaveCriticalSection (CS);
  end;
{$IF Defined(MSWINDOWS) OR Defined(DELPHILINUX)}
  DeleteCriticalSection (CS);
{$ELSE}
  DoneCriticalsection (CS);
{$ENDIF}
  inherited;
end;

procedure TLogStringListProvider.Init;
begin
  fintLogList := TStringList.Create;
  inherited;
end;

procedure TLogStringListProvider.Restart;
begin
  Stop;
  Clear;
  EnterCriticalSection (CS);
  try
    if Assigned (fintLogList) then
      fintLogList.Free;
  finally
    LeaveCriticalSection (CS);
  end;
  Init;
end;

procedure TLogStringListProvider.WriteLog (cLogItem: TLogItem);
begin
  EnterCriticalSection (CS);
  LogList.BeginUpdate;
  try
    if fMaxSize > 0 then
    begin
      while LogList.Count >= fMaxSize do
        LogList.Delete (0);
    end;
    if CustomMsgOutput then
      LogList.AddObject (LogItemToFormat(cLogItem), cLogItem.Clone)
    else
    begin
      LogList.AddObject (LogItemToLine(cLogItem, fShowTimeStamp, fShowEventTypes), cLogItem.Clone);
      if cLogItem.EventType = etHeader then
        LogList.Add (FillStr('-', cLogItem.Msg.Length));
    end;
  finally
    LogList.EndUpdate;
    LeaveCriticalSection (CS);
  end;
end;

procedure TLogStringListProvider.Clear;
begin
  EnterCriticalSection (CS);
  try
    LogList.Clear;
  finally
    LeaveCriticalSection (CS);
  end;
end;

function TLogStringListProvider.GetLogList: TStrings;
begin
  if Assigned (fLogList) then
    Result := fLogList
  else
    Result := fintLogList;
end;

initialization

GlobalLogStringListProvider := TLogStringListProvider.Create;

finalization

if Assigned (GlobalLogStringListProvider) and (GlobalLogStringListProvider.RefCount = 0) then
  GlobalLogStringListProvider.Free;

end.
