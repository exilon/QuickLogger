{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.Logger.ExceptionHook
  Description : Log raised Exceptions
  Author      : Kike Pérez
  Version     : 1.20
  Created     : 12/10/2017
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
unit Quick.Logger.ExceptionHook;

{$i QuickLib.inc}

interface

implementation

uses
  SysUtils,
  System.TypInfo,
  Quick.Logger;

//var
  //RealRaiseExceptObject: Pointer;

type
  EExceptionHack = class
  public
    FMessage: string;
    FHelpContext: Integer;
    FInnerException: Exception;
    FStackInfo: Pointer;
    FAcquireInnerException: Boolean;
  end;

procedure RaiseExceptObject(pExRec: PExceptionRecord);
type
  TRaiseExceptObjectProc = procedure(pExRec: PExceptionRecord);
begin
  if TObject(pExRec^.ExceptObject) is Exception then EExceptionHack(pExRec^.ExceptObject).FAcquireInnerException := True;
  //throw event in Quick Logger to log it
  if Assigned(GlobalLoggerHandledException) then
  begin
    {$IFDEF DELPHILINUX}
    GlobalLoggerHandledException(Pointer(pExRec^.ExceptObject));
    {$ELSE}
    GlobalLoggerHandledException(pExRec^.ExceptObject);
    {$ENDIF}
  end;
  //throw real exception
  //if Assigned(RealRaiseExceptObject) then TRaiseExceptObjectProc(RealRaiseExceptObject)(pExRec);
end;

initialization
  //RealRaiseExceptObject := RaiseExceptObjProc;
  RaiseExceptObjProc := @RaiseExceptObject; //raised exceptions

end.
