{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Email
  Description : Log Email Provider
  Author      : Kike Pérez
  Version     : 1.23
  Created     : 15/10/2017
  Modified    : 24/05/2018

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
begin
  if fSMTP.Mail.Subject = '' then fSMTP.Mail.Subject := Format('%s [%s] %s',[SystemInfo.AppName,EventTypeName[cLogItem.EventType],Copy(cLogItem.Msg,1,50)]);

  if CustomMsgOutput then fSMTP.Mail.Body := cLogItem.Msg
    else fSMTP.Mail.Body := LogItemToHtml(cLogItem);

  fSMTP.SendMail;
end;

initialization
  GlobalLogEmailProvider := TLogEmailProvider.Create;

finalization
  if Assigned(GlobalLogEmailProvider) and (GlobalLogEmailProvider.RefCount = 0) then GlobalLogEmailProvider.Free;

end.
