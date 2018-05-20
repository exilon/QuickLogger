{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Email
  Description : Log Email Provider
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

unit Quick.Logger.Provider.Email;

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  Quick.Commons,
  Quick.SMTP,
  Quick.Logger;

type

  TLogEmailProvider = class (TLogProviderBase)
  private
    fSMTP : TSMTP;
    fMail : TMailMessage;
  public
    constructor Create; override;
    destructor Destroy; override;
    property SMTP : TSMTP read fSMTP write fSMTP;
    property Mail : TMailMessage read fMail write fMail;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

const
  CRLF = '<BR>';

var
  GlobalLogEmailProvider : TLogEmailProvider;

implementation

constructor TLogEmailProvider.Create;
begin
  inherited;
  LogLevel := LOG_ALL;
  fSMTP := TSMTP.Create;
  fMail := fSMTP.Mail;
  IncludedInfo := [iiAppName,iiHost,iiUserName,iiOSVersion];
end;

destructor TLogEmailProvider.Destroy;
begin
  fMail := nil;
  if Assigned(fSMTP) then fSMTP.Free;
  inherited;
end;

procedure TLogEmailProvider.Init;
begin
  inherited;
end;

procedure TLogEmailProvider.Restart;
begin
  Stop;
  Init;
end;

procedure TLogEmailProvider.WriteLog(cLogItem : TLogItem);
var
  subject : string;
  msg : TStringList;
begin
  if fSMTP.Mail.Subject = '' then fSMTP.Mail.Subject := Format('%s [%s] %s',[SystemInfo.AppName,EventTypeName[cLogItem.EventType],Copy(cLogItem.Msg,1,50)]);
  msg := TStringList.Create;
  try
    msg.Add(Format('<B>EventDate:</B> %s%s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),CRLF]));
    msg.Add(Format('<B>Type:</B> %s%s',[EventTypeName[cLogItem.EventType],CRLF]));
    if iiAppName in IncludedInfo then msg.Add(Format('<B>Application:</B> %s%s',[SystemInfo.AppName,CRLF]));
    if iiHost in IncludedInfo then msg.Add(Format('<B>Host:</B> ',[SystemInfo.HostName,CRLF]));
    if iiUserName in IncludedInfo then msg.Add(Format('<B>User:</B> %s%s',[SystemInfo.UserName,CRLF]));
    if iiOSVersion in IncludedInfo then msg.Add(Format('<B>OS:</B> %s%s',[SystemInfo.OsVersion,CRLF]));
    if iiEnvironment in IncludedInfo then msg.Add(Format('<B>Environment:</B> %s%s',[Environment,CRLF]));
    if iiPlatform in IncludedInfo then msg.Add(Format('<B>Platform:</B> %s%s',[PlatformInfo,CRLF]));
    msg.Add(Format('<B>Message:</B> %s%s',[cLogItem.Msg,CRLF]));
    fSMTP.Mail.Body := msg.Text;
  finally
    msg.Free;
  end;
  fSMTP.SendMail;
end;

initialization
  GlobalLogEmailProvider := TLogEmailProvider.Create;

finalization
  if Assigned(GlobalLogEmailProvider) and (GlobalLogEmailProvider.RefCount = 0) then GlobalLogEmailProvider.Free;

end.
