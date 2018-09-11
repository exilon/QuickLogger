unit frMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Quick.Logger,
  Quick.Logger.Provider.Files,
  Quick.Logger.Provider.Events, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.StdCtrls;

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
  Log('A log line was created on memo and file',etInfo);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  GlobalLogFileProvider.LogLevel := LOG_ALL;
  GlobalLogFileProvider.Enabled := True;
  GlobalLogEventsProvider.LogLevel := LOG_ALL;
  GlobalLogEventsProvider.OnAny := OnNewLog;
  GlobalLogEventsProvider.Enabled := True;
  Logger.Providers.Add(GlobalLogFileProvider);
  Logger.Providers.Add(GlobalLogEventsProvider);
end;

procedure TfrmMain.OnNewLog(LogItem: TLogItem);
begin
  meLog.Lines.Add(Format('%s [%s] %s',[DateTimeToStr(LogItem.EventDate),LogItem.EventTypeName,LogItem.Msg]));
end;

end.
