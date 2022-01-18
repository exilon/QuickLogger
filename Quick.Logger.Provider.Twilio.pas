{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.Twilio
  Description : Log Twilio Provider
  Author      : Kike Pérez
  Version     : 1.0
  Created     : 01/05/2020
  Modified    : 02/05/2020

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
unit Quick.Logger.Provider.Twilio;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  DateUtils,
  {$IFDEF FPC}
  fpjson,
  fpjsonrtti,
  IdURI,
  Quick.Base64,
  {$ELSE}
    {$IFDEF DELPHIXE8_UP}
    System.JSON,
    System.Net.URLClient,
    System.NetEncoding,
    {$ELSE}
    Data.DBXJSON,
    IdURI,
    Quick.Base64,
    {$ENDIF}
  {$ENDIF}
  Quick.HttpClient,
  Quick.Commons,
  Quick.Logger;

type

  TLogTwilioProvider = class (TLogProviderBase)
  private
    fHTTPClient : TJsonHTTPClient;
    fAccountSID : string;
    fAuthToken : string;
    fSendFrom : string;
    fSendTo : string;
    fFullURL : string;
    fConnectionTimeout : Integer;
    fResponseTimeout : Integer;
    fUserAgent : string;
  protected
    fHeaders : TPairList;
    function LogToTwilio(cLogItem: TLogItem): string;
  public
    constructor Create; override;
    destructor Destroy; override;
    property AccountSID : string read fAccountSID write fAccountSID;
    property AuthToken : string read fAuthToken write fAuthToken;
    property SendFrom : string read fSendFrom write fSendFrom;
    property SendTo : string read fSendTo write fSendTo;
    property UserAgent : string read fUserAgent write fUserAgent;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogTwilioProvider : TLogTwilioProvider;

implementation

const
  DEF_HTTPCONNECTION_TIMEOUT = 60000;
  DEF_HTTPRESPONSE_TIMEOUT = 60000;

constructor TLogTwilioProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fHeaders := TPairList.Create;
  fConnectionTimeout := DEF_HTTPCONNECTION_TIMEOUT;
  fResponseTimeout := DEF_HTTPRESPONSE_TIMEOUT;
  fUserAgent := DEF_USER_AGENT;
  IncludedInfo := [iiAppName,iiHost,iiEnvironment];
end;

destructor TLogTwilioProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  if Assigned(fHeaders) then fHeaders.Free;
  inherited;
end;

procedure TLogTwilioProvider.Init;
var
  auth : string;
  {$IFDEF DELPHIXE8_UP}
  base64 : TBase64Encoding;
  {$ENDIF}
begin
  fFullURL := Format('https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json',[fAccountSID]);
  fHTTPClient := TJsonHTTPClient.Create;
  fHTTPClient.ConnectionTimeout := fConnectionTimeout;
  fHTTPClient.ResponseTimeout := fResponseTimeout;
  fHTTPClient.ContentType := 'application/x-www-form-urlencoded';
  fHTTPClient.UserAgent := fUserAgent;
  fHTTPClient.HandleRedirects := True;
  fHeaders.Clear;
  {$IFDEF DELPHIXE8_UP}
  base64 := TBase64Encoding.Create(0);
  try
    auth := base64.Encode(fAccountSID + ':' + fAuthToken);
  finally
    base64.Free;
  end;
  {$ELSE}
  auth := Base64Encode(fAccountSID + ':' + fAuthToken);
  {$ENDIF}
  fHeaders.Add('Authorization','Basic ' + auth);
  inherited;
end;

function TLogTwilioProvider.LogToTwilio(cLogItem: TLogItem): string;
begin
  {$IFDEF DELPHIXE8_UP}
    {$IFDEF DELPHIRX10_UP}
    Result := 'Body=' + TNetEncoding.URL.Encode(LogItemToText(cLogItem))
    + '&From=' + TNetEncoding.URL.Encode(fSendFrom)
    + '&To=' + TNetEncoding.URL.Encode(fSendTo);
    {$ELSE}
    Result := 'Body=' + TURI.URLEncode(LogItemToText(cLogItem))
    + '&From=' + TURI.URLEncode(fSendFrom)
    + '&To=' + TURI.URLEncode(fSendTo);
    {$ENDIF}
  {$ELSE}
  Result := 'Body=' + TIdURI.URLEncode(LogItemToText(cLogItem))
    + '&From=' + TIdURI.URLEncode(fSendFrom)
    + '&To=' + TIdURI.URLEncode(fSendTo);
  {$ENDIF}
end;

procedure TLogTwilioProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogTwilioProvider.WriteLog(cLogItem : TLogItem);
var
  resp : IHttpRequestResponse;
begin
  if CustomMsgOutput then resp := fHTTPClient.Post(fFullURL,LogItemToFormat(cLogItem),fHeaders)
    else resp := fHTTPClient.Post(fFullURL,LogToTwilio(cLogItem),fHeaders);

  if not (resp.StatusCode in [200,201,202]) then
    raise ELogger.Create(Format('[TLogTwilioProvider] : Response %d : %s trying to post event (%s)',[resp.StatusCode,resp.StatusText,resp.Response.ToString]));
end;

initialization
  GlobalLogTwilioProvider := TLogTwilioProvider.Create;

finalization
  if Assigned(GlobalLogTwilioProvider) and (GlobalLogTwilioProvider.RefCount = 0) then GlobalLogTwilioProvider.Free;

end.
