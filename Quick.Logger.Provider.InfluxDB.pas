{ ***************************************************************************

  Copyright (c) 2016-2021 Kike Pérez

  Unit        : Quick.Logger.Provider.InfluxDB
  Description : Log Api InfluxDB Provider
  Author      : Kike Pérez
  Version     : 1.1
  Created     : 25/02/2019
  Modified    : 20/04/2021

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
unit Quick.Logger.Provider.InfluxDB;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  DateUtils,
  Quick.HttpClient,
  Quick.Commons,
  Quick.Logger;

type

  TLogInfluxDBProvider = class (TLogProviderBase)
  private
    fHTTPClient : TJsonHTTPClient;
    fURL : string;
    fFullURL : string;
    fDataBase : string;
    fUserName : string;
    fPassword : string;
    fUserAgent : string;
    fIncludedTags : TIncludedLogInfo;
    fCreateDataBaseIfNotExists : Boolean;
    procedure CreateDataBase;
    function LogItemToLine(cLogItem: TLogItem): string;
    procedure SetWriteURL;
    procedure SetPassword(const Value: string);
    procedure SetUserName(const Value: string);
  public
    constructor Create; override;
    destructor Destroy; override;
    property URL : string read fURL write fURL;
    property DataBase : string read fDataBase write fDataBase;
    property UserName : string read fUserName write SetUserName;
    property Password : string read fPassword write SetPassword;
    property CreateDataBaseIfNotExists : Boolean read fCreateDataBaseIfNotExists write fCreateDataBaseIfNotExists;
    property UserAgent : string read fUserAgent write fUserAgent;
    property IncludedTags : TIncludedLogInfo read fIncludedTags write fIncludedTags;
    property JsonOutputOptions : TJsonOutputOptions read fJsonOutputOptions write fJsonOutputOptions;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogInfluxDBProvider : TLogInfluxDBProvider;

implementation

constructor TLogInfluxDBProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fURL := 'http://localhost:8086';
  fDataBase := 'logger';
  fUserName := '';
  fPassword := '';
  fCreateDataBaseIfNotExists := True;
  fJsonOutputOptions.UseUTCTime := True;
  fUserAgent := DEF_USER_AGENT;
  fIncludedTags := [iiAppName,iiHost,iiEnvironment];
  IncludedInfo := [iiAppName,iiHost,iiEnvironment];
end;

destructor TLogInfluxDBProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);

  inherited;
end;

procedure TLogInfluxDBProvider.Init;
begin
  SetWriteURL;
  fHTTPClient := TJsonHTTPClient.Create;
  fHTTPClient.ContentType := 'application/json';
  fHTTPClient.UserAgent := fUserAgent;
  fHTTPClient.HandleRedirects := True;
  if fCreateDataBaseIfNotExists then CreateDataBase;
  inherited;
end;

procedure TLogInfluxDBProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogInfluxDBProvider.SetPassword(const Value: string);
begin
  if fPassword <> Value then
  begin
    fPassword := Value;
    SetWriteURL;
  end;
end;

procedure TLogInfluxDBProvider.SetWriteURL;
begin
  if fUserName+fPassword <> '' then fFullURL := Format('%s/write?db=%s&u=%s&p=%s&precision=ms',[fURL,fDataBase,fUserName,fPassword])
    else fFullURL := Format('%s/write?db=%s&precision=ms',[fURL,fDataBase]);
end;

procedure TLogInfluxDBProvider.SetUserName(const Value: string);
begin
  if fUserName <> Value then
  begin
    fUserName := Value;
    SetWriteURL;
  end;
end;

procedure TLogInfluxDBProvider.CreateDataBase;
var
  resp : IHttpRequestResponse;
begin
  if fUserName+fPassword <> '' then resp := fHTTPClient.Post(Format('%s/query?q=CREATE DATABASE %s&u=%s&p=%s',[fURL,fDatabase,fUserName,fPassword]),'')
    else resp := fHTTPClient.Post(Format('%s/query?q=CREATE DATABASE %s',[fURL,fDatabase]),'');

  if not (resp.StatusCode in [200,204]) then
    raise ELogger.Create(Format('[TLogInfluxDBProvider] : Response %d : %s trying to create database',[resp.StatusCode,resp.StatusText]));
