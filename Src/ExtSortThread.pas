unit ExtSortThread;

interface

{$REGION 'Описание модуля'}
 (*
  *  Модуль объектов сортировки
  *
  *  Алгорит сортировки состоит из 2 фаз
  *
  *  - СОЗДАНИЕ СЕРИЙ
  *  Запущенные SeriesCreator порционно считывают переданные им части файла в буфер обмена,
  *  размер которого лимитирован.
  *  Затем в буфере выполняется быстрая сортировка строк методом QuickSort. Учитывается длина
  *  сортируемой строки.
  *  В итоге образуется серия (отсортированный отрезок), который сохраняется в файл.
  *  Имя файла помещается в потокобезопасную очередь MergeController.
  *  Далее цикл повторяется, пока не будет обработан таким образом последний участок файла
  *
  *  - СЛИЯНИЕ
  *  Как только в буфере MergeController появляются 2 и более отрезка, запускается создание
  *  объекта слияния, которому передаются имена отрезков
  *  Процесс повторяется пока очередь не опустеет
  *  В объекте объединяются два файла в один, используя функцию слияния.
  *  Если размер файла соответствует размеру неотсортированного файла, то цель достигнута.
  *  Сортировка прекращается.
  *  В противном случае файл передается контроллеру слияния.
  *  Количество одновременно работающих потоков не превышает 4. За это отвечает семафор в
  *  контроллере слияния
  *)
{$ENDREGION}

uses
  Winapi.Windows,
  Winapi.Messages,

  System.Classes,
  System.AnsiStrings,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SysUtils,

  Vcl.Forms,

  ExtSortFile;

const
  AVAILABLE_MEMORY = $100000 shr 2;
  NUMBER_PROCESSOR = 4;

  WM_SORT_HAS_FINISHED = WM_USER + 1;

type
  TSortClass = class of TAbstractSort;

  ISort = interface
    ['{584FBB13-9C6E-407A-A9BD-1643D5248946}']
    procedure Start;
    procedure Stop;
    procedure SetSrcFileReader(Value: IFileReader);
    /// <summary>
    /// Сортируемый файл
    /// </summary>
    property SrcFileReader: IFileReader write SetSrcFileReader;
  end;

  /// <summary>
  /// Управляет процессом слияния файлов:
  /// накапливает имена файлов - отрезков в списке,
  /// запускает слияние двух файлов
  /// </summary>
  IMergeController = interface(ISort)
    ['{B9235DAE-87E5-4F03-9D44-109B1C86C468}']
    function Add(const AFilename: string): Boolean;
    procedure SetMergerClass(const Value: TSortClass);
    /// <summary>
    /// Класс объекта слияния
    /// </summary>
    property MergerClass: TSortClass write SetMergerClass;
  end;

  IPhase = interface(ISort)
    ['{ED42A5DE-6DB1-419C-B1B7-6D318E5F66F0}']
    procedure SetMergeController(Value: IMergeController);
    /// <summary>
    /// Контроллер слияния
    /// </summary>
    property MergeController: IMergeController write SetMergeController;
  end;

  /// <summary>
  /// Производит слияния файлов:
  /// если размер нового файла слияния меньше размера исходного файла,
  /// передает этот файл контроллеру слияния,
  /// в противном случае цель достугнута.
  /// </summary>
  IMerger = interface(IPhase)
    ['{21D4607E-B847-4023-BB0C-BA8F050FD2CF}']
    procedure SetLeftFileName(const Value: string);
    procedure SetRightFileName(const Value: string);
    procedure SetDscFileName(const Value: string);
    /// <summary>
    /// Первый файл слияния
    /// </summary>
    property LeftFileName: string write SetLeftFileName;
    /// <summary>
    /// Второй файл слияния
    /// </summary>
    property RightFileName: string write SetRightFileName;
    /// <summary>
    /// Имя отсортированного файла
    /// </summary>
    property DscFileName: string write SetDscFileName;
  end;
{$REGION 'TSort'}

  TAbstractSort = class abstract(TInterfacedObject, ISort)
  protected
    class var FStop: Integer;
  protected
    FSrcFileReader  : IFileReader;
    FFileReaderClass: TFileClass;
    FFileWriterClass: TFileClass;
    FThread         : TThread;
  private
    procedure SetSrcFileReader(Value: IFileReader);
  public
    constructor Create(const AFileClass: array of TFileClass); reintroduce; virtual;
    destructor Destroy; override;
  public
    class procedure Initialize;
    function HasStopped: Boolean;
    procedure Stop; virtual;
    procedure Start; virtual; abstract;
    property SrcFileReader: IFileReader write SetSrcFileReader;
  end;
{$ENDREGION}
{$REGION 'TPhase'}

  TMergeController = class;

  TPhase = class(TAbstractSort)
  protected
    FMergeController: TMergeController;
  private
    procedure SetMergeController(Value: IMergeController);
  public
    property MergeController: IMergeController write SetMergeController;
  end;
{$ENDREGION}
{$REGION 'TSeries'}

  /// <summary>
  /// Из считанных частей файла в буфер (размер буфера ограничен)
  /// создает отрезок,
  /// сохраняет его в файл,
  /// и передает контроллеру слияния
  /// </summary>
  TSeriesCreator = class(TPhase, IPhase)
    FEof: Boolean;
    FStringList: TList<AnsiString>;
    FAvailableMemory: Integer;
    FMerge: TMergeController;
    procedure PopulateStringList;
    procedure SortStringList;
    procedure SaveStringList;
    procedure NotifyMergeManager(const ASeriesFileName: string);
    procedure ClearStringList;
  public
    constructor Create(const AFileClass: array of TFileClass); override;
    destructor Destroy; override;
  public
    procedure Start; override;
  end;

