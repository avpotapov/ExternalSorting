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

  WM_UPDATE_SERIES_PROGRESS = WM_USER + 1;
  WM_UPDATE_MERGE_PROGRESS  = WM_USER + 2;
  WM_UPDATE_SORT_FINISHED   = WM_USER + 3;

type
  EExtSortThread = class(Exception);

  ISeries = interface
    ['{584FBB13-9C6E-407A-A9BD-1643D5248946}']
    procedure Start;
    procedure Stop;
  end;

  IMerge = interface(ISeries)
    ['{B9235DAE-87E5-4F03-9D44-109B1C86C468}']
    function Add(const AFilename: string): Boolean;
  end;

  TBaseThread = class(TInterfacedObject, ISeries)
  protected
    class var FStop: Integer;
  protected
    FFileReader     : IFileReader;
    FFileWriter     : IFileWriter;
    FFileReaderClass: TFileClass;
    FFileWriterClass: TFileClass;
    FThread         : TThread;
    FTempFileName   : string;
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

  TSeries = class(TBaseThread)
    FInfo: Boolean;
    FEof: Boolean;
    FStringList: TList<AnsiString>;
    FAvailableMemory: Integer;
    FMerge: IMerge;
    procedure PopulateStringList;
    procedure SortStringList;
    procedure SaveStringList;
    procedure MergeStringList;
    procedure ClearStringList;
    procedure MergeWithFile;
  public
    constructor Create(const AFileReader: IFileReader; // Текстовый файл
      const AFileReaderClass: TFileClass;              // Класс файла для чтения
      const AFileWriterClass: TFileClass;              // Класс файла для записи
      const AMerge: IMerge;                            // Объект заключительного слияния файлов
      const AInfo: Boolean = False // Флаг отправки позиции чтения файла в ProgressBar
      ); reintroduce;
    destructor Destroy; override;
    procedure Start; override;
  end;

  TMerge = class(TBaseThread, IMerge)
    FCounter: Integer;
    FFileName: string;
    FQueue: TQueue<string>;
    FMutex: THandle;
    // Массив ожидаемых событий
    // Mutex + FEvents[0]
    FEvents: array [0 .. 1] of THandle;
  private
    procedure MergeFiles(const AFilename: string);
  public
    constructor Create(const AFilename: string; // Имя отсортированного файла
      const AFileReader: IFileReader;           // Текстовый файл
      const AFileReaderClass: TFileClass;       // Класс файла для чтения
      const AFileWriterClass: TFileClass        // Класс файла для записи
      ); reintroduce;

    destructor Destroy; override;
  public
    procedure Start; override;
    function Add(const AFilename: string): Boolean;
  end;

  ISortFactory = interface
    ['{3733A403-3813-478F-9E3A-B592D283A7D7}']
    function GetSeries(AReader: IFileReader; AMerge: IMerge; AInfo: Boolean = False): ISeries;
    function GetMerge: IMerge;
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
    constructor Create(AFileReaderClass, AFileWriterClass: TFileClass); reintroduce;
  public
    function GetMerge: IMerge;
    function GetSeries(AReader: IFileReader; AMerge: IMerge; AInfo: Boolean = False): ISeries;
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

function TSortFactory.GetMerge: IMerge;
var
  Reader: IFileReader;
begin
  Reader := FFileReaderClass.Create as IFileReader;
  Reader.Open(FSrcFileName);
  Result := TMerge.Create(FDscFileName, Reader, FFileReaderClass, FFileWriterClass);
end;

function TSortFactory.GetReader: IFileReader;
begin
  Result := FFileReaderClass.Create as IFileReader;
  Result.Open(FSrcFileName);
end;

function TSortFactory.GetSeries(AReader: IFileReader; AMerge: IMerge; AInfo: Boolean): ISeries;
begin
  if AReader = nil then
    raise Exception.Create('Не указан интерфейс исходного файла');
  if AMerge = nil then
    raise Exception.Create('Не указан интерфейс слияния файла');
  Result := TSeries.Create(AReader, FFileReaderClass, FFileWriterClass, AMerge, AInfo);
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

