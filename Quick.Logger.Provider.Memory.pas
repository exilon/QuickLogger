{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Memory
  Description : Log memory Provider
  Author      : Kike Pérez
  Version     : 1.19
  Created     : 02/10/2017
  Modified    : 08/11/2017

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
unit Quick.Logger.Provider.Memory;

interface

uses
  Classes,
  Windows,
  System.SysUtils,
  System.Generics.Collections,
  Quick.Commons,
  Quick.Logger;

type

  TMemLog = TObjectList<TLogItem>;

  TLogMemoryProvider = class (TLogProviderBase)
  private
    fMemLog : TMemLog;
    fMaxSize : Int64;
  public
    constructor Create; override;
    destructor Destroy; override;
    property MemLog : TMemLog read fMemLog write fMemLog;
    property MaxSize : Int64 read fMaxSize write fMaxSize;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
    function AsStrings : TStrings;
    function AsString : string;
    procedure Clear;
  end;

var
  GlobalLogMemoryProvider : TLogMemoryProvider;

implementation

var
  CS : TRTLCriticalSection;

constructor TLogMemoryProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fMaxSize := 0;
  InitializeCriticalSection(CS);
end;

destructor TLogMemoryProvider.Destroy;
begin
  EnterCriticalSection(CS);
  try
    if Assigned(fMemLog) then fMemLog.Free;
  finally
    LeaveCriticalSection(CS);
  end;
  DeleteCriticalSection(CS);
  inherited;
end;

procedure TLogMemoryProvider.Init;
begin
  fMemLog := TMemLog.Create(True);
  inherited;
end;

procedure TLogMemoryProvider.Restart;
begin
  Stop;
  EnterCriticalSection(CS);
  try
    if Assigned(fMemLog) then fMemLog.Free;
  finally
    LeaveCriticalSection(CS);
  end;
  Init;
end;

procedure TLogMemoryProvider.WriteLog(cLogItem : TLogItem);
begin
  EnterCriticalSection(CS);
  try
    if fMaxSize > 0 then
    begin
      repeat fMemLog.Delete(0) until fMemLog.Count < fMaxSize;
    end;
    fMemLog.Add(cLogItem.Clone);
  finally
    LeaveCriticalSection(CS);
  end;
end;

function TLogMemoryProvider.AsStrings : TStrings;
var
  lItem : TLogItem;
begin
  Result := TStringList.Create;
  if not Assigned(fMemLog) then Exit;
  EnterCriticalSection(CS);
  try
    for lItem in fMemLog do Result.Add(Format('%s [%s] %s',[DateTimeToStr(lItem.EventDate,FormatSettings),EventTypeName[lItem.EventType],lItem.Msg]));
  finally
    LeaveCriticalSection(CS);
  end;
end;

function TLogMemoryProvider.AsString : string;
var
  sl : TStrings;
begin
  sl := AsStrings;
  try
    Result := sl.Text;
  finally
    sl.Free;
  end;
end;

procedure TLogMemoryProvider.Clear;
begin
  EnterCriticalSection(CS);
  try
    fMemLog.Clear;
  finally
    LeaveCriticalSection(CS);
  end;
end;

initialization
  GlobalLogMemoryProvider := TLogMemoryProvider.Create;

finalization
  if Assigned(GlobalLogMemoryProvider) and (GlobalLogMemoryProvider.RefCount = 0) then GlobalLogMemoryProvider.Free;

end.
