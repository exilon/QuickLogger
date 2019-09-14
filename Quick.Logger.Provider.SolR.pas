{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.Logger.Provider.Rest
  Description : Log Api SolR Provider
  Author      : Kike Pérez
  Version     : 1.22
  Created     : 15/10/2017
  Modified    : 23/02/2019

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
unit Quick.Logger.Provider.SolR;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  Quick.HttpClient,
  Quick.Commons,
  System.Json,
  Quick.Logger;

type

  TLogSolrProvider = class (TLogProviderBase)
  private
    fHTTPClient : TJsonHTTPClient;
    fURL : string;
    fFullURL : string;
    fCollection : string;
    fUserAgent : string;
    procedure CreateCollection(const aName : string);
    function ExistsCollection(const aName : string) : Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    property URL : string read fURL write fURL;
    property Collection : string read fCollection write fCollection;
    property UserAgent : string read fUserAgent write fUserAgent;
    property JsonOutputOptions : TJsonOutputOptions read fJsonOutputOptions write fJsonOutputOptions;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogSolrProvider : TLogSolrProvider;

implementation

constructor TLogSolrProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fURL := 'http://localhost:8983/solr';
  fCollection := 'logger';
  fUserAgent := DEF_USER_AGENT;
  IncludedInfo := [iiAppName,iiHost,iiEnvironment];
end;

destructor TLogSolrProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);

  inherited;
end;

procedure TLogSolrProvider.Init;
begin
  fFullURL := Format('%s/solr',[fURL]);
  fHTTPClient := TJsonHTTPClient.Create;
  fHTTPClient.ContentType := 'application/json';
  fHTTPClient.UserAgent := fUserAgent;
  fHTTPClient.HandleRedirects := True;
  if not ExistsCollection(fCollection) then CreateCollection(fCollection);
  inherited;
end;

procedure TLogSolrProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogSolrProvider.CreateCollection(const aName : string);
var
  resp : IHttpRequestResponse;
begin        exit;
  resp := fHTTPClient.Get(Format('%s/admin/collections?action=CREATE&name=%s',[fFullURL,aName]));
  if not (resp.StatusCode in [200,201]) then
    raise ELogger.Create(Format('[TLogSolRProvider] : Can''t create Collection (Error %d : %s)',[resp.StatusCode,resp.StatusText]));
end;

function TLogSolrProvider.ExistsCollection(const aName : string) : Boolean;
var
  resp : IHttpRequestResponse;
  json : TJSONValue;
  a : string;
begin
  Result := False;
  resp := fHTTPClient.Get(Format('%s/admin/cores?action=STATUS&core=%s',[fFullURL,aName]));
  if resp.StatusCode in [200,201] then
  begin
    json := resp.Response.FindValue(Format('status.%s.name',[aName]));
    if json <> nil then
    begin
      Result := json.Value = aName;
      //json.Free;
    end;
  end
  else raise ELogger.Create(Format('[TLogSolRProvider] : Can''t check Collection (Error %d : %s)',[resp.StatusCode,resp.StatusText]));
end;

procedure TLogSolrProvider.WriteLog(cLogItem : TLogItem);
var
  resp : IHttpRequestResponse;
begin
  if CustomMsgOutput then resp := fHTTPClient.Post(Format('%s/%s/update/json/docs',[fFullURL,fCollection]),cLogItem.Msg)
    else resp := fHTTPClient.Post(Format('%s/%s/update/json/docs',[fFullURL,fCollection]),LogItemToJson(cLogItem));

  if not (resp.StatusCode in [200,201]) then
    raise ELogger.Create(Format('[TLogSolRProvider] : Response %d : %s trying to post event',[resp.StatusCode,resp.StatusText]));
end;

initialization
  GlobalLogSolrProvider := TLogSolrProvider.Create;

finalization
  if Assigned(GlobalLogSolrProvider) and (GlobalLogSolrProvider.RefCount = 0) then GlobalLogSolrProvider.Free;

end.
