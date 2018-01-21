{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.Logger.Provider.Files
  Description : Log Console Provider
  Author      : Kike Pérez
  Version     : 1.18
  Created     : 12/10/2017
  Modified    : 20/01/2018

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
unit Quick.Logger.Provider.Files;

interface

uses
  Classes,
  System.SysUtils,
  System.IOUtils,
  System.Zip,
  Quick.Commons,
  Quick.Logger;

type

  TLogFileProvider = class (TLogProviderBase,IRotable)
  private
    fLogWriter : TStreamWriter;
    fFileName : string;
    fMaxRotateFiles : Integer;
    fMaxFileSizeInMB : Integer;
    fLimitLogSize : Int64;
    fDailyRotate : Boolean;
    fCompressRotatedFiles : Boolean;
    fFileCreationDate : TDateTime;
    fShowEventTypes : Boolean;
    fShowHeaderInfo : Boolean;
    fIsRotating : Boolean;
    procedure WriteToStream(const cMsg : string);
    procedure CompressLogFile(const cFileName : string);
    function GetLogFileBackup(cNumBackup : Integer; zipped : Boolean) : string;
  public
    constructor Create; override;
    destructor Destroy; override;
    property FileName : string read fFileName write fFileName;
    property MaxRotateFiles : Integer read fMaxRotateFiles write fMaxRotateFiles;
    property MaxFileSizeInMB : Integer read fMaxFileSizeInMB write fMaxFileSizeInMB;
    property DailyRotate : Boolean read fDailyRotate write fDailyRotate;
    property CompressRotatedFiles : Boolean read fCompressRotatedFiles write fCompressRotatedFiles;
    property ShowEventType : Boolean read fShowEventTypes write fShowEventTypes;
    property ShowHeaderInfo : Boolean read fShowHeaderInfo write fShowHeaderInfo;
    procedure Init; override;
    procedure Restart; override;
    procedure WriteLog(cLogItem : TLogItem); override;
    procedure RotateLog;
  end;

var
  GlobalLogFileProvider : TLogFileProvider;

implementation

constructor TLogFileProvider.Create;
begin
  inherited;
  fFileName := TPath.GetDirectoryName(ParamStr(0)) + '\' + TPath.GetFileNameWithoutExtension(ParamStr(0)) + '.log';
  fIsRotating := False;
  fMaxRotateFiles := 5;
  fMaxFileSizeInMB := 20;
  fDailyRotate := False;
  fCompressRotatedFiles := False;
  fShowEventTypes := True;
  fShowHeaderInfo := True;
  LogLevel := LOG_ALL;
end;

destructor TLogFileProvider.Destroy;
begin
  if Assigned(fLogWriter) then fLogWriter.Free;
  inherited;
end;

procedure TLogFileProvider.Init;
var
  FileMode : Word;
  fs : TFileStream;
begin
  if fMaxFileSizeInMB > 0 then fLimitLogSize := fMaxFileSizeInMB * 1024 * 1024
    else fLimitLogSize := 0;
  if TFile.Exists(fFileName) then
  begin
    fFileCreationDate := TFile.GetCreationTime(fFileName);
    FileMode := fmOpenWrite or fmShareDenyWrite;
  end
  else
  begin
    FileMode := fmCreate or fmShareDenyWrite;
    fFileCreationDate := Now();
  end;
  //create stream file
  fs := TFileStream.Create(fFileName, FileMode);
  try
    fs.Seek(0,TSeekOrigin.soEnd);
    fLogWriter := TStreamWriter.Create(fs,TEncoding.Default,32);
    fLogWriter.AutoFlush := True;
    fLogWriter.OwnStream;
    //writes header info
    if fShowHeaderInfo then
    begin
      WriteToStream(FillStr('-',70));
      WriteToStream(Format('Application : %s %s',[ExtractFilenameWithoutExt(ParamStr(0)),GetAppVersionFullStr]));
      WriteToStream(Format('Path        : %s',[ExtractFilePath(ParamStr(0))]));
      WriteToStream(Format('CPU cores   : %d',[CPUCount]));
      WriteToStream(Format('OS version  : %s',[TOSVersion.ToString]));
      WriteToStream(Format('Host        : %s',[GetComputerName]));
      WriteToStream(Format('Username    : %s',[Trim(GetLoggedUserName)]));
      WriteToStream(Format('Started     : %s',[NowStr]));
      if IsService then WriteToStream('AppType     : Service')
        else if System.IsConsole then WriteToStream('AppType     : Console');

      if IsDebug then WriteToStream('Debug mode  : On');
      WriteToStream(FillStr('-',70));
    end;
  except
    fs.Free;
    raise;
  end;
  //creates the threadlog
  inherited;
end;

procedure TLogFileProvider.WriteToStream(const cMsg : string);
begin
  try
    //check if need to rotate
    if ((fLimitLogSize > 0) and (fLogWriter.BaseStream.Size > fLimitLogSize))
       or ((fDailyRotate) and (not IsSameDay(fFileCreationDate,Now()))) then RotateLog;
    //writes to stream file
    fLogWriter.WriteLine(cMsg);
    fLogWriter.Flush;
  except
    raise ELogger.Create('Error writting to file log!');
  end;
end;

procedure TLogFileProvider.WriteLog(cLogItem : TLogItem);
begin
  if cLogItem.EventType = etHeader then
  begin
    WriteToStream(cLogItem.Msg);
    WriteToStream(FillStr('-',cLogItem.Msg.Length));
  end
  else
  begin
    if fShowEventTypes then WriteToStream(Format('%s [%s] %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),EventTypeName[cLogItem.EventType],cLogItem.Msg]))
      else WriteToStream(Format('%s %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),cLogItem.Msg]));
  end;
end;

function TLogFileProvider.GetLogFileBackup(cNumBackup : Integer; zipped : Boolean) : string;
var
  LogExt : string;
  LogName : string;
  zipExt : string;
begin
  if zipped then zipExt := '.zip'
    else zipExt := '';
  LogName := TPath.GetFileNameWithoutExtension(fFileName);
  LogExt := TPath.GetExtension(fFileName);
  Result := Format('%s.%d%s%s',[LogName,cNumBackup,LogExt,zipExt]);
end;

procedure TLogFileProvider.Restart;
begin
  Stop;
  if Assigned(fLogWriter) then fLogWriter.Free;
  Init;
end;

procedure TLogFileProvider.RotateLog;
var
  RotateFile : string;
  i : Integer;
begin
  if fIsRotating then Exit;
  //frees stream file
  if Assigned(fLogWriter) then fLogWriter.Free;
  fIsRotating := True;
  try
    //delete older log backup and zip
    RotateFile := GetLogFileBackup(fMaxRotateFiles,True);
    if TFile.Exists(RotateFile) then TFile.Delete(RotateFile);
    RotateFile := GetLogFileBackup(fMaxRotateFiles,False);
    if TFile.Exists(RotateFile) then TFile.Delete(RotateFile);
    //rotates older log backups or zips
    for i := fMaxRotateFiles - 1 downto 1 do
    begin
      RotateFile := GetLogFileBackup(i,True);
      if TFile.Exists(RotateFile) then TFile.Move(RotateFile,GetLogFileBackup(i + 1,True));
      RotateFile := GetLogFileBackup(i,False);
      if TFile.Exists(RotateFile) then TFile.Move(RotateFile,GetLogFileBackup(i + 1,False));
    end;
    //rename current log
    RotateFile := GetLogFileBackup(1,False);
    TFile.Move(fFileName,RotateFile);
  finally
    //initialize stream file again
    Init;
    fIsRotating := False;
  end;
  //compress log file
  if fCompressRotatedFiles then
  begin
    TThread.CreateAnonymousThread(procedure
                                  begin
                                    CompressLogFile(RotateFile);
                                  end).Start;
  end;
end;

procedure TLogFileProvider.CompressLogFile(const cFileName : string);
var
  zip : TZipFile;
begin
  zip := TZipFile.Create;
  try
    try
      zip.Open(GetLogFileBackup(1,True),zmWrite);
      zip.Add(cFileName,'',TZipCompression.zcDeflate);
      zip.Close;
    except
      raise ELogger.Create('Error trying to backup log file!');
    end;
    TFile.Delete(cFileName);
  finally
    zip.Free;
  end;
end;

initialization
  GlobalLogFileProvider := TLogFileProvider.Create;

finalization
  if Assigned(GlobalLogFileProvider) and (GlobalLogFileProvider.RefCount = 0) then GlobalLogFileProvider.Free;

end.
