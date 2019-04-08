program QuickLogger.Lib.Tester;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Winapi.ActiveX;

const
  LIBPATH = '.\QuickLogger.dll';

function AddProviderJSONNative(Provider : Pchar) : Integer; stdcall; external LIBPATH;
function AddStandardFileProviderNative(const LogFilename : PChar) : Integer; stdcall; external LIBPATH;
procedure ResetProviderNative(ProviderName : PChar); stdcall; external LIBPATH;
function GetProviderNamesNative(out str: PChar): Integer; external LIBPATH;
function GetLibVersionNative(out str: PChar): Integer; stdcall; external LIBPATH;
function GetLastError(out str: PChar): Integer; stdcall; external LIBPATH;
procedure InfoNative(Line : PChar); stdcall; external LIBPATH;

function GetPChar(const str : string) : PChar;
begin
  {$IFNDEF  UNIX}
    Result := CoTaskMemAlloc(SizeOf(Char)*(Length(str)+1));
  {$ELSE}
    Result := Memory.MemAlloc(SizeOf(Char)*(Length(str)+1));
  {$ENDIF}
  {$IFNDEF FPC}
    strcopy(Result, PWideChar(str));
  {$ELSE}
    strcopy(Result, PChar(str));
  {$ENDIF}
end;

begin
  try
    AddStandardFileProviderNative('.\Logger.log');
    InfoNative(GetPChar('Test'));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
