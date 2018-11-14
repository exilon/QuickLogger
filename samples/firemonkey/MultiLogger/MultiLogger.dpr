program MultiLogger;

uses
  System.StartUpCopy,
  FMX.Forms,
  frMain in 'frMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