end;

function TLogInfluxDBProvider.LogItemToLine(cLogItem: TLogItem): string;
var
  incinfo : TStringList;
  tags : string;
  fields : string;
begin
  incinfo := TStringList.Create;
  try
    incinfo.Add(Format('type=%s',[EventTypeName[cLogItem.EventType]]));
    if iiAppName in fIncludedTags then incinfo.Add(Format('application=%s',[SystemInfo.AppName]));
    if iiHost in fIncludedTags then incinfo.Add(Format('host=%s',[SystemInfo.HostName]));
    if iiUserName in fIncludedTags then incinfo.Add(Format('user=%s',[SystemInfo.UserName]));
    if iiOSVersion in fIncludedTags then incinfo.Add(Format('os=%s',[SystemInfo.OsVersion]));
    if iiEnvironment in fIncludedTags then incinfo.Add(Format('environment=%s',[Environment]));
    if iiPlatform in fIncludedTags then incinfo.Add(Format('platform=%s',[PlatformInfo]));
    if iiThreadId in fIncludedTags then incinfo.Add(Format('treadid=%s',[cLogItem.ThreadId]));
    if iiProcessId in fIncludedTags then incinfo.Add(Format('processid=%s',[SystemInfo.ProcessId]));

    tags := CommaText(incinfo);

    incinfo.Clear;
    incinfo.Add(Format('type="%s"',[EventTypeName[cLogItem.EventType]]));
    if iiAppName in IncludedInfo then incinfo.Add(Format('application="%s"',[SystemInfo.AppName]));
    if iiHost in IncludedInfo then incinfo.Add(Format('host="%s"',[SystemInfo.HostName]));
    if iiUserName in IncludedInfo then incinfo.Add(Format('user="%s"',[SystemInfo.UserName]));
    if iiOSVersion in IncludedInfo then incinfo.Add(Format('os="%s"',[SystemInfo.OsVersion]));
    if iiEnvironment in IncludedInfo then incinfo.Add(Format('environment="%s"',[Environment]));
    if iiPlatform in IncludedInfo then incinfo.Add(Format('platform="%s"',[PlatformInfo]));
    if iiThreadId in IncludedInfo then incinfo.Add(Format('treadid=%s',[cLogItem.ThreadId]));
    if iiProcessId in IncludedInfo then incinfo.Add(Format('processid=%s',[SystemInfo.ProcessId]));
    incinfo.Add(Format('message="%s"',[cLogItem.Msg]));
    fields := CommaText(incinfo);

    {$IFDEF DELPHIXE7_UP}
    Result := Format('logger,%s %s %d',[tags,fields,DateTimeToUnix(LocalTimeToUTC(cLogItem.EventDate),True)*1000]);
    {$ELSE}
    Result := Format('logger,%s %s %d',[tags,fields,DateTimeToUnix(LocalTimeToUTC(cLogItem.EventDate))*1000]);
    {$ENDIF}
  finally
    incinfo.Free;
  end;
end;

procedure TLogInfluxDBProvider.WriteLog(cLogItem : TLogItem);
var
  resp : IHttpRequestResponse;
  stream : TStringStream;
begin
  stream := TStringStream.Create(LogItemToLine(cLogItem));
  try
    resp := fHTTPClient.Post(fFullURL,stream);
  finally
    stream.Free;
  end;

  if not (resp.StatusCode in [200,204]) then
    raise ELogger.Create(Format('[TLogInfluxDBProvider] : Response %d : %s trying to post event',[resp.StatusCode,resp.StatusText]));
end;

initialization
  GlobalLogInfluxDBProvider := TLogInfluxDBProvider.Create;

finalization
  if Assigned(GlobalLogInfluxDBProvider) and (GlobalLogInfluxDBProvider.RefCount = 0) then GlobalLogInfluxDBProvider.Free;

end.
