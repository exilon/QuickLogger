{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.Slack
  Description : Log Slack Bot Channel Provider
  Author      : Kike Pérez
  Version     : 1.22
  Created     : 24/05/2018
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
unit Quick.Logger.Provider.Slack;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  {$IFDEF DELPHIXE8_UP}
  System.JSON,
  {$ELSE}
  IdHTTP,
    {$IFDEF FPC}
    fpjson,
    {$ELSE}
      {$IFDEF DELPHIXE7_UP}
      System.JSON,
      {$ENDIF}
    Data.DBXJSON,
    {$ENDIF}
  {$ENDIF}
  Quick.Commons,
  Quick.HttpClient,
  Quick.Logger;

const
  SLACKWEBHOOKURL = 'https://hooks.slack.com/services/%s';

type

  TSlackChannelType = (tcPublic, tcPrivate);

  TLogSlackProvider = class (TLogProviderBase)
  private
    fHttpClient : TJsonHttpClient;
    fChannelName : string;
    fUserName : string;
    fWebHookURL : string;
    procedure SetChannelName(const Value: string);
  public
    constructor Create; override;
    destructor Destroy; override;
    property ChannelName : string read fChannelName write SetChannelName;
    property UserName : string read fUserName write fUserName;
    property WebHookURL : string read fWebHookURL write fWebHookURL;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogSlackProvider : TLogSlackProvider;

implementation

constructor TLogSlackProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fChannelName := '';
  fWebHookURL := '';
  IncludedInfo := [iiAppName,iiHost];
end;

destructor TLogSlackProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);

  inherited;
end;

procedure TLogSlackProvider.Init;
begin
  fHTTPClient := TJsonHttpClient.Create;
  fHTTPClient.ContentType := 'application/json';
  fHTTPClient.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36';
  fHTTPClient.HandleRedirects := True;
  inherited;
end;

procedure TLogSlackProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogSlackProvider.SetChannelName(const Value: string);
begin
  if Value.StartsWith('#') then fChannelName := Value
    else fChannelName := '#' + Value;
end;

procedure TLogSlackProvider.WriteLog(cLogItem : TLogItem);
var
  json : TJsonObject;
  resp : IHttpRequestResponse;
begin
  if CustomMsgOutput then resp := fHttpClient.Post(fWebHookURL,LogItemToFormat(cLogItem))
  else
  begin
    json := TJSONObject.Create;
    try
      json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('text',LogItemToText(cLogItem));
      json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('username',fUserName);
      json.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('channel',fChannelName);
      resp := fHttpClient.Post(fWebHookURL,json);
    finally
      json.Free;
    end;
  end;
  if resp.StatusCode <> 200 then
    raise ELogger.Create(Format('[TLogSlackProvider] : Response %d : %s (%s) trying to send event',[resp.StatusCode,resp.StatusText,
    {$IFDEF DELPHIXE8_UP}
   resp.Response.ToJSON]));
  {$ELSE}
    {$IFDEF FPC}
     resp.Response.AsJson]));
    {$ELSE}
     resp.Response.ToString]));
    {$ENDIF}
  {$ENDIF}
end;

initialization
  GlobalLogSlackProvider := TLogSlackProvider.Create;

finalization
  if Assigned(GlobalLogSlackProvider) and (GlobalLogSlackProvider.RefCount = 0) then GlobalLogSlackProvider.Free;

end.
