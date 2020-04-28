{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.Logger.Provider.IDEDebug
  Description : Log Output IDE Debug log Provider
  Author      : Kike Pérez
  Version     : 1.25
  Created     : 02/10/2017
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
unit Quick.Logger.Provider.IDEDebug;

{$i QuickLib.inc}

interface

uses
  Classes,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ELSE}
    {$IFNDEF DELPHILINUX}
    FMX.Types,
    {$ENDIF}
  {$ENDIF}
  SysUtils,
  Quick.Commons,
  Quick.Logger;

type

  TLogIDEDebugProvider = class (TLogProviderBase)
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogIDEDebugProvider : TLogIDEDebugProvider;

implementation

constructor TLogIDEDebugProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
end;

destructor TLogIDEDebugProvider.Destroy;
begin
  inherited;
end;

procedure TLogIDEDebugProvider.Init;
begin
  inherited;
end;

procedure TLogIDEDebugProvider.Restart;
begin
  Stop;
  Init;
end;

{$IFDEF MSWINDOWS}
procedure TLogIDEDebugProvider.WriteLog(cLogItem : TLogItem);
begin
  if CustomMsgOutput then OutputDebugString(PChar(LogItemToFormat(cLogItem)))
    else OutputDebugString(PChar(LogItemToLine(cLogItem,False,True)));
end;
{$ELSE}
procedure TLogIDEDebugProvider.WriteLog(cLogItem : TLogItem);
begin
  {$IFNDEF DELPHILINUX}
  if CustomMsgOutput then FMX.Types.Log.d(cLogItem.Msg)
    else FMX.Types.Log.d(LogItemToLine(cLogItem,False,True));
  {$ENDIF}
end;
{$ENDIF}

initialization
  GlobalLogIDEDebugProvider := TLogIDEDebugProvider.Create;

finalization
  if Assigned(GlobalLogIDEDebugProvider) and (GlobalLogIDEDebugProvider.RefCount = 0) then GlobalLogIDEDebugProvider.Free;

end.