class procedure TBaseThread.Initialize;
begin
  FStop := 0;
end;

constructor TBaseThread.Create(const AFileReader: IFileReader;
  const AFileReaderClass, AFileWriterClass: TFileClass);
begin
  FTempFileName    := '';
  FFileReader      := AFileReader;
  FFileReaderClass := AFileReaderClass;
  FFileWriterClass := AFileWriterClass;
end;

destructor TBaseThread.Destroy;
begin
  Stop;
  FreeAndNil(FThread);
  inherited;
end;

function TBaseThread.HasStopped: Boolean;
begin
  Result := InterlockedCompareExchange(FStop, 1, 1) = 1;
end;

procedure TBaseThread.Stop;
begin
  InterlockedExchange(FStop, 1);
end;

{ TSeries }

constructor TSeries.Create(const AFileReader: IFileReader; // Текстовый файл
  const AFileReaderClass: TFileClass;                      // Класс файла для чтения
  const AFileWriterClass: TFileClass;                      // Класс файла для записи
  const AMerge: IMerge; // Интерфейс, который получает отрезок для слияния файлов
  const AInfo: Boolean = False // Флаг отправки позиции чтения файла в ProgressBar
  );
begin
  inherited Create(AFileReader, AFileReaderClass, AFileWriterClass);
  FMerge           := AMerge;
  FStringList      := TList<AnsiString>.Create;
  FAvailableMemory := AVAILABLE_MEMORY;
  FEof             := False;
  FInfo            := AInfo;
end;

destructor TSeries.Destroy;
begin
  inherited;
  FreeAndNil(FStringList);
end;

procedure TSeries.MergeStringList;
begin
  if FTempFileName = '' then
    SaveStringList
  else
    MergeWithFile;
end;

procedure TSeries.MergeWithFile;

// Основная процедура слияния списка и файла
  procedure Merge(const AReader: IFileReader; const AWriter: IFileWriter);
  var
    Index         : Integer;
    StringFromFile: AnsiString;
    IsReadString  : Boolean;
  begin
    Index        := 0;
    IsReadString := AReader.ReadString(StringFromFile);

    // Слияние
    while (FStringList.Count > Index) and IsReadString do
    begin
      if CompareShortString(FStringList[Index], StringFromFile) < 0 then
      begin
        AWriter.WriteString(FStringList[Index]);
        Inc(Index);
      end
      else
      begin
        AWriter.WriteString(StringFromFile);
        IsReadString := AReader.ReadString(StringFromFile);
      end;
    end;

    // Хвостовая запись
    while IsReadString do
    begin
      AWriter.WriteString(StringFromFile);
      IsReadString := AReader.ReadString(StringFromFile);
    end;

    while (FStringList.Count > Index) do
    begin
      AWriter.WriteString(FStringList[Index]);
      Inc(Index);
    end;
  end;

var
  FileReader     : IFileReader;
  FileWriter     : IFileWriter;
  NewTempFileName: string;
begin
  NewTempFileName := TFileWriter.MakeRandomFileName;

  FileReader := FFileReaderClass.Create as IFileReader;
  FileReader.Open(FTempFileName);
  try
    FileWriter := FFileWriterClass.Create as IFileWriter;
    FileWriter.Open(NewTempFileName);
    try
      Merge(FileReader, FileWriter);
    finally
      FileWriter.Close;
    end;
  finally
    FileReader.Close;
    DeleteFile(FTempFileName);
    FTempFileName := NewTempFileName;
  end;

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
  S         : AnsiString;
  FileWriter: IFileWriter;
begin
  FTempFileName := TFileWriter.MakeRandomFileName;
  FileWriter    := FFileWriterClass.Create as IFileWriter;
  FileWriter.Open(FTempFileName);
  try
    for S in FStringList do
      FileWriter.WriteString(S);
  finally
    FileWriter.Close;
  end;
end;