{$ENDREGION}
{$REGION 'TMergeController'}

  TMergeController = class(TAbstractSort, IMergeController)
    FMergerClass: TSortClass;
    FCounter: Integer;
    FMerges: TList<ISort>;
    FQueue: TQueue<string>;
    FMutex: THandle;
    FSemaphore: THandle;
    // FMutex + FSemaphore
    FWaitHandles: array [0 .. 1] of THandle;
    procedure SetMergerClass(const Value: TSortClass);
  public
    constructor Create(const AFileClass: array of TFileClass); override;
    destructor Destroy; override;
  public
    procedure HasDone;
    procedure Start; override;
    function Add(const AFilename: string): Boolean;
    property MergerClass: TSortClass write SetMergerClass;
  end;
{$ENDREGION}
{$REGION 'TMerger'}

  TMerger = class(TPhase, IMerger)
    FLeftFileName, FRightFileName, FDscFileName: string;
    procedure SetLeftFileName(const Value: string);
    procedure SetRightFileName(const Value: string);
    procedure SetDscFileName(const Value: string);
    procedure MergeFiles;
  public
    procedure Start; override;
    property LeftFileName: string write SetLeftFileName;
    property RightFileName: string write SetRightFileName;
    property DscFileName: string write SetDscFileName;
  end;

{$ENDREGION}

implementation

uses
  ExtSortFactory;

function CompareShortString(const Left, Right: AnsiString): Integer;
var
  L, R: Word;
begin
  L      := Length(Left);
  R      := Length(Right);
  Result := System.AnsiStrings.AnsiStrLComp(@Left[1], @Right[1], Min(MAX_SIZE_COMPARE_STRING, Min(L, R)));
  if (Result = 0) and (L < R) then
    Result := -1;
  if (Result = 0) and (L > R) then
    Result := 1;
end;

{$REGION 'TSort'}

class procedure TAbstractSort.Initialize;
begin
  FStop := 0;
end;

constructor TAbstractSort.Create(const AFileClass: array of TFileClass);
begin
  FFileReaderClass := AFileClass[0];
  FFileWriterClass := AFileClass[1];
