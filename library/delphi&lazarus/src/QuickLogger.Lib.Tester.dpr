program QuickLogger.Lib.Tester;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  {$IFDEF MSWINDOWS}
  Winapi.ActiveX,
  {$ENDIF}
  System.SysUtils;

const
  {$IFDEF MSWINDOWS}
  LIBPATH = '.\QuickLogger.dll';
  {$ELSE}
  LIBPATH = './libQuickLogger.so';
  {$ENDIF}

function AddProviderJSONNative(Provider : Pchar) : Integer; stdcall; external LIBPATH;
function AddStandardFileProviderNative(const LogFilename : PChar) : Integer; stdcall; external LIBPATH;
procedure ResetProviderNative(ProviderName : PChar); stdcall; external LIBPATH;
function GetProviderNamesNative(out str: PChar): Integer; external LIBPATH;
function GetLibVersionNative(out str: PChar): Integer; stdcall; external LIBPATH;
function GetLastError(out str: PChar): Integer; stdcall; external LIBPATH;
procedure InfoNative(Line : PChar); stdcall; external LIBPATH;

function GetPChar(const str : string) : PChar;
begin
  {$IFDEF MSWINDOWS}
    Result := CoTaskMemAlloc(SizeOf(Char)*(Length(str)+1));
  {$ELSE}
    {$IFDEF FPC}
    Result := Memory.MemAlloc(SizeOf(Char)*(Length(str)+1));
    {$ELSE}
    GetMem(Result,SizeOf(Char)*(Length(str)+1));
    {$ENDIF}
  {$ENDIF}
  {$IFNDEF FPC}
    StrCopy(Result, PWideChar(str));
  {$ELSE}
    StrCopy(Result, PChar(str));
  {$ENDIF}
end;

begin
  try
    AddStandardFileProviderNative('Logger.log');
    InfoNative(GetPChar('Test'));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
