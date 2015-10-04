unit ExtSortThread;

interface

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
  EExtSortThread = class(Exception);

  ISortThread = interface
    ['{584FBB13-9C6E-407A-A9BD-1643D5248946}']
    procedure Start;
    procedure Stop;
  end;

  IMergeManager = interface(ISortThread)
    ['{B9235DAE-87E5-4F03-9D44-109B1C86C468}']
    function Add(const AFilename: string): Boolean;
  end;


  TSortThread = class(TInterfacedObject, ISortThread)
  protected
    class var FStop: Integer;
  protected
    FFileReader     : IFileReader;
    FFileWriter     : IFileWriter;
    FFileReaderClass: TFileClass;
    FFileWriterClass: TFileClass;
    FThread         : TThread;
  public
    constructor Create(const AFileReader: IFileReader; const AFileReaderClass: TFileClass;
      // Класс файла для чтения
      const AFileWriterClass: TFileClass // Класс файла для записи
      ); reintroduce;
    destructor Destroy; override;
  public
    class procedure Initialize;
    function HasStopped: Boolean;
    procedure Stop; virtual;
    procedure Start; virtual; abstract;
  end;

  TMergeManager = class;

  TSeries = class(TSortThread)
    FEof: Boolean;
    FStringList: TList<AnsiString>;
    FAvailableMemory: Integer;
    FMerge: TMergeManager;
    procedure PopulateStringList;
    procedure SortStringList;
    procedure SaveStringList;
    procedure NotifyMergeManager(const ASeriesFileName: string);
    procedure ClearStringList;
  public
    constructor Create(const AFileReader: IFileReader; // Текстовый файл
      const AFileReaderClass: TFileClass;              // Класс файла для чтения
      const AFileWriterClass: TFileClass;              // Класс файла для записи
      const AMerge: IMergeManager                     // Объект заключительного слияния файлов
      ); reintroduce;
    destructor Destroy; override;
    procedure Start; override;
  end;

  TMergeManager = class(TSortThread, IMergeManager)
    FCounter: Integer;
    FFileName: string;
    FMerges: TList<ISortThread>;
    FQueue: TQueue<string>;
    FMutex: THandle;
  public
    constructor Create(const AFilename: string; // Имя отсортированного файла
      const AFileReader: IFileReader;           // Текстовый файл
      const AFileReaderClass: TFileClass;       // Класс файла для чтения
      const AFileWriterClass: TFileClass       // Класс файла для записи
      ); reintroduce;

    destructor Destroy; override;
  public
    procedure Start; override;
    function Add(const AFilename: string): Boolean;
  end;

  TMerge = class(TSortThread)
    FMergeManager: TMergeManager;
    FLeftFileName, FRightFileName: string;
    procedure MergeFiles;
  private
    FFileName: string;
  public
    constructor Create(const AFilename: string; // Имя отсортированного файла
      const AFileReader: IFileReader;           // Исходный текстовый файл
      const AFileNames: array of string;        // Имена сливаемых файлов
      const AMergeManager: TMergeManager;       // Менеджер слияния
      const AFileReaderClass: TFileClass;       // Класс файла для чтения
      const AFileWriterClass: TFileClass        // Класс файла для записи
      ); reintroduce;
  public
    procedure Start; override;
  end;

  ISortFactory = interface
    ['{3733A403-3813-478F-9E3A-B592D283A7D7}']
    function GetSeries(AReader: IFileReader; AMerge: IMergeManager)
      : ISortThread;
    function GetMergeManager: IMergeManager;
    procedure SetSrcFileName(const Value: string);
    procedure SetDscFileName(const Value: string);
    function GetReader: IFileReader;

    property SrcFileName: string write SetSrcFileName;
    property DscFilename: string write SetDscFileName;
    property Reader: IFileReader read GetReader;
  end;

  TSortFactory = class(TInterfacedObject, ISortFactory)
    FSrcFileName: string;
    FDscFileName: string;
    FFileReaderClass: TFileClass;
    FFileWriterClass: TFileClass;
  private
    procedure SetSrcFileName(const Value: string);
    procedure SetDscFileName(const Value: string);
  public
    constructor Create(AFileReaderClass, AFileWriterClass: TFileClass);
      reintroduce;
  public
    function GetMergeManager: IMergeManager;
    function GetSeries(AReader: IFileReader; AMergeManager: IMergeManager)
      : ISortThread;
    function GetReader: IFileReader;

    property SrcFileName: string write SetSrcFileName;
    property DscFilename: string write SetDscFileName;
    property Reader: IFileReader read GetReader;
  end;