end;

destructor TAbstractSort.Destroy;
begin
  Stop;
  FreeAndNil(FThread);
  inherited;
end;

function TAbstractSort.HasStopped: Boolean;
begin
  Result := InterlockedCompareExchange(FStop, 1, 1) = 1;
end;

procedure TAbstractSort.SetSrcFileReader(Value: IFileReader);
begin
  FSrcFileReader := Value;
end;

procedure TAbstractSort.Stop;
begin
  InterlockedExchange(FStop, 1);
end;

{$ENDREGION}
{$REGION 'TPhase'}

procedure TPhase.SetMergeController(Value: IMergeController);
begin
  FMergeController := Value as TMergeController;
end;
{$ENDREGION}
{$REGION 'TSeries'}

constructor TSeriesCreator.Create(const AFileClass: array of TFileClass);
begin
  inherited Create(AFileClass);
  FStringList      := TList<AnsiString>.Create;
  FAvailableMemory := AVAILABLE_MEMORY;
  FEof             := False;
end;

destructor TSeriesCreator.Destroy;
begin
  inherited;
  FreeAndNil(FStringList);
end;

procedure TSeriesCreator.NotifyMergeManager(const ASeriesFileName: string);
begin
  // Отправить файл для завершающего слияния
  while not HasStopped do
    if FMergeController.Add(ASeriesFileName) then
      Break;
end;

procedure TSeriesCreator.PopulateStringList;
var
  S: AnsiString;
begin
  while FAvailableMemory > 0 do
  begin
    if not FSrcFileReader.ReadString(S) then
    begin
      FEof := True;
      Break;
    end;
    if HasStopped then
      Break;
    FStringList.Add(S);
    Dec(FAvailableMemory, Length(S));
  end;
end;

procedure TSeriesCreator.SortStringList;
begin
  FStringList.Sort(TComparer<AnsiString>.Construct(CompareShortString));
end;

procedure TSeriesCreator.ClearStringList;
var
  S: AnsiString;
begin
  for S in FStringList do
    Inc(FAvailableMemory, Length(S));
  FStringList.Clear;
end;

procedure TSeriesCreator.SaveStringList;
var
  S             : AnsiString;
  FileWriter    : IFileWriter;
  SeriesFileName: string;
begin
  SeriesFileName := TFileWriter.MakeRandomFileName;
  FileWriter     := FFileWriterClass.Create as IFileWriter;
  FileWriter.Open(SeriesFileName);
  try
    // Сохранить серию в файл
    for S in FStringList do
      FileWriter.WriteString(S);
    // Отправить имя файла менеджеру слияний
    NotifyMergeManager(SeriesFileName);
  finally
    FileWriter.Close;
  end;
end;

procedure TSeriesCreator.Start;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while not HasStopped do
      begin
        try
          PopulateStringList;
          SortStringList;
          SaveStringList;
          ClearStringList;
          if FEof then
            Break;
        finally
          FMergeController.HasDone;
        end;
      end;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

{$ENDREGION}
{$REGION 'TMergeController'}

constructor TMergeController.Create(const AFileClass: array of TFileClass);
begin
  inherited Create(AFileClass);
  FCounter        := 0;
  FMutex          := CreateMutex(nil, False, '');
  FSemaphore      := CreateSemaphore(nil, 0, NUMBER_PROCESSOR, '');
  FWaitHandles[0] := FMutex;
  FWaitHandles[1] := FSemaphore;
  FQueue          := TQueue<string>.Create;
  FMerges         := TList<ISort>.Create;
end;

destructor TMergeController.Destroy;
begin
  inherited;
  CloseHandle(FMutex);
  CloseHandle(FSemaphore);
  FreeAndNil(FQueue);
  FreeAndNil(FMerges);
end;

procedure TMergeController.HasDone;
var
  PrevCount: LongInt;
