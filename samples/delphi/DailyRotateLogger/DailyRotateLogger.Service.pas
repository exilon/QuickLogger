unit DailyRotateLogger.Service;

interface

uses
  Quick.Logger,
  Quick.Logger.Provider.Files,
  Quick.Logger.ExceptionHook,
  Quick.Threads;

type
  TMyService = class
  private
    fScheduler : TScheduledTasks;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Execute;
  end;

implementation

constructor TMyService.Create;
begin
  fScheduler := TScheduledTasks.Create;
  GlobalLogFileProvider.DailyRotate := True;
  GlobalLogFileProvider.DailyRotateFileDateFormat := 'yyyymmdd';
  GlobalLogFileProvider.MaxRotateFiles := 10;
  GlobalLogFileProvider.MaxFileSizeInMB := 10;
  GlobalLogFileProvider.RotatedFilesPath := '.\logs';
  Logger.Providers.Add(GlobalLogFileProvider);
  GlobalLogFileProvider.Enabled := True;
end;

destructor TMyService.Destroy;
begin
  fScheduler.Free;
  inherited;
end;

procedure TMyService.Execute;
begin
  fScheduler.AddTask('LogToFile',procedure(aTask : ITask)
    begin
      Logger.Info('Logged a new entry');
    end
  ).StartNow.RepeatEvery(10,TTimeMeasure.tmSeconds);
  fScheduler.Start;
end;


end.
