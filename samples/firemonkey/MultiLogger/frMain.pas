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
  Quick.Logger.Provider.Events,
  Quick.Threads, FMX.Memo.Types;

type
  TfrmMain = class(TForm)
    meLog: TMemo;
    btnGenerateLog: TButton;
    btnMultiThread: TButton;
    procedure btnGenerateLogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OnNewLog(LogItem : TLogItem);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnMultiThreadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  backgroundtasks : TBackgroundTasks;

implementation

{$R *.fmx}

procedure TfrmMain.btnGenerateLogClick(Sender: TObject);
begin
  Log('Test log entry created!',etError);
end;

procedure TfrmMain.btnMultiThreadClick(Sender: TObject);
var
  i : Integer;
begin
  for i := 1 to 10 do
  begin
    backgroundtasks.AddTask([i],False,procedure(task : ITask)
                          begin
                            Logger.Info('Logged from Task %d',[task[0].AsInteger]);
                          end).Run;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  backgroundtasks.Free;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  GlobalLogFileProvider.LogLevel := LOG_ALL;
  GlobalLogFileProvider.Enabled := True;
  GlobalLogFileProvider.IncludedInfo := GlobalLogFileProvider.IncludedInfo + [iiThreadId];
  Logger.Providers.Add(GlobalLogFileProvider);

  GlobalLogEventsProvider.LogLevel := LOG_ALL;
  GlobalLogEventsProvider.OnAny :=  OnNewLog;
  GlobalLogEventsProvider.Enabled := True;
  Logger.Providers.Add(GlobalLogEventsProvider);

  GlobalLogIDEDebugProvider.Enabled := True;
  Logger.Providers.Add(GlobalLogIDEDebugProvider);

  backgroundtasks := TBackgroundTasks.Create(10,100);
  backgroundtasks.Start;
end;

procedure TfrmMain.OnNewLog(LogItem: TLogItem);
begin
  TThread.Synchronize(nil,
  procedure
  begin
    meLog.Lines.Add(Format('%s [%s] %s (TreadId: %d)',[DateTimeToStr(LogItem.EventDate),LogItem.EventTypeName,LogItem.Msg,LogItem.ThreadId]));
  end
  );
end;

end.
