{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Email
  Description : Log Email Provider
  Author      : Kike Pérez
  Version     : 1.19
  Created     : 15/10/2017
  Modified    : 23/11/2017

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

interface

uses
  Classes,
  System.SysUtils,
  Quick.Commons,
  Quick.SMTP,
  Quick.Logger;

type

  TLogEmailProvider = class (TLogProviderBase)
  private
    fSMTP : TSMTP;
    fMail : TMailMessage;
    fShowTimeStamp : Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    property SMTP : TSMTP read fSMTP write fSMTP;
    property Mail : TMailMessage read fMail write fMail;
    property ShowTimeStamp : Boolean read fShowTimeStamp write fShowTimeStamp;
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
  fShowTimeStamp := True;
  fSMTP := TSMTP.Create;
  fMail := fSMTP.Mail;
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
  msg : string;
begin
  if fShowTimeStamp then msg := Format('%s [%s] %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),EventTypeName[cLogItem.EventType],cLogItem.Msg])
    else msg := Format('[%s] %s',[EventTypeName[cLogItem.EventType],cLogItem.Msg]);
  if fSMTP.Mail.Subject = '' then fSMTP.Mail.Subject := Format('Logger: [%s] event in %s',[EventTypeName[cLogItem.EventType],ExtractFilenameWithoutExt(ParamStr(0))]);
  fSMTP.Mail.Body := msg;
  fSMTP.SendMail;
end;

initialization
  GlobalLogEmailProvider := TLogEmailProvider.Create;

finalization
  if Assigned(GlobalLogEmailProvider) and (GlobalLogEmailProvider.RefCount = 0) then GlobalLogEmailProvider.Free;

end.
