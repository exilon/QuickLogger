{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.Logger.Provider.Redis
  Description : Log Api Redis Provider
  Author      : Kike Pérez
  Version     : 1.23
  Created     : 15/10/2017
  Modified    : 12/02/2019

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

const
  DEF_REDIS_PORT = 6379;
  CRLF = #10#13;

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
    function EscapeString(const json: string): string;
    function RedisSELECT(dbIndex : Integer) : Int64;
    function RedisRPUSH(const aKey, Msg : string) : Int64;
    function RedisLPUSH(const aKey, Msg : string) : Int64;
    function RedisLTRIM(const aKey : string; aMaxSize : Int64) : Boolean;
    function RedisAUTH(const aPassword : string) : Boolean;
    function RedisQUIT : Boolean;
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
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogRedisProvider : TLogRedisProvider;

implementation

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
  fOutputAsJson := True;
end;

destructor TLogRedisProvider.Destroy;
begin
  if Assigned(fTCPClient) then
  begin
    try
      if fTCPClient.Connected then RedisQUIT;
      fTCPClient.IOHandler.InputBuffer.Clear;
      fTCPClient.IOHandler.WriteBufferFlush;
      if fTCPClient.Connected then fTCPClient.Disconnect(False);
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
  fTCPClient.ConnectTimeout := 5000;
  fTCPClient.Connect;
  if not fTCPClient.Connected then raise ELogger.Create('Can''t connect to Redis Server!');
  if fPassword <> '' then
  begin
    if not RedisAUTH(fPassword) then raise  ELogger.Create('Redis authentication error!');
  end;
  if fDataBase > 0 then
  begin
    if not RedisSELECT(fDataBase) = 0 then raise ELogger.CreateFmt('Can''t select Redis Database "%d"',[fDataBase]);
  end;
  inherited;
end;

function TLogRedisProvider.EscapeString(const json: string): string;
begin
  Result := StringReplace(json,'\','\\"',[rfReplaceAll]);
  Result := StringReplace(Result,'"','\"',[rfReplaceAll]);
  //Result := StringReplace(Result,'/','\/"',[rfReplaceAll]);
end;

procedure TLogRedisProvider.WriteLog(cLogItem : TLogItem);
var
  log : string;
begin
  if CustomMsgOutput then log := cLogItem.Msg
  else
  begin
    if fOutputAsJson then
    begin
      log := LogItemToJson(cLogItem);
    end
    else
    begin
      log := Format('%s [%s] %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),EventTypeName[cLogItem.EventType],cLogItem.Msg]);
    end;
  end;

  log := EscapeString(log);
  try
    RedisRPUSH(fLogKey,log);
    //RedisLPUSH(fLogKey+'1',log);
    if fMaxSize > 0 then RedisLTRIM(fLogKey,fMaxSize);
  except
    on E : Exception do raise ELogger.Create(Format('Error sending Log to Redis: %s',[e.Message]));
  end;
end;

function TLogRedisProvider.RedisRPUSH(const aKey, Msg : string) : Int64;
var
  res : string;
begin
  if not fTCPClient.Connected then fTCPClient.Connect;
  fTCPClient.IOHandler.Write(Format('RPUSH %s "%s"%s',[aKey,msg,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(1000) then
  begin
    res := fTCPClient.IOHandler.ReadLn;
    Result := StrToInt64(StringReplace(res,':','',[]));
  end
  else Result := 0;
end;

function TLogRedisProvider.RedisSELECT(dbIndex: Integer): Int64;
var
  res : string;
begin
  if not fTCPClient.Connected then fTCPClient.Connect;
  fTCPClient.IOHandler.Write(Format('SELECT %d%s',[dbIndex,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(1000) then
  begin
    res := fTCPClient.IOHandler.ReadLn;
    if res.Contains('+OK') then Result := 1
      else Result := StrToInt64(StringReplace(res,':','',[]));
  end
  else Result := 0;
end;

function TLogRedisProvider.RedisLPUSH(const aKey, Msg : string) : Int64;
var
  res : string;
begin
  if not fTCPClient.Connected then fTCPClient.Connect;
  fTCPClient.IOHandler.Write(Format('LPUSH %s "%s"%s',[aKey,msg,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(1000) then
  begin
    res := fTCPClient.IOHandler.ReadLn;
    Result := StrToInt64(StringReplace(res,':','',[]));
  end
  else Result := 0;
end;

procedure TLogRedisProvider.Restart;
begin
  Stop;
  if Assigned(fTCPClient) then
  begin
    if fTCPClient.Connected then fTCPClient.Disconnect(False);
    fTCPClient.Free;
  end;
  Init;
end;

function TLogRedisProvider.RedisLTRIM(const aKey : string; aMaxSize : Int64) : Boolean;
begin
  if not fTCPClient.Connected then fTCPClient.Connect;
  fTCPClient.IOHandler.Write(Format('LTRIM %s 0 %d%s',[aKey,fMaxSize,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(1000) then
  begin
    Result := fTCPClient.IOHandler.ReadLn = '+OK';
  end
  else Result := False;
end;

function TLogRedisProvider.RedisAUTH(const aPassword : string) : Boolean;
begin
  if not fTCPClient.Connected then fTCPClient.Connect;
  fTCPClient.IOHandler.Write(Format('AUTH %s%s',[aPassword,CRLF]));
  if fTCPClient.IOHandler.CheckForDataOnSource(1000) then
  begin
    Result := fTCPClient.IOHandler.ReadLn = '+OK';
  end
  else Result := False;
end;

function TLogRedisProvider.RedisQUIT : Boolean;
begin
  Result := True;
  try
    if not fTCPClient.Connected then fTCPClient.Connect;
    fTCPClient.IOHandler.Write(Format('QUIT%s',[CRLF]));
    if fTCPClient.IOHandler.CheckForDataOnSource(1000) then
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
