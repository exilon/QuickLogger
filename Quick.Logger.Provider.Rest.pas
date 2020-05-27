{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.Rest
  Description : Log Api Rest Provider
  Author      : Kike Pérez
  Version     : 1.23
  Created     : 15/10/2017
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
unit Quick.Logger.Provider.Rest;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  Quick.HttpClient,
  Quick.Commons,
  Quick.Logger;

type

  TLogRestProvider = class (TLogProviderBase)
  private
    fHTTPClient : TJsonHTTPClient;
    fURL : string;
    fUserAgent : string;
  public
    constructor Create; override;
    destructor Destroy; override;
    property URL : string read fURL write fURL;
    property UserAgent : string read fUserAgent write fUserAgent;
    property JsonOutputOptions : TJsonOutputOptions read fJsonOutputOptions write fJsonOutputOptions;
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
  fHTTPClient := TJsonHTTPClient.Create;
  fHTTPClient.ContentType := 'application/json';
  fHTTPClient.UserAgent := fUserAgent;
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
  resp : IHttpRequestResponse;
begin
  if CustomMsgOutput then resp := fHTTPClient.Post(fURL,LogItemToFormat(cLogItem))
    else resp := fHTTPClient.Post(fURL,LogItemToJson(cLogItem));

  if not (resp.StatusCode in [200,201]) then
    raise ELogger.Create(Format('[TLogRestProvider] : Response %d : %s trying to post event',[resp.StatusCode,resp.StatusText]));
end;

initialization
  GlobalLogRestProvider := TLogRestProvider.Create;

finalization
  if Assigned(GlobalLogRestProvider) and (GlobalLogRestProvider.RefCount = 0) then GlobalLogRestProvider.Free;

end.
