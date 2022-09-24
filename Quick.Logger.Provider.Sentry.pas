{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.Sentry
  Description : Log Sentry Provider
  Author      : Kike Pérez
  Version     : 1.0
  Created     : 22/04/2020
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
unit Quick.Logger.Provider.Sentry;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  DateUtils,
  {$IFDEF FPC}
  fpjson,
  fpjsonrtti,
  Quick.Json.fpc.Compatibility,
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

  TLogSentryProvider = class (TLogProviderBase)
  private
    fHTTPClient : TJsonHTTPClient;
    fProtocol : string;
    fSentryHost : string;
    fProjectId : string;
    fPublicKey : string;
    fSentryVersion : string;
    fFullURL : string;
    fConnectionTimeout : Integer;
    fResponseTimeout : Integer;
    fUserAgent : string;
    function LogToSentry(cLogItem: TLogItem): string;
    function EventTypeToSentryLevel(aEventType : TEventType) : string;
    procedure SetDSNEntry(const Value: string);
    function GetProtocol: Boolean;
    procedure SetProtocol(const Value: Boolean);
  public
    constructor Create; override;
    destructor Destroy; override;
    property DSNKey : string write SetDSNEntry;
    property SentryVersion : string read fSentryVersion write fSentryVersion;
    property Secured : Boolean read GetProtocol write SetProtocol;
    property Host : string read fSentryHost write fSentryHost;
    property ProjectId : string read fProjectId write fProjectId;
    property PublicKey : string read fPublicKey write fPublicKey;
    property UserAgent : string read fUserAgent write fUserAgent;
    property JsonOutputOptions : TJsonOutputOptions read fJsonOutputOptions write fJsonOutputOptions;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogSentryProvider : TLogSentryProvider;

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

constructor TLogSentryProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fSentryVersion := '7';
  fJsonOutputOptions.UseUTCTime := False;
  fConnectionTimeout := DEF_HTTPCONNECTION_TIMEOUT;
  fResponseTimeout := DEF_HTTPRESPONSE_TIMEOUT;
  fUserAgent := DEF_USER_AGENT;
  IncludedInfo := [iiAppName,iiHost,iiEnvironment];
end;

destructor TLogSentryProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);

  inherited;
end;

procedure TLogSentryProvider.Init;
begin
  fFullURL := Format('%s://%s/api/%s/store/?sentry_key=%s&sentry_version=%s',[fProtocol,fSentryHost,fProjectId,fPublicKey,fSentryVersion]);
  fHTTPClient := TJsonHTTPClient.Create;
  fHTTPClient.ConnectionTimeout := fConnectionTimeout;
  fHTTPClient.ResponseTimeout := fResponseTimeout;
  fHTTPClient.ContentType := 'application/json';
  fHTTPClient.UserAgent := fUserAgent;
  fHTTPClient.HandleRedirects := True;
  inherited;
end;

function TLogSentryProvider.EventTypeToSentryLevel(aEventType : TEventType) : string;
begin
  case aEventType of
    etWarning : Result := 'warning';
    etError,
    etException : Result := 'error';
    etCritical : Result := 'fatal';
    etDebug,
    etTrace : Result := 'debug';
    else Result := 'info';
  end;
end;

function TLogSentryProvider.GetProtocol: Boolean;
begin
  Result := fProtocol.ToLower = 'https';
end;

procedure TLogSentryProvider.SetProtocol(const Value: Boolean);
begin
  if Value then fProtocol := 'https'
    else fProtocol := 'http';
end;

function TLogSentryProvider.LogToSentry(cLogItem: TLogItem): string;
var
  jsEvent : TJSONObject;
  jsMessage : TJSONObject;
  jsException : TJSONObject;
  jsUser : TJSONObject;
  jsTags : TJSONObject;
  tagName : string;
  tagValue : string;
  {$IFDEF FPC}
  json : TJSONObject;
  jarray : TJSONArray;
  {$ENDIF}
