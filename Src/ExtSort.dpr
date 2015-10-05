program ExtSort;

uses
  Vcl.Forms,
  ExtSortForm in 'ExtSortForm.pas' {MainForm},
  SimpleLogger in 'SimpleLogger.pas',
  ExtSortFile in 'ExtSortFile.pas',
  ExtSortFactory in 'ExtSortFactory.pas',
  ExtSortThread in 'ExtSortThread.pas';

{$R *.res}

begin
  Application.Initialize;
{$REGION 'Debug'}
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
{$ENDREGION}
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

end.
