unit frMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.StdCtrls,
  Quick.Logger,
  Quick.Logger.Provider.Files,
  Quick.Logger.Provider.IDEDebug,
  Quick.Logger.Provider.Events;

type
  TfrmMain = class(TForm)
    meLog: TMemo;
    btnGenerateLog: TButton;
    procedure btnGenerateLogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OnNewLog(LogItem : TLogItem);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.btnGenerateLogClick(Sender: TObject);
begin
  Log('Test log entry created!',etError);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  GlobalLogFileProvider.LogLevel := LOG_ALL;
  GlobalLogFileProvider.Enabled := True;
  Logger.Providers.Add(GlobalLogFileProvider);

  GlobalLogEventsProvider.LogLevel := LOG_ALL;
  GlobalLogEventsProvider.OnAny :=  OnNewLog;
  GlobalLogEventsProvider.Enabled := True;
  Logger.Providers.Add(GlobalLogEventsProvider);

  GlobalLogIDEDebugProvider.Enabled := True;
  Logger.Providers.Add(GlobalLogIDEDebugProvider);

end;

procedure TfrmMain.OnNewLog(LogItem: TLogItem);
begin
  TThread.Synchronize(nil,
  procedure
  begin
    meLog.Lines.Add(Format('%s [%s] %s',[DateTimeToStr(LogItem.EventDate),LogItem.EventTypeName,LogItem.Msg]));
  end
  );
end;

end.
