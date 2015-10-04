program ExtSort;

uses
  Vcl.Forms,
  ExtSortForm in 'ExtSortForm.pas' {MainForm},
  ExtSortThread in 'ExtSortThread.pas',
  SimpleLogger in 'SimpleLogger.pas',
  ExtSortFile in 'ExtSortFile.pas';

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
