unit ExtSortFactory;

interface

uses
  System.Classes,
  System.SysUtils,
  ExtSortThread,

  ExtSortFile;

type
  EExtSortFactory = class(Exception);

  ISortFactorySingleton = interface
    ['{D1D19AB8-2892-4F75-B7AA-2A90BA6D9C3D}']

    // Фабрики
    function GetReader(const AFileName: string): IFileReader;
    function GetWriter(const AFileName: string): IFileWriter;

    function GetMergerController: IMergeController;
    function GetSeriesCreator(AMergeController: IMergeController; const ABoundaries: array of Int64): IPhase;
    function GetMerger(AMergeController: IMergeController; const AFileNames: array of string): IMerger;

    procedure SetSrcFileName(const Value: string);
    procedure SetDscFileName(const Value: string);
    procedure SetFileReaderClass(const Value: TFileClass);
    procedure SetFileWriterClass(const Value: TFileClass);
    procedure SetSeriesCreatorClass(const Value: TSortClass);
    procedure SetMergerClass(const Value: TSortClass);
    procedure SetMergeControllerClass(const Value: TSortClass);

    property SrcFileName: string write SetSrcFileName;
    property DscFileName: string write SetDscFileName;
    property FileReaderClass: TFileClass write SetFileReaderClass;
    property FileWriterClass: TFileClass write SetFileWriterClass;
    property SeriesCreatorClass: TSortClass write SetSeriesCreatorClass;
    property MergerClass: TSortClass write SetMergerClass;
    property MergeControllerClass: TSortClass write SetMergeControllerClass;

  end;
{$REGION 'TSortFactorySingleton'}

  TSortFactorySingleton = class(TInterfacedObject, ISortFactorySingleton)
  strict private
  class var
    FInstance: ISortFactorySingleton;

    FSrcFileName         : string;
    FDscFileName         : string;
    FFileReaderClass     : TFileClass;
    FFileWriterClass     : TFileClass;
    FSeriesCreatorClass  : TSortClass;
    FMergerClass         : TSortClass;
    FMergeControllerClass: TSortClass;

    procedure SetSrcFileName(const Value: string);
    procedure SetDscFileName(const Value: string);
    procedure SetFileReaderClass(const Value: TFileClass);
    procedure SetFileWriterClass(const Value: TFileClass);
    procedure SetSeriesCreatorClass(const Value: TSortClass);
    procedure SetMergerClass(const Value: TSortClass);
    procedure SetMergeControllerClass(const Value: TSortClass);

    constructor Create;
  public
    class function GetInstance: ISortFactorySingleton;

    // Фабрики
    function GetReader(const AFileName: string): IFileReader;
    function GetWriter(const AFileName: string): IFileWriter;

    function GetMergerController: IMergeController;
    function GetSeriesCreator(AMergeController: IMergeController; const ABoundaries: array of Int64): IPhase;
    function GetMerger(AMergeController: IMergeController; const AFileNames: array of string): IMerger;

    // Настройки фабрики
    property SrcFileName: string write SetSrcFileName;
    property DscFileName: string write SetDscFileName;
    property FileReaderClass: TFileClass write SetFileReaderClass;
    property FileWriterClass: TFileClass write SetFileWriterClass;
    property SeriesCreatorClass: TSortClass write SetSeriesCreatorClass;
    property MergerClass: TSortClass write SetMergerClass;
    property MergeControllerClass: TSortClass write SetMergeControllerClass;

  end;

{$ENDREGION}

implementation

{$REGION 'TSortFactorySingleton'}

constructor TSortFactorySingleton.Create;
begin
  inherited;
end;

class function TSortFactorySingleton.GetInstance: ISortFactorySingleton;
begin
  If FInstance = nil Then
  begin
    FInstance := TSortFactorySingleton.Create;
  end;
  Result := FInstance;
end;

function TSortFactorySingleton.GetReader(const AFileName: string): IFileReader;
begin
  Result := FFileReaderClass.Create as IFileReader;
  Result.Open(AFileName);
end;

function TSortFactorySingleton.GetWriter(const AFileName: string): IFileWriter;
begin
  Result := FFileWriterClass.Create as IFileWriter;
  Result.Open(AFileName);
end;

function TSortFactorySingleton.GetMergerController: IMergeController;
begin
  Result             := FMergeControllerClass.Create([FFileReaderClass, FFileWriterClass]) as IMergeController;
  Result.MergerClass := FMergerClass;
end;

function TSortFactorySingleton.GetMerger(AMergeController: IMergeController; const AFileNames: array of string)
  : IMerger;
begin
  Result                 := FMergerClass.Create([FFileReaderClass, FFileWriterClass]) as IMerger;
  Result.SrcFileReader   := GetReader(FSrcFileName);
  Result.MergeController := AMergeController;
  Result.LeftFileName    := AFileNames[0];
  Result.RightFileName   := AFileNames[1];
  Result.DscFileName     := FDscFileName;
end;

function TSortFactorySingleton.GetSeriesCreator(AMergeController: IMergeController;
  const ABoundaries: array of Int64): IPhase;
var
  L, H  : Int64;
  Reader: IFileReader;
begin
  Result := FSeriesCreatorClass.Create([FFileReaderClass, FFileWriterClass]) as IPhase;

  L := ABoundaries[0];
  H := ABoundaries[1];

  Reader := GetReader(FSrcFileName);
  Reader.SetBoundaries(L, H);
  Result.SrcFileReader := Reader;

  Result.MergeController := AMergeController;
end;

procedure TSortFactorySingleton.SetDscFileName(const Value: string);
begin
  if FDscFileName <> Value then
    if FileExists(Value) then
      raise EExtSortFactory.CreateFmt('Файл ''%s'' уже существует ', [Value]);
  FDscFileName := Value;
end;

procedure TSortFactorySingleton.SetFileReaderClass(const Value: TFileClass);
begin
  if FFileReaderClass <> Value then
    FFileReaderClass := Value;
end;

procedure TSortFactorySingleton.SetFileWriterClass(const Value: TFileClass);
begin
  if FFileWriterClass <> Value then
    FFileWriterClass := Value;
end;

procedure TSortFactorySingleton.SetMergerClass(const Value: TSortClass);
begin
  if FMergerClass <> Value then
    FMergerClass := Value;
end;

procedure TSortFactorySingleton.SetMergeControllerClass(const Value: TSortClass);
begin
  if FMergeControllerClass <> Value then
    FMergeControllerClass := Value;
end;

procedure TSortFactorySingleton.SetSeriesCreatorClass(const Value: TSortClass);
begin
  if FSeriesCreatorClass <> Value then
    FSeriesCreatorClass := Value;
end;

procedure TSortFactorySingleton.SetSrcFileName(const Value: string);
const
  L: Int64 = $40000;         // 100 Kb
  H: Int64 = $1000000000000; // 10 Gb
var
  FFileStream: TFileStream;
begin
  if FSrcFileName <> Value then
    if not FileExists(Value) then
      raise EExtSortFactory.CreateFmt('Файл ''%s'' не существует ', [Value]);
  // Проверка размера файла
  FFileStream := TFileStream.Create(Value, fmOpenRead);
  try

    if (FFileStream.Size < L) or (FFileStream.Size > H) then
      raise EExtSortFactory.Create('Проверьте размер файла ''%s'' [100Kb - 10 Gb] ');
  finally
    FreeAndNil(FFileStream);
  end;

  FSrcFileName := Value;
end;

{$ENDREGION}

end.
