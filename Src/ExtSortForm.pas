unit ExtSortForm;

interface

{$REGION 'uses'}

uses
  Winapi.Windows,
  Winapi.Messages,

  System.SysUtils,
  System.Variants,
  System.Classes,
  System.DateUtils,

  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ImgList,
  Vcl.ExtDlgs,

  System.UITypes,
  System.Diagnostics,
  System.Generics.Collections,
  System.Generics.Defaults,

  ExtSortFile,
  ExtSortThread;

{$ENDREGION}

type
  TMainForm = class(TForm)
    SrcButtonedEdit: TButtonedEdit;
    SortButton: TButton;
    DscButtonedEdit: TButtonedEdit;
    SrcLabel: TLabel;
    DestLabel: TLabel;
    StatusBar: TStatusBar;
    ImageList: TImageList;
    SaveTextFileDialog: TSaveTextFileDialog;
    OpenTextFileDialog: TOpenTextFileDialog;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure SortButtonClick(Sender: TObject);
    procedure SrcButtonedEditRightButtonClick(Sender: TObject);
    procedure DscButtonedEditRightButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TimerTimer(Sender: TObject);
  private
    FSortFactory : ISortFactory;
    FSeriesPool  : TList<ISortThread>;
    FMergeManager: IMergeManager;
    FTime        : TTime;
    procedure StartSort;
    procedure WmSortFinished(var Message: TMessage); message WM_SORT_HAS_FINISHED;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}
{$IFDEF DEBUG}

uses SimpleLogger;
{$ENDIF}
{$REGION 'StatusBarHelper - StatusInfo'}

type
  TStatusBarHelper = class Helper for TStatusBar
    procedure SetInfo(const AMsg: string);
    procedure ElapsedTime(const ATime: TTime);
  end;

procedure TStatusBarHelper.ElapsedTime(const ATime: TTime);
begin
  Panels[1].Text := FormatDateTime('hh:nn:ss', ATime);
end;

procedure TStatusBarHelper.SetInfo(const AMsg: string);
begin
  Panels[0].Text := AMsg;
end;

{$ENDREGION}

procedure TMainForm.SortButtonClick(Sender: TObject);
begin
  StatusBar.SetInfo('Сортировка ...');
  try
    // Запустить сортировку
    StartSort;
  except
    on E: Exception do
      StatusBar.SetInfo(Format('ОШИБКА: %s', [E.Message]));
  end;
end;

procedure TMainForm.SrcButtonedEditRightButtonClick(Sender: TObject);
begin
  // Файла - источник
  if OpenTextFileDialog.Execute then
  begin
    SrcButtonedEdit.Text := OpenTextFileDialog.FileName;
    StatusBar.SetInfo(Format('Файл - источник: %s', [SrcButtonedEdit.Text]));
  end;
end;

procedure TMainForm.DscButtonedEditRightButtonClick(Sender: TObject);
begin
  // Файл - приемник
  if SaveTextFileDialog.Execute then
  begin
    DscButtonedEdit.Text := SaveTextFileDialog.FileName;
    StatusBar.SetInfo(Format('Файл - приемник: %s', [DscButtonedEdit.Text]));
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FreeAndNil(FSeriesPool);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Фабрика объектов сортировки: серии, слияние
  FSortFactory := TSortFactory.Create(TFileReader, TFileWriter);
  // Пул потоков  создания серий
  FSeriesPool := TList<ISortThread>.Create;
end;

procedure TMainForm.TimerTimer(Sender: TObject);
begin
  FTime := IncSecond(FTime, 1);
  StatusBar.ElapsedTime(FTime);
end;

procedure TMainForm.WmSortFinished(var Message: TMessage);
begin
  StatusBar.SetInfo('Сортировка закончена');
  Timer.Enabled := False;
end;

procedure TMainForm.StartSort;
var
  Series     : ISortThread;
  TextFile   : IFileReader;
  FileSection: Int64;
  I          : Integer;
  L, H       : Int64;
begin
  FTime         := 0;
  Timer.Enabled := True;
  TSortThread.Initialize;
  FSortFactory.SrcFileName := SrcButtonedEdit.Text;
  FSortFactory.DscFileName := DscButtonedEdit.Text;

  // Разделить файл на равные части
  TextFile    := FSortFactory.Reader;
  FileSection := TextFile.Size div NUMBER_PROCESSOR;

{$IFDEF DEBUG}
  Log.LogStatus(Format('Сортируемый файл ''%s''', [SrcButtonedEdit.Text]), 'TMainForm.StartSort');
  Log.LogStatus(Format('Размер файла ''%d''', [TextFile.Size]), 'TMainForm.StartSort');
  Log.LogStatus(Format('Размер части файла ''%d''', [FileSection]), 'TMainForm.StartSort');
  Log.LogStatus(Format('Количество частей файла ''%d''', [NUMBER_PROCESSOR]),
    'TMainForm.StartSort');
{$ENDIF}
  // Интерфейс слияния
  FMergeManager := FSortFactory.GetMergeManager;
  FMergeManager.Start;

  for I := 0 to NUMBER_PROCESSOR - 1 do
  begin

    // Разделить файл на равные части
    TextFile := FSortFactory.Reader;
    L        := I * FileSection;
    H        := (I + 1) * FileSection;
    TextFile.SetBoundaries(L, H);

{$IFDEF DEBUG}
    Log.LogStatus(Format('Диапазон %d части ''%d - %d''', [I, L, H]), 'TMainForm.StartSort');
{$ENDIF}
    // Интерфейс серий
    Series := FSortFactory.GetSeries(TextFile, FMergeManager);
    Series.Start;
    // Добавить интерфейс серии в пул
    FSeriesPool.Add(Series);
  end;
end;

end.