begin
  ReleaseSemaphore(FSemaphore, 1, @PrevCount);
end;

procedure TMergeController.SetMergerClass(const Value: TSortClass);
begin
  FMergerClass := Value;
end;

function TMergeController.Add(const AFilename: string): Boolean;
begin
  if WaitForSingleObject(FMutex, 1000) <> WAIT_OBJECT_0 then
    Exit(False);
  try
    FQueue.Enqueue(AFilename);
    Result := True;
  finally
    ReleaseMutex(FMutex);
  end;
end;

procedure TMergeController.Start;
var
  Merge: ISort;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while not HasStopped do
        case WaitForMultipleObjects(2, @FWaitHandles, True, 1000) of
          WAIT_OBJECT_0:
            try
              if FQueue.Count >= 2 then
              begin
                Merge := TSortFactorySingleton.GetInstance.GetMerger(Self, [FQueue.Dequeue, FQueue.Dequeue]);
                Merge.Start;
                FMerges.Add(Merge);
              end;
            finally
              ReleaseMutex(FMutex);
            end;
          WAIT_TIMEOUT:
            Continue;
        else
          Break;
        end;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

{$ENDREGION}
{$REGION 'Merger'}

procedure TMerger.SetDscFileName(const Value: string);
begin
  FDscFileName := Value;
end;

procedure TMerger.SetLeftFileName(const Value: string);
begin
  FLeftFileName := Value;
end;

procedure TMerger.SetRightFileName(const Value: string);
begin
  FRightFileName := Value;
end;

procedure TMerger.Start;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        MergeFiles;
      finally
        FMergeController.HasDone;
      end;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TMerger.MergeFiles;
  procedure Merge(Left, Right: IFileReader; Writer: IFileWriter);
  var
    LStr, RStr                        : AnsiString;
    LIsReadingString, RIsReadingString: Boolean;
  begin
    LIsReadingString := Left.ReadString(LStr);
    RIsReadingString := Right.ReadString(RStr);
    while LIsReadingString and RIsReadingString do
    begin
      if CompareShortString(LStr, RStr) < 0 then
      begin
        Writer.WriteString(LStr);
        LIsReadingString := Left.ReadString(LStr);
      end
      else
      begin
        Writer.WriteString(RStr);
        RIsReadingString := Right.ReadString(RStr);
      end;
    end;
    while LIsReadingString do
    begin
      Writer.WriteString(LStr);
      LIsReadingString := Left.ReadString(LStr);
    end;
    while RIsReadingString do
    begin
      Writer.WriteString(RStr);
      RIsReadingString := Right.ReadString(RStr);
    end;
  end;

var
  Left, Right  : IFileReader;
  Writer       : IFileWriter;
  MergeFileName: string;
begin
  Left := FFileReaderClass.Create as IFileReader;
  Left.Open(FLeftFileName);
  try
    Right := FFileReaderClass.Create as IFileReader;
    Right.Open(FRightFileName);
    try
      MergeFileName := TFileWriter.MakeRandomFileName;
      Writer        := FFileWriterClass.Create as IFileWriter;
      Writer.Open(MergeFileName);
      try
        Merge(Left, Right, Writer);
        if Writer.Size = FSrcFileReader.Size then
        begin
          // Закончить сортировку
          Stop;
          // Остановить таймер
          PostMessage(Application.MainFormHandle, WM_SORT_HAS_FINISHED, 0, 0);
        end
        else
          // Отправить файл для слияния
          while not HasStopped do
            if FMergeController.Add(MergeFileName) then
              Break;
      finally
        Writer.Close;
      end;
    finally
      Right.Close;
      DeleteFile(FRightFileName)
    end;
  finally
    Left.Close;
    DeleteFile(FLeftFileName);
  end;
  if HasStopped then
    // Переименовать файл
    RenameFile(MergeFileName, FDscFileName);
end;
{$ENDREGION}

end.