implementation

function CompareShortString(const Left, Right: AnsiString): Integer;
var
  L, R: Word;
begin
  L      := Length(Left);
  R      := Length(Right);
  Result := System.AnsiStrings.AnsiStrLComp(@Left[1], @Right[1],
    Min(MAX_SIZE_COMPARE_STRING, Min(L, R)));
  if (Result = 0) and (L < R) then
    Result := -1;
  if (Result = 0) and (L > R) then
    Result := 1;

end;

{ TSortFactory }

constructor TSortFactory.Create(AFileReaderClass, AFileWriterClass: TFileClass);
begin
  FFileReaderClass := AFileReaderClass;
  FFileWriterClass := AFileWriterClass;
end;

function TSortFactory.GetMergeManager: IMergeManager;
var
  Reader: IFileReader;
begin
  Reader := FFileReaderClass.Create as IFileReader;
  Reader.Open(FSrcFileName);
  Result := TMergeManager.Create(FDscFileName, Reader, FFileReaderClass, FFileWriterClass);
end;

function TSortFactory.GetReader: IFileReader;
begin
  Result := FFileReaderClass.Create as IFileReader;
  Result.Open(FSrcFileName);
end;

function TSortFactory.GetSeries(AReader: IFileReader; AMergeManager: IMergeManager): ISortThread;
begin
  if AReader = nil then
    raise Exception.Create('Не указан интерфейс исходного файла');
  if AMergeManager = nil then
    raise Exception.Create('Не указан интерфейс слияния файла');
  Result := TSeries.Create(AReader, FFileReaderClass, FFileWriterClass, AMergeManager);
end;

procedure TSortFactory.SetDscFileName(const Value: string);
begin
  FDscFileName := Value;
  if Value = '' then
    raise Exception.Create('Не указано имя отсортированного файла');

  if FileExists(FDscFileName) then
    raise Exception.CreateFmt('Файл ''%'' уже существует' + #13#10 + 'Укажите новое имя файла',
      [FSrcFileName]);
end;

procedure TSortFactory.SetSrcFileName(const Value: string);
begin
  FSrcFileName := Value;
  if Value = '' then
    raise Exception.Create('Не указано имя сортируемого файла');

  if not FileExists(FSrcFileName) then
    raise Exception.CreateFmt('Файл ''%'' не найден', [FSrcFileName]);
end;

{ TBaseThread }

class procedure TSortThread.Initialize;
begin
  FStop := 0;
end;

constructor TSortThread.Create(const AFileReader: IFileReader;
  const AFileReaderClass, AFileWriterClass: TFileClass);
begin
  FFileReader      := AFileReader;
  FFileReaderClass := AFileReaderClass;
  FFileWriterClass := AFileWriterClass;
end;

destructor TSortThread.Destroy;
begin
  Stop;
  FreeAndNil(FThread);
  inherited;
end;

function TSortThread.HasStopped: Boolean;
begin
  Result := InterlockedCompareExchange(FStop, 1, 1) = 1;
end;

procedure TSortThread.Stop;
begin
  InterlockedExchange(FStop, 1);
end;

{ TSeries }

constructor TSeries.Create(const AFileReader: IFileReader; // Текстовый файл
  const AFileReaderClass: TFileClass;                      // Класс файла для чтения
  const AFileWriterClass: TFileClass;                      // Класс файла для записи
  const AMerge: IMergeManager                             // Менеджер слияния файлов
  );