begin
  jsEvent := TJSONObject.Create;
  try
    {$IFDEF FPC}
      jsEvent.Add('timestamp',TJSONInt64Number.Create(DateTimeToUnix(cLogItem.EventDate)));
    {$ELSE}
      {$IFDEF DELPHIXE7_UP}
      jsEvent.AddPair('timestamp',TJSONNumber.Create(DateTimeToUnix(cLogItem.EventDate,fJsonOutputOptions.UseUTCTime)));
      {$ELSE}
      jsEvent.AddPair('timestamp',TJSONNumber.Create(DateTimeToUnix(cLogItem.EventDate)));
      {$ENDIF}
    {$ENDIF}
    jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('level',EventTypeToSentryLevel(cLogItem.EventType));
    jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('logger','QuickLogger');
    jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('platform','other');
    jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('server_name',SystemInfo.HostName);
    if iiEnvironment in IncludedInfo then jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('environment',Environment);

    if cLogItem.EventType = etException then
    begin
      jsException := TJSONObject.Create;
      jsException.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('type',EventTypeName[cLogItem.EventType]);
      jsException.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('value',cLogItem.Msg);
      if iiThreadId in IncludedInfo then jsException.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('thread_id',cLogItem.ThreadId.ToString);
      {$IFNDEF FPC}
      jsEvent.AddPair('exception',TJSONObject.Create(TJSONPair.Create('values',TJSONArray.Create(jsException))));
      {$ELSE}
      jarray := TJSONArray.Create;
      jarray.AddElement(jsException);
      json := TJSONObject.Create;
      json.AddPair(TJSONPair.Create('values',jarray));
      jsEvent.Add('exception',json);
      {$ENDIF}
    end
    else
    begin
      jsMessage := TJSONObject.Create;
      jsMessage.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('formatted',cLogItem.Msg);
      jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('message',jsMessage);
    end;

    jsTags := TJSONObject.Create;
    if iiAppName in IncludedInfo then jsTags.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('application',AppName);
    if iiPlatform in IncludedInfo then jsTags.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('platformtype',PlatformInfo);
    if iiOSVersion in IncludedInfo then jsTags.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('OS',SystemInfo.OSVersion);
    if iiProcessId in IncludedInfo then jsTags.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('pid',SystemInfo.ProcessId.ToString);
    for tagName in IncludedTags do
    begin
      if fCustomTags.TryGetValue(tagName,tagValue) then jsTags.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}(tagName,tagValue);
    end;
    jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('tags',jsTags);

    if iiUserName in IncludedInfo then
    begin
      jsUser := TJSONObject.Create;
      //jsUser.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('id',SystemInfo.UserName);
      jsUser.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('username',SystemInfo.UserName);
      jsEvent.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('user',jsUser);
    end;

    {$IFDEF DELPHIXE8_UP}
    Result := jsEvent.ToJSON
    {$ELSE}
      {$IFDEF FPC}
      Result := jsEvent.AsJSON;
      {$ELSE}
      Result := jsEvent.ToString;
      {$ENDIF}
    {$ENDIF}
  finally
    jsEvent.Free;
  end;
end;

procedure TLogSentryProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogSentryProvider.SetDSNEntry(const Value: string);
var
  segments : TArray<string>;
begin
  segments := value.Split(['/','@']);
  try
    fProtocol := segments[0].Replace(':','');
    fPublicKey := segments[2];
    fSentryHost := segments[3];
    fProjectId := segments[4];
  except
    raise Exception.Create('Sentry DSN not valid!');
  end;
end;

procedure TLogSentryProvider.WriteLog(cLogItem : TLogItem);
var
  resp : IHttpRequestResponse;
begin
  if CustomMsgOutput then resp := fHTTPClient.Post(fFullURL,LogItemToFormat(cLogItem))
    else resp := fHTTPClient.Post(fFullURL,LogToSentry(cLogItem));

  if not (resp.StatusCode in [200,201,202]) then
    raise ELogger.Create(Format('[TLogSentryProvider] : Response %d : %s trying to post event',[resp.StatusCode,resp.StatusText]));
end;

initialization
  GlobalLogSentryProvider := TLogSentryProvider.Create;

finalization
  if Assigned(GlobalLogSentryProvider) and (GlobalLogSentryProvider.RefCount = 0) then GlobalLogSentryProvider.Free;

end.
