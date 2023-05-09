{ ***************************************************************************

  Copyright (c) 2016-2020 Kike Pérez

  Unit        : Quick.Logger.Provider.Files
  Description : Log Console Provider
  Author      : Kike Pérez
  Version     : 1.30
  Created     : 12/10/2017
  Modified    : 24/04/2020

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

{$i QuickLib.inc}

interface

uses
  Classes,
  SysUtils,
  DateUtils,
  {$IFDEF FPC}
  Quick.Files,
  zipper,
  {$ELSE}
  System.IOUtils,
  System.Zip,
  {$ENDIF}
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
    fRotatedFilesPath : string;
    fFileCreationDate : TDateTime;
    fShowEventTypes : Boolean;
    fShowHeaderInfo : Boolean;
    fIsRotating : Boolean;
    fUnderlineHeaderEventType: Boolean;
    fAutoFlush : Boolean;
    fAutoFileName : Boolean;
    FDailyRotateFileDateFormat: string;
    function CalcRotateLogFileName(cNumBackup: Integer; cFileDate: string; cZipped: Boolean; cFormatNumBackup: Boolean =
        true): string;
    function CheckNeedRotate : Boolean;
    function GetFileDate(cFileName: string): string;
    function GetLogFileBackup(cNumBackup: Integer; zipped: Boolean): string;
    procedure SetFileName(const Value: string);
    procedure SetRotatedFilesPath(const Value: string);
  protected
    procedure CompressLogFile(const cFileName : string); virtual;
    procedure WriteHeaderInfo; virtual;
    procedure WriteToStream(const cMsg : string); virtual;
  public
    constructor Create; override;
    destructor Destroy; override;
    property FileName : string read fFileName write SetFileName;
    {$IFDEF MSWINDOWS}
    property AutoFileNameByProcess : Boolean read fAutoFileName write fAutoFileName;
    {$ENDIF}
    property MaxRotateFiles : Integer read fMaxRotateFiles write fMaxRotateFiles;
    property MaxFileSizeInMB : Integer read fMaxFileSizeInMB write fMaxFileSizeInMB;
    property DailyRotate : Boolean read fDailyRotate write fDailyRotate;
    property DailyRotateFileDateFormat: string read FDailyRotateFileDateFormat write FDailyRotateFileDateFormat;
    property RotatedFilesPath : string read fRotatedFilesPath write SetRotatedFilesPath;
    property CompressRotatedFiles : Boolean read fCompressRotatedFiles write fCompressRotatedFiles;
    property ShowEventType : Boolean read fShowEventTypes write fShowEventTypes;
    property ShowHeaderInfo : Boolean read fShowHeaderInfo write fShowHeaderInfo;
    property UnderlineHeaderEventType : Boolean read fUnderlineHeaderEventType write fUnderlineHeaderEventType;
    property AutoFlush : Boolean read fAutoFlush write fAutoFlush;
    procedure Init; override;
    procedure Restart; override;
    procedure RotateLog; virtual;
    procedure WriteLog(cLogItem : TLogItem); override;
  end;

  {$IFDEF MSWINDOWS}
  function GetCurrentProcessId : Cardinal; stdcall; external 'kernel32.dll';
  {$ENDIF}

var
  GlobalLogFileProvider : TLogFileProvider;

implementation

constructor TLogFileProvider.Create;
begin
  inherited;
  fFileName := '';
  fIsRotating := False;
  fMaxRotateFiles := 5;
  fMaxFileSizeInMB := 20;
  fDailyRotate := False;
  fCompressRotatedFiles := False;
  fShowEventTypes := True;
  fShowHeaderInfo := True;
  fUnderlineHeaderEventType := False;
  fRotatedFilesPath := '';
  fAutoFlush := False;
  fAutoFileName := False;
  LogLevel := LOG_ALL;
  IncludedInfo := [iiAppName,iiHost,iiUserName,iiOSVersion];
end;

destructor TLogFileProvider.Destroy;
begin
  if Assigned(fLogWriter) then fLogWriter.Free;
  fLogWriter := nil;
  inherited;
end;

procedure CreateNewLogFile(const aFilename : string);
var
  fs : TFileStream;
begin
  //resolve windows filesystem tunneling creation date?
  fs := TFile.Create(aFilename);
  try
    //do nothing...created to set new creationdate
  finally
    fs.Free;
  end;
  TFile.SetCreationTime(aFilename,Now());
end;

function TLogFileProvider.CalcRotateLogFileName(cNumBackup: Integer; cFileDate: string; cZipped: Boolean;
    cFormatNumBackup: Boolean = true): string;
var
  zipExt: string;
  LogName: string;
  LogExt: string;
  Num: string;
begin
  if cZipped then
    zipExt := '.zip'
  else
    zipExt := '';
  LogName := TPath.GetFileNameWithoutExtension (fFileName);
  LogExt := TPath.GetExtension (fFileName);
  if cNumBackup > 0 then
    if cFormatNumBackup then
      Num := '.' + cNumBackup.ToString.PadLeft (MaxRotateFiles.ToString.Length, '0')
    else
      Num := '.' + cNumBackup.ToString
  else
    Num := '';
  if cFileDate = '' then
    Result := Format ('%s%s%s%s', [LogName, Num, LogExt, zipExt])
  else
    Result := Format ('%s%s.%s%s%s', [LogName, Num, cFileDate, LogExt, zipExt]);
  if fRotatedFilesPath = '' then
    Result := TPath.GetDirectoryName (fFileName) + PathDelim + Result
  else
    Result := IncludeTrailingPathDelimiter (fRotatedFilesPath) + Result;
end;

procedure TLogFileProvider.Init;
var
  FileMode : Word;
  fs : TFileStream;
  exepath : string;
begin
  if Assigned(fLogWriter) then fLogWriter.Free;
  fLogWriter := nil;

  //get exepath only if not running as dll
  if IsLibrary then exepath := SystemInfo.AppPath
    else exepath := ParamStr(0);

  if fFileName = '' then
  begin
    {$IFNDEF ANDROID}
    fFileName := TPath.GetDirectoryName(exepath) + PathDelim + TPath.GetFileNameWithoutExtension(exepath) + '.log';
    {$ELSE}
    fFileName := TPath.GetDocumentsPath + PathDelim + 'logger.log';
    {$ENDIF}
  end;

  if fFileName.StartsWith('.'+PathDelim) then fFileName := StringReplace(fFileName,'.'+PathDelim,TPath.GetDirectoryName(exepath) + PathDelim,[])
    else if ExtractFilePath(fFileName) = '' then fFileName := TPath.GetDirectoryName(exepath) + PathDelim + fFileName;

  {$IFDEF MSWINDOWS}
  if fAutoFileName then fFileName := Format('%s\%s_%d.log',[TPath.GetDirectoryName(fFileName),TPath.GetFileNameWithoutExtension(fFileName),GetCurrentProcessId]);
  {$ENDIF}

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
    //resolve windows filesystem tunneling creation date
    CreateNewLogFile(fFileName);
  end;
  //create stream file
  fs := TFileStream.Create(fFileName, FileMode);
  try
    fs.Seek(0,TSeekOrigin.soEnd);
    fLogWriter := TStreamWriter.Create(fs,TEncoding.Default,32);
    fLogWriter.AutoFlush := fAutoFlush;
    fLogWriter.OwnStream;
    //check if need to rotate
    if CheckNeedRotate then
    begin
      try
        RotateLog;
      except
        on E : Exception do NotifyError(Format('Can''t rotate log file: %s',[e.message]));
      end;
      Exit;
    end;
    //writes header info
    if fShowHeaderInfo then WriteHeaderInfo;
  except
    fs.Free;
    raise;
  end;
  //creates the threadlog
  inherited;
end;

procedure TLogFileProvider.WriteHeaderInfo;
begin
  WriteToStream(FillStr('-',70));
  if iiAppName in IncludedInfo then
  begin
    WriteToStream(Format('Application : %s %s',[SystemInfo.AppName,SystemInfo.AppVersion]));
  end;
  if iiProcessId in IncludedInfo then WriteToStream(Format('PID         : %d',[SystemInfo.ProcessId]));
  WriteToStream(Format('Path        : %s',[SystemInfo.AppPath]));
  WriteToStream(Format('CPU cores   : %d',[SystemInfo.CPUCores]));
  if iiOSVersion in IncludedInfo then WriteToStream(Format('OS version  : %s',[SystemInfo.OSVersion]));
  //{$IFDEF MSWINDOWS}
  if iiHost in IncludedInfo then WriteToStream(Format('Host        : %s',[SystemInfo.HostName]));
  if iiUserName in IncludedInfo then WriteToStream(Format('Username    : %s',[Trim(SystemInfo.UserName)]));
  //{$ENDIF}
  WriteToStream(Format('Started     : %s',[DateTimeToStr(Now(),FormatSettings)]));
  {$IFDEF MSWINDOWS}
  if IsService then WriteToStream('AppType     : Service')
    else if System.IsConsole then WriteToStream('AppType     : Console');

  if IsDebug then WriteToStream('Debug mode  : On');
  {$ENDIF}
  WriteToStream(FillStr('-',70));
end;

procedure TLogFileProvider.WriteToStream(const cMsg : string);
begin
  try
    //check if need to rotate
    if CheckNeedRotate then
    begin
      try
        RotateLog;
      except
        on E : Exception do NotifyError(Format('Can''t rotate log file: %s',[e.message]));
      end;
    end;
    //writes to stream file
    fLogWriter.WriteLine(cMsg);
    //needs to flush if autoflush??
    if not fAutoFlush then fLogWriter.Flush;
  except
    raise ELogger.Create('Error writting to file log!');
  end;
end;

procedure TLogFileProvider.WriteLog(cLogItem : TLogItem);
begin
  if CustomMsgOutput then
  begin
    WriteToStream(LogItemToFormat(cLogItem));
    Exit;
  end;

  if cLogItem.EventType = etHeader then
  begin
    WriteToStream(cLogItem.Msg);
    if fUnderlineHeaderEventType then WriteToStream(FillStr('-',cLogItem.Msg.Length));
  end
  else
  begin
    //if fShowEventTypes then WriteToStream(Format('%s [%s] %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),EventTypeName[cLogItem.EventType],LogItemToLine(cLogItem.Msg)]))
    //  else WriteToStream(Format('%s %s',[DateTimeToStr(cLogItem.EventDate,FormatSettings),cLogItem.Msg]));
    WriteToStream(LogItemToLine(cLogItem,True,fShowEventTypes));
  end;
end;

function TLogFileProvider.GetFileDate(cFileName: string): string;
var
  fileDate: TDateTime;
begin
  Result := '';
  if FDailyRotateFileDateFormat = '' then
    Exit;
  try
    fileDate := TFile.GetCreationTime (cFileName);
    Result := FormatDateTime (FDailyRotateFileDateFormat, fileDate);
  except
    Result := '';
  end;
end;

function TLogFileProvider.GetLogFileBackup(cNumBackup: Integer; zipped: Boolean): string;
var
  SearchRec: TSearchRec;
  i: Integer;
begin
  // Doing this twice to be backward compatible independent if the numbackup is formatted or not
  for i := 0 to 1 do
  begin
    if DailyRotate then
      Result := CalcRotateLogFileName (cNumBackup, '*', zipped, i = 0)
    else
      Result := CalcRotateLogFileName (cNumBackup, '', zipped, i = 0);

    if findfirst (Result, faAnyFile, SearchRec) = 0 then
      Result := TPath.GetDirectoryName (Result) + PathDelim + SearchRec.Name
    else
      Result := '';
    FindClose (SearchRec);
    if Result <> '' then
      Exit;
  end;
end;

procedure TLogFileProvider.Restart;
begin
  Stop;
  //if Assigned(fLogWriter) then fLogWriter.Free;
  Init;
end;

procedure TLogFileProvider.RotateLog;
var
  RotateFile: string;
  i: Integer;

begin
  if fIsRotating then
    Exit;
  fIsRotating := true;
  try
    // frees stream file
    if Assigned (fLogWriter) then
    begin
      fLogWriter.Free;
      fLogWriter := nil;
    end;
    try
      if fRotatedFilesPath <> '' then
        ForceDirectories (fRotatedFilesPath);
      // delete older log backup and zip
      RotateFile := GetLogFileBackup (fMaxRotateFiles, true);
      if RotateFile <> '' then
        TFile.Delete (RotateFile);
      RotateFile := GetLogFileBackup (fMaxRotateFiles, False);
      if RotateFile <> '' then
        TFile.Delete (RotateFile);
      // rotates older log backups or zips
      for i := fMaxRotateFiles - 1 downto 1 do
      begin
        RotateFile := GetLogFileBackup (i, true);
        if RotateFile <> '' then
          TFile.Move (RotateFile, CalcRotateLogFileName(i + 1, GetFileDate(RotateFile), true));
        RotateFile := GetLogFileBackup (i, False);
        if RotateFile <> '' then
          TFile.Move (RotateFile, CalcRotateLogFileName(i + 1, GetFileDate(RotateFile), False));
      end;
      // rename current log
      RotateFile := CalcRotateLogFileName (1, GetFileDate(fFileName), False);
      TFile.Move (fFileName, RotateFile);
    finally
      // initialize stream file again
      Init;
    end;
  finally
    fIsRotating := False;
  end;
  // compress log file
  if fCompressRotatedFiles then
  begin
{$IFDEF FPC}
    CompressLogFile (RotateFile);
{$ELSE}
    TThread.CreateAnonymousThread (
      procedure
      begin
        CompressLogFile(RotateFile);
      end).Start;
{$ENDIF}
  end;
end;

procedure TLogFileProvider.SetFileName(const Value: string);
begin
  if Value <> fFileName then
  begin
    fFileName := Value;
    if IsEnabled then Restart;
  end;
end;

procedure TLogFileProvider.SetRotatedFilesPath(const Value: string);
var
  exepath : string;
begin
  if IsLibrary then exepath := SystemInfo.AppPath
    else exepath := ParamStr(0);

  if Value.StartsWith('.' + PathDelim) then fRotatedFilesPath := StringReplace(Value,'.' + PathDelim,TPath.GetDirectoryName(exepath) + PathDelim,[])
    else fRotatedFilesPath := Value;
end;

function TLogFileProvider.CheckNeedRotate: Boolean;
begin
  if ((fLimitLogSize > 0) and (fLogWriter.BaseStream.Size > fLimitLogSize))
    or ((fDailyRotate) and (not IsSameDay(fFileCreationDate,Now()))) then
    Result := True
  else Result := False;
end;

procedure TLogFileProvider.CompressLogFile(const cFileName : string);
{$IFDEF FPC}
var
  zip : TZipper;
begin
  try
    zip := TZipper.Create;
    try
      zip.FileName := GetLogFileBackup(1,True);
      zip.Entries.AddFileEntry(cFilename,ExtractFileName(cFilename));
      zip.ZipAllFiles;
    finally
      zip.Free;
    end;
    TFile.Delete(cFileName);
  except
    raise ELogger.Create('Error trying to backup log file!');
  end;
end;
{$ELSE}
var
  zip : TZipFile;
begin
  try
    zip := TZipFile.Create;
    try
      zip.Open(GetLogFileBackup(1,True),zmWrite);
      zip.Add(cFileName,'',TZipCompression.zcDeflate);
      zip.Close;
    finally
      zip.Free;
    end;
    TFile.Delete(cFileName);
  except
    raise ELogger.Create('Error trying to backup log file!');
  end;
end;

{$ENDIF}

initialization
  GlobalLogFileProvider := TLogFileProvider.Create;

finalization
  if Assigned(GlobalLogFileProvider) and (GlobalLogFileProvider.RefCount = 0) then GlobalLogFileProvider.Free;

end.
