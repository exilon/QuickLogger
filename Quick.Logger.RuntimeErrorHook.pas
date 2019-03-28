{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.Logger.RuntimeErrorHook
  Description : Log Runtime Errors
  Author      : Kike Pérez
  Version     : 1.20
  Created     : 28/03/2019
  Modified    : 28/03/2019

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
unit Quick.Logger.RuntimeErrorHook;

{$i QuickLib.inc}

interface

implementation

uses
  SysUtils,
  System.TypInfo,
  Quick.Logger;

//var
  //RealErrorProc : procedure (ErrorCode: Byte; ErrorAddr: Pointer);

procedure HandleErrorProc(ErrorCode : Byte; ErrorPtr : Pointer);
var
  errorname : string;
begin
  if Assigned(GlobalLoggerRuntimeError) then
  begin
    errorname := GetEnumName(TypeInfo(TRuntimeError), ErrorCode);
    GlobalLoggerRuntimeError(errorname,ErrorCode,ErrorPtr);
  end;
end;

initialization
  //RealErrorProc := ErrorProc;
  ErrorProc := HandleErrorProc; //runtime errors

end.
