{ ***************************************************************************

  Copyright (c) 2016-2021 Kike Pérez

  Unit        : Quick.Logger.Provider.Telegram
  Description : Log Telegram Bot Channel Provider
  Author      : Kike Pérez
  Version     : 1.22
  Created     : 21/05/2018
  Modified    : 28/12/2021

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
unit Quick.Logger.Provider.Telegram;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  idURI,
  {$IFDEF DELPHIXE8_UP}
  System.JSON,
  {$ENDIF}
  Quick.Commons,
  Quick.HttpClient,
  Quick.Logger;

const
  TELEGRAM_CHATID = '"chat":{"id":-'; //need a previous send msg from your bot into the channel chat
  TELEGRAM_API_SENDMSG = 'https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s';
  TELEGRAM_API_GETCHATID = 'https://api.telegram.org/bot%s/getUpdates';

type

  TTelegramChannelType = (tcPublic, tcPrivate);

  TLogTelegramProvider = class (TLogProviderBase)
  private
    fHttpClient : TJsonHttpClient;
    fChannelName : string;
    fChannelType : TTelegramChannelType;
    fBotToken : string;
    function GetPrivateChatId : Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    property ChannelName : string read fChannelName write fChannelName;
    property ChannelType : TTelegramChannelType read fChannelType write fChannelType;
    property BotToken : string read fBotToken write fBotToken;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

var
  GlobalLogTelegramProvider : TLogTelegramProvider;

implementation

constructor TLogTelegramProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fChannelName := '';
  fChannelType := tcPublic;
  fBotToken := '';
  IncludedInfo := [iiAppName,iiHost];
end;

destructor TLogTelegramProvider.Destroy;
begin
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);

  inherited;
end;

function TLogTelegramProvider.GetPrivateChatId: Boolean;
var
  telegramgetid : string;
  resp : IHttpRequestResponse;
  reg : string;
begin
  Result := False;
  telegramgetid := Format(TELEGRAM_API_GETCHATID,[fBotToken]);
  resp := fHttpClient.Get(telegramgetid);
  if resp.StatusCode <> 200 then
    raise ELogger.Create(Format('[TLogTelegramProvider] : Response %d : %s trying to send event',[resp.StatusCode,resp.StatusText]));
  //get chat id from response
  {$IFDEF DELPHIXE8_UP}
   reg := resp.Response.ToJSON;
  {$ELSE}
    {$IFDEF FPC}
     reg := resp.Response.AsJson;
    {$ELSE}
     reg := resp.Response.ToString;
    {$ENDIF}
  {$ENDIF}
  reg := stringReplace(reg,' ','',[rfReplaceAll]);
  if reg.Contains(TELEGRAM_CHATID) then
  begin
    reg := Copy(reg,Pos(TELEGRAM_CHATID,reg) + Length(TELEGRAM_CHATID)-1,reg.Length);
    fChannelName := Copy(reg,1,Pos(',',reg)-1);
    Result := True;
  end;
 end;

procedure TLogTelegramProvider.Init;
begin
  fHTTPClient := TJsonHttpClient.Create;
  fHTTPClient.ContentType := 'application/json';
  fHTTPClient.UserAgent := DEF_USER_AGENT;
  fHTTPClient.HandleRedirects := True;
  //try to get chat id for a private channel if not especified a ChatId (need a previous message sent from bot to channel first)
  if (fChannelType = tcPrivate) and (not fChannelName.StartsWith('-')) then
  begin
    if not GetPrivateChatId then raise ELogger.Create('Telegram Log Provider can''t get private chat Id!');
  end;
  inherited;
end;

procedure TLogTelegramProvider.Restart;
begin
  Stop;
  if Assigned(fHTTPClient) then FreeAndNil(fHTTPClient);
  Init;
end;

procedure TLogTelegramProvider.WriteLog(cLogItem : TLogItem);
var
  telegramsg : string;
  chatid : string;
  resp : IHttpRequestResponse;
begin
  if fChannelType = tcPublic then chatid := '@' + fChannelName
      else chatid := fChannelName;

  if CustomMsgOutput then telegramsg := TIdURI.URLEncode(Format(TELEGRAM_API_SENDMSG,[fBotToken,chatid,LogItemToFormat(cLogItem)]))
    else telegramsg := TIdURI.URLEncode(Format(TELEGRAM_API_SENDMSG,[fBotToken,chatid,LogItemToText(cLogItem)]));

  resp := fHttpClient.Get(telegramsg);

  if resp.StatusCode <> 200 then
    raise ELogger.Create(Format('[TLogTelegramProvider] : Response %d : %s trying to send event',[resp.StatusCode,resp.StatusText]));
end;

initialization
  GlobalLogTelegramProvider := TLogTelegramProvider.Create;

finalization
  if Assigned(GlobalLogTelegramProvider) and (GlobalLogTelegramProvider.RefCount = 0) then GlobalLogTelegramProvider.Free;

end.
