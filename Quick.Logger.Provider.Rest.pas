{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Rest
  Description : Log Api Rest Provider
  Author      : Kike Pérez
  Version     : 1.20
  Created     : 15/10/2017
  Modified    : 01/04/2018

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
unit Quick.Logger.Provider.Rest;

interface

uses
  Classes,
  System.SysUtils,
  {$IF CompilerVersion > 28}
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  System.JSON,
  {$ELSE}
  IdHTTP,
  Data.DBXJSON,
  {$ENDIF}
  Quick.Commons,
  Quick.Logger;

const
  DEF_USER_AGENT = 'Quick.Logger Agent';

type

  TLogRestProvider = class (TLogProviderBase)
  private
    {$IF CompilerVersion > 28}
    fHTTPClient : THTTPClient;
    {$ELSE}
    fHTTPClient : TIdHTTP;
    {$ENDIF}
    fURL : string;
    fUserAgent : string;
  public
    constructor Create; override;
    destructor Destroy; override;
    property URL : string read fURL write fURL;
    property UserAgent : string read fUserAgent write fUserAgent;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogRestProvider : TLogRestProvider;

implementation

constructor TLogRestProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fURL := '';
  fUserAgent := DEF_USER_AGENT;
end;

destructor TLogRestProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  inherited;
end;

procedure TLogRestProvider.Init;
begin
  {$IF CompilerVersion > 28}
  fHTTPClient := THTTPClient.Create;
  fHTTPClient.ContentType := 'text/json';
  fHTTPClient.UserAgent := fUserAgent;
  {$ELSE}
  fHTTPClient := TIdHTTP.Create(nil);
  fHTTPClient.Request.ContentType := 'text/json';
  fHTTPClient.Request.UserAgent := fUserAgent;
  {$ENDIF}
  fHTTPClient.HandleRedirects := True;
  inherited;
end;

procedure TLogRestProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogRestProvider.WriteLog(cLogItem : TLogItem);
var
  json : TJSONObject;
  {$IF CompilerVersion > 28}
  resp : IHTTPResponse;
  {$ELSE}
  resp : TIdHTTPResponse;
  {$ENDIF}
  ss : TStringStream;
begin
  ss := TStringStream.Create;
  try
    json := TJSONObject.Create;
    try
      json.AddPair('EventDate',DateTimeToStr(cLogItem.EventDate,FormatSettings));
      json.AddPair('EventType',IntToStr(Integer(cLogItem.EventType)));
      json.AddPair('Msg',cLogItem.Msg);
      {$IF CompilerVersion > 28}
      ss.WriteString(json.ToJSON);
      {$ELSE}
      ss.WriteString(json.ToString);
      {$ENDIF}
    finally
      json.Free;
    end;
    {$IF CompilerVersion > 28}
    resp := fHTTPClient.Post(fURL,ss,nil);
    {$ELSE}
    fHTTPClient.Post(fURL,ss,nil);
    resp := fHTTPClient.Response;
    {$ENDIF}
  finally
    ss.Free;
  end;
  {$IF CompilerVersion > 28}
  if resp.StatusCode <> 201 then
    raise ELogger.Create(Format('[TLogRestProvider] : Response %d : %s trying to post event',[resp.StatusCode,resp.StatusText]));
  {$ELSE}
  if resp.ResponseCode <> 201 then
    raise ELogger.Create(Format('[TLogRestProvider] : Response %d : %s trying to post event',[resp.ResponseCode,resp.ResponseText]));
  {$ENDIF}
end;

initialization
  GlobalLogRestProvider := TLogRestProvider.Create;

finalization
  if Assigned(GlobalLogRestProvider) and (GlobalLogRestProvider.RefCount = 0) then GlobalLogRestProvider.Free;

end.