procedure TSeries.Start;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    var
      Size: Int64;
    begin
      Size := FFileReader.Size div NUMBER_PROCESSOR;
      while not HasStopped do
      begin
        PopulateStringList;
        SortStringList;
        MergeStringList;
        ClearStringList;
        if FEof then
          Break;
        if FInfo then
          SendMessage(Application.MainFormHandle, WM_UPDATE_SERIES_PROGRESS,
            FFileReader.Position, Size);
      end;

      // Отправить файл для завершающего слияния
      while not HasStopped do
        if FMerge.Add(FTempFileName) then
          Break;

      if FInfo then
        SendMessage(Application.MainFormHandle, WM_UPDATE_SERIES_PROGRESS, 0, Size);

    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

{ TMerge }

constructor TMerge.Create(const AFilename: string; // Имя отсортированного файла
const AFileReader: IFileReader;                    // Текстовый файл
const AFileReaderClass: TFileClass;                // Класс файла для чтения
const AFileWriterClass: TFileClass                 // Класс файла для записи
  );
begin
  inherited Create(AFileReader, AFileReaderClass, AFileWriterClass);
  FFileName   := AFilename;
  FCounter    := 0;
  FFileReader := AFileReader;
  FMutex      := CreateMutex(nil, False, '');
  FEvents[0]  := CreateEvent(nil, False, False, '');
  FEvents[1]  := FMutex;
  FQueue      := TQueue<string>.Create;
end;

destructor TMerge.Destroy;
begin
  inherited;
  CloseHandle(FEvents[0]);
  CloseHandle(FMutex);
  FreeAndNil(FQueue);
end;

function TMerge.Add(const AFilename: string): Boolean;
begin
  if WaitForSingleObject(FMutex, 1000) <> WAIT_OBJECT_0 then
    Exit(False);
  try
    FQueue.Enqueue(AFilename);
    SetEvent(FEvents[0]);
    Result := True;
  finally
    ReleaseMutex(FMutex);
  end;

end;

procedure TMerge.Start;
var
  FileName: string;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while not HasStopped do
        case WaitForMultipleObjects(2, @FEvents, True, 1000) of
          WAIT_OBJECT_0:
            try
              while FQueue.Count > 0 do
              begin
                FileName := FQueue.Dequeue;
                if FTempFileName = '' then
                  FTempFileName := FileName
                else
                begin
                  MergeFiles(FileName);
                end;
                Inc(FCounter);
              end;
              if FCounter = NUMBER_PROCESSOR then
                Stop;
            finally
              ReleaseMutex(FMutex);
            end;
          WAIT_TIMEOUT:
            Continue;

        else
          Break;
        end;
      if FTempFileName <> '' then
      begin
        RenameFile(FTempFileName, FFileName);
        PostMessage(Application.MainFormHandle, WM_UPDATE_SORT_FINISHED, 0, 0);
      end;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TMerge.MergeFiles(const AFilename: string);

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
      SendMessage(Application.MainFormHandle, WM_UPDATE_MERGE_PROGRESS, Right.Position, Right.Size);
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
      SendMessage(Application.MainFormHandle, WM_UPDATE_MERGE_PROGRESS, Right.Position, Right.Size);
    end;

    SendMessage(Application.MainFormHandle, WM_UPDATE_MERGE_PROGRESS, 0, Right.Size);

  end;

var
  Left, Right: IFileReader;
  Writer     : IFileWriter;
  NewFileName: string;
begin
  Left := FFileReaderClass.Create as IFileReader;
  Left.Open(FTempFileName);
  try
    Right := FFileReaderClass.Create as IFileReader;
    Right.Open(AFilename);
    try
      NewFileName := TFileWriter.MakeRandomFileName;
      Writer      := FFileWriterClass.Create as IFileWriter;
      Writer.Open(NewFileName);
      try
        Merge(Left, Right, Writer);
      finally
        Writer.Close;
      end;
    finally
      Right.Close;
//      DeleteFile(AFilename)
    end;
  finally
    Left.Close;
//    DeleteFile(FTempFileName);
    FTempFileName := NewFileName;
  end;
end;

end.
