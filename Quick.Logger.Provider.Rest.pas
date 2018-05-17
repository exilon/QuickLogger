{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Rest
  Description : Log Api Rest Provider
  Author      : Kike Pérez
  Version     : 1.21
  Created     : 15/10/2017
  Modified    : 17/05/2018

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

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  {$IFDEF DELPHIXE8_UP}
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  {$ELSE}
  IdHTTP,
  {$ENDIF DELPHIXE8_UP}
  Quick.Commons,
  Quick.Logger;

const
  DEF_USER_AGENT = 'Quick.Logger Agent';

type

  TLogRestProvider = class (TLogProviderBase)
  private
    {$IFDEF DELPHIXE8_UP}
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
  IncludedInfo := [iiAppName,iiHost];
end;

destructor TLogRestProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);

  inherited;
end;

procedure TLogRestProvider.Init;
begin
  {$IFDEF DELPHIXE8_UP}
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
  {$IFDEF DELPHIXE8_UP}
  resp : IHTTPResponse;
  {$ELSE}
  resp : TIdHTTPResponse;
    {$IFDEF FPC}
    rs : TStringStream;
    {$ENDIF}
  {$ENDIF}
  ss : TStringStream;
begin
  ss := TStringStream.Create;
  try
    ss.WriteString(LogItemToJson(cLogItem,False));
    {$IFDEF DELPHIXE8_UP}
    resp := fHTTPClient.Post(fURL,ss,nil);
    {$ELSE}
      {$IFDEF FPC}
      rs := TStringStream.Create;
      try
        fHTTPClient.Post(fURL,ss,rs);
      finally
        rs.Free;
      end;
      {$ELSE}
      fHTTPClient.Post(fURL,ss,nil);
      {$ENDIF}
    resp := fHTTPClient.Response;
    {$ENDIF}
  finally
    ss.Free;
  end;
  {$IFDEF DELPHIXE8_UP}
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