begin
  inherited Create(AFileReader, AFileReaderClass, AFileWriterClass);
  FMerge           := AMerge as TMergeManager;
  FStringList      := TList<AnsiString>.Create;
  FAvailableMemory := AVAILABLE_MEMORY;
  FEof             := False;
end;

destructor TSeries.Destroy;
begin
  inherited;
  FreeAndNil(FStringList);
end;

procedure TSeries.NotifyMergeManager(const ASeriesFileName: string);
begin

  // Отправить файл для завершающего слияния
  while not HasStopped do
    if FMerge.Add(ASeriesFileName) then
      Break;
end;

procedure TSeries.PopulateStringList;
var
  S: AnsiString;
begin
  while FAvailableMemory > 0 do
  begin
    if not FFileReader.ReadString(S) then
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

procedure TSeries.SortStringList;
begin
  FStringList.Sort(TComparer<AnsiString>.Construct(CompareShortString));
end;

procedure TSeries.ClearStringList;
var
  S: AnsiString;
begin
  for S in FStringList do
    Inc(FAvailableMemory, Length(S));
  FStringList.Clear;
end;

procedure TSeries.SaveStringList;
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

procedure TSeries.Start;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while not HasStopped do
      begin
        PopulateStringList;
        SortStringList;
        SaveStringList;
        ClearStringList;
        if FEof then
          Break;
      end;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

{ TMerge }

constructor TMergeManager.Create(const AFilename: string; // Имя отсортированного файла
const AFileReader: IFileReader;                           // Текстовый файл
const AFileReaderClass: TFileClass;                       // Класс файла для чтения
const AFileWriterClass: TFileClass                       // Класс файла для записи
);
begin
  inherited Create(AFileReader, AFileReaderClass, AFileWriterClass);
  FFileName   := AFilename;
  FCounter    := 0;
  FFileReader := AFileReader;
  FMutex      := CreateMutex(nil, False, '');
  FQueue      := TQueue<string>.Create;
  FMerges     := TList<ISortThread>.Create;
end;

destructor TMergeManager.Destroy;
begin
  inherited;
  CloseHandle(FMutex);
  FreeAndNil(FQueue);
  FreeAndNil(FMerges);
end;

function TMergeManager.Add(const AFilename: string): Boolean;
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

procedure TMergeManager.Start;
var
  FMerge: ISortThread;
  S     : Integer;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while not HasStopped do
        case WaitForSingleObject(FMutex, 1000) of
          WAIT_OBJECT_0:
            try
              S := FQueue.Count;
              if FQueue.Count >= 2 then
              begin
                FMerge := TMerge.Create(FFileName, FFileReader,
                  [FQueue.Dequeue, FQueue.Dequeue], Self, FFileReaderClass, FFileWriterClass)
                  as ISortThread;
                FMerge.Start;
                FMerges.Add(FMerge);
              end;
            finally
              ReleaseMutex(FMutex);
            end;
          WAIT_TIMEOUT:
            Continue;
        else
          Break;
        end;
      S := 10;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

{ TMerge }

constructor TMerge.Create(const AFilename: string; const AFileReader: IFileReader;
const AFileNames: array of string; const AMergeManager: TMergeManager;
const AFileReaderClass, AFileWriterClass: TFileClass);
begin
  inherited Create(AFileReader, AFileReaderClass, AFileWriterClass);
  FFileName      := AFilename;
  FMergeManager  := AMergeManager;
  FLeftFileName  := AFileNames[0];
  FRightFileName := AFileNames[1];
end;

procedure TMerge.Start;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      MergeFiles;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TMerge.MergeFiles;

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
        if Writer.Size = FFileReader.Size then
        begin
          // Закончить сортировку
          Stop;
          // Остановить таймер
          PostMessage(Application.MainFormHandle, WM_SORT_HAS_FINISHED, 0, 0);
        end
        else
          // Отправить файл для слияния
          while not HasStopped do
            if FMergeManager.Add(MergeFileName) then
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
    RenameFile(MergeFileName, FFileName);

end;

end.
