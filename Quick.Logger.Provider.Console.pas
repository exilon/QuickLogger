{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.Console
  Description : Log Console Provider
  Author      : Kike Pérez
  Version     : 1.22
  Created     : 12/10/2017
  Modified    : 24/04/2020

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
unit Quick.Logger.Provider.Console;

{$i QuickLib.inc}

interface

uses
  Classes,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  SysUtils,
  Quick.Commons,
  Quick.Console,
  Quick.Logger;

type

  {$IFDEF DELPHIXE7_UP}
  TEventTypeColors = array of TConsoleColor;
  {$ELSE}
  TEventTypeColors = array[0..11] of TConsoleColor;
  {$ENDIF}

const

  //Reference for TEventType = (etHeader, etInfo, etSuccess, etWarning, etError, etCritical, etException, etDebug, etTrace, etDone, etCustom1, etCustom2);
  {$IFDEF DELPHIXE7_UP}
  DEF_EVENTTYPECOLORS : TEventTypeColors = [ccLightGray {etHeader},
                                            ccWhite {etInfo},
                                            ccLightGreen {etSuccess},
                                            ccYellow {etWarning},
                                            ccLightRed {etError},
                                            ccYellow {etCritical},
                                            ccRed {etException},
                                            ccLightCyan {etDebug},
                                            ccLightMagenta {etTrace},
                                            ccGreen {etDone},
                                            ccCyan {etCustom1},
                                            ccCyan {etCustom2}
                                            ];
  {$ELSE}
  DEF_EVENTTYPECOLORS : TEventTypeColors = (ccLightGray {etHeader},
                                            ccWhite {etInfo},
                                            ccLightGreen {etSuccess},
                                            ccYellow {etWarning},
                                            ccLightRed {etError},
                                            ccYellow {etCritical},
                                            ccRed {etException},
                                            ccLightCyan {etDebug},
                                            ccLightMagenta {etTrace},
                                            ccGreen {etDone},
                                            ccCyan {etCustom1},
                                            ccCyan {etCustom2}
                                            );

  {$ENDIF}

  CR = #13;

type

  TLogConsoleProvider = class (TLogProviderBase)
  private
    fShowEventColors : Boolean;
    fShowTimeStamp : Boolean;
    fEventTypeColors : TEventTypeColors;
    fShowEventTypes : Boolean;
    fUnderlineHeaderEventType : Boolean;
    function GetEventTypeColor(cEventType : TEventType) : TConsoleColor;
    procedure SetEventTypeColor(cEventType: TEventType; cValue : TConsoleColor);
  public
    constructor Create; override;
    destructor Destroy; override;
    property ShowEventColors : Boolean read fShowEventColors write fShowEventColors;
    property ShowTimeStamp : Boolean read fShowTimeStamp write fShowTimeStamp;
    property ShowEventType : Boolean read fShowEventTypes write fShowEventTypes;
    property UnderlineHeaderEventType : Boolean read fUnderlineHeaderEventType write fUnderlineHeaderEventType;
    property EventTypeColor[cEventType : TEventType] : TConsoleColor read GetEventTypeColor write SetEventTypeColor;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogConsoleProvider : TLogConsoleProvider;

implementation

constructor TLogConsoleProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fShowEventTypes := False;
  fShowEventColors := True;
  fShowTimeStamp := False;
  fUnderlineHeaderEventType := False;
  fEventTypeColors := DEF_EVENTTYPECOLORS;
end;

destructor TLogConsoleProvider.Destroy;
begin
  inherited;
end;

function TLogConsoleProvider.GetEventTypeColor(cEventType: TEventType): TConsoleColor;
begin
  Result := fEventTypeColors[Integer(cEventType)];
end;

procedure TLogConsoleProvider.SetEventTypeColor(cEventType: TEventType; cValue : TConsoleColor);
begin
  fEventTypeColors[Integer(cEventType)] := cValue;
end;

procedure TLogConsoleProvider.Init;
begin
  {$IFDEF MSWINDOWS}
  //not enable if console not available
  if GetStdHandle(STD_OUTPUT_HANDLE) = 0 then
  begin
    Enabled := False;
    Exit;
  end;
  {$ENDIF}
  inherited;
end;

procedure TLogConsoleProvider.Restart;
begin
  Stop;
  Init;
end;

procedure TLogConsoleProvider.WriteLog(cLogItem : TLogItem);
begin
  if CustomMsgOutput then
  begin
    Writeln(LogItemToFormat(cLogItem){$IFDEF LINUX}+CR{$ENDIF});
    Exit;
  end;

  if fShowEventColors then
  begin
    //changes color for event
    if cLogItem.EventType = etCritical then TextBackground(ccRed)
      else TextColor(EventTypeColor[cLogItem.EventType]);

    {case cLogItem.EventType of
      etHeader : TextColor(ccLightGray);
      etInfo : TextColor(ccWhite);
      etSuccess : TextColor(ccLightGreen);
      etWarning : TextColor(ccYellow);
      etError : TextColor(ccLightRed);
      etCritical : begin TextColor(ccYellow); TextBackground(ccRed); end;
      etException : TextColor(ccRed);
      etDebug : TextColor(ccLightCyan);
      etTrace : TextColor(ccLightMagenta);
      else TextColor(ccWhite);
    end;}

    if cLogItem.EventType = etHeader then
    begin
      Writeln(cLogItem.Msg{$IFDEF LINUX}+CR{$ENDIF});
      if fUnderlineHeaderEventType then Writeln(FillStr('-',cLogItem.Msg.Length));
    end
    else
    begin
      //if fShowTimeStamp then Writeln(Format('%s %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),cLogItem.Msg{$IFDEF LINUX}+CR{$ENDIF}]))
      //  else Writeln(cLogItem.Msg{$IFDEF LINUX}+CR{$ENDIF});
      writeln(LogItemToLine(cLogItem,fShowTimeStamp,fShowEventTypes){$IFDEF LINUX}+CR{$ENDIF});
    end;

    ResetColors;
  end
  else
  begin
    TextColor(ccWhite);
    if fShowTimeStamp then Writeln(Format('%s [%s] %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),EventTypeName[cLogItem.EventType],cLogItem.Msg{$IFDEF LINUX}+CR{$ENDIF}]))
      else Writeln(Format('[%s] %s',[EventTypeName[cLogItem.EventType],cLogItem.Msg{$IFDEF LINUX}+CR{$ENDIF}]));
    if cLogItem.EventType = etHeader then Writeln(FillStr('-',cLogItem.Msg.Length));
  end;
end;

initialization
  GlobalLogConsoleProvider := TLogConsoleProvider.Create;

finalization

  if Assigned(GlobalLogConsoleProvider) and (GlobalLogConsoleProvider.RefCount = 0) then GlobalLogConsoleProvider.Free;

end.
