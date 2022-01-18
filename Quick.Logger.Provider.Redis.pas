{ ***************************************************************************

  Copyright (c) 2016-2021 Kike Pérez

  Unit        : Quick.Logger.Provider.Redis
  Description : Log Api Redis Provider
  Author      : Kike Pérez
  Version     : 1.28
  Created     : 15/10/2017
  Modified    : 03/03/2021

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
unit Quick.Logger.Provider.Redis;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  IdTCPClient,
  Quick.Commons,
  Quick.Logger;

type

  TLogRedisProvider = class (TLogProviderBase)
  private
    fTCPClient : TIdTCPClient;
    fHost : string;
    fPort : Integer;
    fDataBase : Integer;
    fLogKey : string;
    fMaxSize : Int64;
    fPassword : string;
    fOutputAsJson : Boolean;
    fConnectionTimeout : Integer;
    fReadTimeout : Integer;
    function EscapeString(const json: string) : string;
    function IsIntegerResult(const aValue : string) : Boolean;
    function RedisSELECT(dbIndex : Integer) : Boolean;
    function RedisRPUSH(const aKey, Msg : string) : Boolean;
    function RedisLTRIM(const aKey : string; aFirstElement, aMaxSize : Int64) : Boolean;
    function RedisAUTH(const aPassword : string) : Boolean;
    function RedisQUIT : Boolean;
    procedure Connect;
    procedure SetConnectionTimeout(const Value: Integer);
    procedure SetReadTimeout(const Value: Integer);
  public
    constructor Create; override;
    destructor Destroy; override;
    property Host : string read fHost write fHost;
    property Port : Integer read fPort write fPort;
    property DataBase : Integer read fDataBase write fDataBase;
    property LogKey : string read fLogKey write fLogKey;
    property MaxSize : Int64 read fMaxSize write fMaxSize;
    property Password : string read fPassword write fPassword;
    property OutputAsJson : Boolean read fOutputAsJson write fOutputAsJson;
    property JsonOutputOptions : TJsonOutputOptions read fJsonOutputOptions write fJsonOutputOptions;
    property ConnectionTimeout : Integer read fConnectionTimeout write SetConnectionTimeout;
    property ReadTimeout : Integer read fReadTimeout write SetReadTimeout;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogRedisProvider : TLogRedisProvider;

implementation

const
  DEF_REDIS_PORT = 6379;
  CRLF = #10#13;
  DEF_CONNECTIONTIMEOUT = 30000;
  DEF_READTIMETOUT = 10000;

procedure TLogRedisProvider.Connect;
begin
  if not fTCPClient.Connected then
  begin
    fTCPClient.Connect;
    if not fTCPClient.Connected then raise ELogger.Create('Can''t connect to Redis Server!');
    NotifyError('Reconnected to Redis server');
  end;
  fTCPClient.Socket.Binding.SetKeepAliveValues(True,5000,1000);
  if fPassword <> '' then
  begin
    if not RedisAUTH(fPassword) then raise  ELogger.Create('Redis authentication error!');
  end;
  if fDataBase > 0 then
  begin
    if not RedisSELECT(fDataBase) then raise ELogger.CreateFmt('Can''t select Redis Database "%d"',[fDataBase]);
  end;
end;

constructor TLogRedisProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fHost := 'localhost';
  fPort := DEF_REDIS_PORT;
  fDataBase := 0;
  fLogKey := 'Logger';
  fMaxSize := 0;
  fPassword := '';
  IncludedInfo := [iiAppName,iiHost,iiEnvironment,iiPlatform];
  fConnectionTimeout := DEF_CONNECTIONTIMEOUT;
  fReadTimeout := DEF_READTIMETOUT;
  fJsonOutputOptions.UseUTCTime := True;
  fOutputAsJson := True;
end;

destructor TLogRedisProvider.Destroy;
begin
  if Assigned(fTCPClient) then
  begin
    try
      try
        fTCPClient.IOHandler.InputBuffer.Clear;
        fTCPClient.IOHandler.WriteBufferFlush;
        if fTCPClient.Connected then RedisQUIT;
        if fTCPClient.Connected then fTCPClient.Disconnect(False);
      except
        //avoid closing errors
      end;
      fTCPClient.Free;
    except
      //avoid closing errors
    end;
  end;

  inherited;
end;

procedure TLogRedisProvider.Init;
begin
  fTCPClient := TIdTCPClient.Create;
  fTCPClient.Host := fHost;
  fTCPClient.Port := fPort;
  fTCPClient.ConnectTimeout := fConnectionTimeout;
  fTCPClient.ReadTimeout := fConnectionTimeout;
  try
    fTCPClient.Connect; //first connection
    //connect password and database
    Connect;
  except
    on E : Exception do NotifyError(Format('Can''t connect to Redis service %s:%d (%s)',[Self.Host,Self.Port,e.Message]));
  end;
  inherited;
end;

function TLogRedisProvider.IsIntegerResult(const aValue: string): Boolean;
begin
  Result := IsInteger(StringReplace(aValue,':','',[]));
end;

function TLogRedisProvider.EscapeString(const json: string): string;
begin
  Result := StringReplace(json,'\','\\',[rfReplaceAll]);
  Result := StringReplace(Result,'"','\"',[rfReplaceAll]);
  Result := StringReplace(Result,#13,'\r',[rfReplaceAll]);
  Result := StringReplace(Result,#10,'\n',[rfReplaceAll]);
  //Result := StringReplace(Result,'/','\/"',[rfReplaceAll]);
end;

procedure TLogRedisProvider.WriteLog(cLogItem : TLogItem);
var
  log : string;
begin
  if CustomMsgOutput then log := LogItemToFormat(cLogItem)
  else
  begin
    if fOutputAsJson then
    begin
      log := LogItemToJson(cLogItem);
    end
    else
    begin
      log := LogItemToLine(cLogItem,True,True);
    end;
  end;

  log := EscapeString(log);
  try
    RedisRPUSH(fLogKey,log);
    if fMaxSize > 0 then RedisLTRIM(fLogKey,fMaxSize*-1,-2);
  except
    on E : Exception do raise ELogger.Create(Format('Error sending Log to Redis: %s',[e.Message]));
  end;
end;

function TLogRedisProvider.RedisRPUSH(const aKey, Msg : string) : Boolean;
var
  res : string;
begin
  Result := False;
  if not fTCPClient.Connected then Connect;
  fTCPClient.IOHandler.Write(Format('RPUSH %s "%s"%s',[aKey,msg,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(fReadTimeout) then
  begin
    res := fTCPClient.IOHandler.ReadLn;
    if IsIntegerResult(res) then Result := True
      else raise ELogger.CreateFmt('RPUSH error: %s',[res]);
  end;
end;

function TLogRedisProvider.RedisSELECT(dbIndex: Integer): Boolean;
var
  res : string;
begin
  Result := False;
  if not fTCPClient.Connected then Connect;
  fTCPClient.IOHandler.Write(Format('SELECT %d%s',[dbIndex,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(fReadTimeout) then
  begin
    res := fTCPClient.IOHandler.ReadLn;
    if res.Contains('+OK') then Result := True
      else raise ELogger.CreateFmt('SELECT error: %s',[res]);
  end;
end;

procedure TLogRedisProvider.Restart;
begin
  //Stop; no stop to avoid clear current queue
  if Assigned(fTCPClient) then
  begin
    try
      if fTCPClient.Connected then fTCPClient.Disconnect(False);
    except
      //avoid error in a already failing connection
    end;
    fTCPClient.Free;
  end;
  Init;
end;

procedure TLogRedisProvider.SetConnectionTimeout(const Value: Integer);
begin
  if fConnectionTimeout <> Value then
  begin
    fConnectionTimeout := Value;
    if Assigned(fTCPClient) then fTCPClient.ConnectTimeout := fConnectionTimeout;
  end;
end;

procedure TLogRedisProvider.SetReadTimeout(const Value: Integer);
begin
  if fReadTimeout <> Value then
  begin
    fReadTimeout := Value;
    if Assigned(fTCPClient) then fTCPClient.ConnectTimeout := fReadTimeout;
  end;
end;

function TLogRedisProvider.RedisLTRIM(const aKey : string; aFirstElement, aMaxSize : Int64) : Boolean;
begin
  Result := False;
  if not fTCPClient.Connected then Connect;
  fTCPClient.IOHandler.Write(Format('LTRIM %s %d %d%s',[aKey,aFirstElement,fMaxSize,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(fReadTimeout) then
  begin
    Result := fTCPClient.IOHandler.ReadLn = '+OK';
  end;
end;

function TLogRedisProvider.RedisAUTH(const aPassword : string) : Boolean;
begin
  Result := False;
  if not fTCPClient.Connected then Connect;
  fTCPClient.IOHandler.Write(Format('AUTH %s%s',[aPassword,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(fReadTimeout) then
  begin
    Result := fTCPClient.IOHandler.ReadLn = '+OK';
  end;
end;

function TLogRedisProvider.RedisQUIT : Boolean;
begin
  Result := True;
  try
    if not fTCPClient.Connected then Connect;
    fTCPClient.IOHandler.Write(Format('QUIT%s',[CRLF]));
    if fTCPClient.IOHandler.CheckForDataOnSource(fReadTimeout) then
    begin
      Result := fTCPClient.IOHandler.ReadLn = '+OK';
    end;
  except
    Result := False;
  end;
end;

initialization
  GlobalLogRedisProvider := TLogRedisProvider.Create;

finalization
  if Assigned(GlobalLogRedisProvider) and (GlobalLogRedisProvider.RefCount = 0) then GlobalLogRedisProvider.Free;

end.
