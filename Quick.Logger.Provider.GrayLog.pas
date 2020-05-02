{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.GrayLog
  Description : Log GrayLog Provider
  Author      : Kike Pérez
  Version     : 1.2
  Created     : 15/03/2019
  Modified    : 25/04/2020

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
unit Quick.Logger.Provider.GrayLog;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  DateUtils,
  {$IFDEF FPC}
  fpjson,
  fpjsonrtti,
  {$ELSE}
    {$IFDEF DELPHIXE8_UP}
    System.JSON,
    {$ELSE}
    Data.DBXJSON,
    {$ENDIF}
  {$ENDIF}
  Quick.HttpClient,
  Quick.Commons,
  Quick.Logger;

type

  TLogGrayLogProvider = class (TLogProviderBase)
  private
    fHTTPClient : TJsonHTTPClient;
    fURL : string;
    fFullURL : string;
    fGrayLogVersion : string;
    fShortMessageAsEventType : Boolean;
    fConnectionTimeout : Integer;
    fResponseTimeout : Integer;
    fUserAgent : string;
    function LogToGELF(cLogItem: TLogItem): string;
    function EventTypeToSysLogLevel(aEventType : TEventType) : Integer;
  public
    constructor Create; override;
    destructor Destroy; override;
    property URL : string read fURL write fURL;
    property GrayLogVersion : string read fGrayLogVersion write fGrayLogVersion;
    property ShortMessageAsEventType : Boolean read fShortMessageAsEventType write fShortMessageAsEventType;
    property UserAgent : string read fUserAgent write fUserAgent;
    property JsonOutputOptions : TJsonOutputOptions read fJsonOutputOptions write fJsonOutputOptions;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogGrayLogProvider : TLogGrayLogProvider;

implementation

const
  DEF_HTTPCONNECTION_TIMEOUT = 60000;
  DEF_HTTPRESPONSE_TIMEOUT = 60000;

type
  TSyslogSeverity = (slEmergency, {0 - emergency - system unusable}
              slAlert, {1 - action must be taken immediately }
              slCritical, { 2 - critical conditions }
              slError, {3 - error conditions }
              slWarning, {4 - warning conditions }
              slNotice, {5 - normal but signification condition }
              slInformational, {6 - informational }
              slDebug); {7 - debug-level messages }

constructor TLogGrayLogProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fURL := 'http://localhost:12201';
  fGrayLogVersion := '2.1';
  fShortMessageAsEventType := False;
  fJsonOutputOptions.UseUTCTime := False;
  fConnectionTimeout := DEF_HTTPCONNECTION_TIMEOUT;
  fResponseTimeout := DEF_HTTPRESPONSE_TIMEOUT;
  fUserAgent := DEF_USER_AGENT;
  IncludedInfo := [iiAppName,iiHost,iiEnvironment];
end;

destructor TLogGrayLogProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);

  inherited;
end;

procedure TLogGrayLogProvider.Init;
begin
  fFullURL := Format('%s/gelf',[fURL]);
  fHTTPClient := TJsonHTTPClient.Create;
  fHTTPClient.ConnectionTimeout := fConnectionTimeout;
  fHTTPClient.ResponseTimeout := fResponseTimeout;
  fHTTPClient.ContentType := 'application/json';
  fHTTPClient.UserAgent := fUserAgent;
  fHTTPClient.HandleRedirects := True;
  inherited;
end;

function TLogGrayLogProvider.EventTypeToSysLogLevel(aEventType : TEventType) : Integer;
begin
  case aEventType of
    etHeader: Result := Integer(TSyslogSeverity.slInformational);
    etInfo: Result := Integer(TSyslogSeverity.slInformational);
    etSuccess: Result := Integer(TSyslogSeverity.slNotice);
    etWarning: Result := Integer(TSyslogSeverity.slWarning);
    etError: Result := Integer(TSyslogSeverity.slError);
    etCritical: Result := Integer(TSyslogSeverity.slCritical);
    etException: Result := Integer(TSyslogSeverity.slAlert);
    etDebug: Result := Integer(TSyslogSeverity.slDebug);
    etTrace: Result := Integer(TSyslogSeverity.slInformational);
    etDone: Result := Integer(TSyslogSeverity.slNotice);
    etCustom1: Result := Integer(TSyslogSeverity.slEmergency);
    etCustom2: Result := Integer(TSyslogSeverity.slInformational);
    else Result := Integer(TSyslogSeverity.slInformational);
  end;
end;

function TLogGrayLogProvider.LogToGELF(cLogItem: TLogItem): string;
var
  json : TJSONObject;
  tagName : string;
  tagValue : string;
begin
  json := TJSONObject.Create;
  try
    json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('version',fGrayLogVersion);
    json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('host',SystemInfo.HostName);
    if fShortMessageAsEventType then
    begin
      json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('short_message',EventTypeName[cLogItem.EventType]);
      json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('full_message',cLogItem.Msg);
    end
    else
    begin
      json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('type',EventTypeName[cLogItem.EventType]);
      json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('short_message',cLogItem.Msg);
    end;
    {$IFDEF FPC}
      json.Add('timestamp',TJSONInt64Number.Create(DateTimeToUnix(cLogItem.EventDate)));
      json.Add('level',TJSONInt64Number.Create(EventTypeToSysLogLevel(cLogItem.EventType)));
    {$ELSE}
      {$IFDEF DELPHIXE7_UP}
      json.AddPair('timestamp',TJSONNumber.Create(DateTimeToUnix(cLogItem.EventDate,fJsonOutputOptions.UseUTCTime)));
      {$ELSE}
      json.AddPair('timestamp',TJSONNumber.Create(DateTimeToUnix(cLogItem.EventDate)));
      {$ENDIF}
      json.AddPair('level',TJSONNumber.Create(EventTypeToSysLogLevel(cLogItem.EventType)));
    {$ENDIF}

    if iiAppName in IncludedInfo then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('_application',AppName);
    if iiEnvironment in IncludedInfo then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('_environment',Environment);
    if iiPlatform in IncludedInfo then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('_platform',PlatformInfo);
    if iiOSVersion in IncludedInfo then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('_OS',SystemInfo.OSVersion);
    if iiUserName in IncludedInfo then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('_user',SystemInfo.UserName);
    if iiThreadId in IncludedInfo then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('_treadid',cLogItem.ThreadId.ToString);
    if iiProcessId in IncludedInfo then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('_pid',SystemInfo.ProcessId.ToString);

    for tagName in IncludedTags do
    begin
      if fCustomTags.TryGetValue(tagName,tagValue) then json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}(tagName,tagValue);
    end;

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

procedure TLogGrayLogProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogGrayLogProvider.WriteLog(cLogItem : TLogItem);
var
  resp : IHttpRequestResponse;
begin
  if CustomMsgOutput then resp := fHTTPClient.Post(fFullURL,LogItemToFormat(cLogItem))
    else resp := fHTTPClient.Post(fFullURL,LogToGELF(cLogItem));

  if not (resp.StatusCode in [200,201,202]) then
    raise ELogger.Create(Format('[TLogGrayLogProvider] : Response %d : %s trying to post event',[resp.StatusCode,resp.StatusText]));
end;

initialization
  GlobalLogGrayLogProvider := TLogGrayLogProvider.Create;

finalization
  if Assigned(GlobalLogGrayLogProvider) and (GlobalLogGrayLogProvider.RefCount = 0) then GlobalLogGrayLogProvider.Free;

end.
