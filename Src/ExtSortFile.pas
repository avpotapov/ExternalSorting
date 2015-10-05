unit ExtSortFile;

interface
{$REGION 'Описание модуля'}
 (*
  *  Модуль доступа к файлам
  *  Созданные объекты позволяют читать и записывать в файл
  *)
{$ENDREGION}

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows;

const
  // Максимальное количество сравниваемых символов
  MAX_SIZE_COMPARE_STRING = 50;
  MAX_STRING_SIZE         = 500;

type
  TFileClass = class of TAbstractFile;

  IFile = interface
    ['{0B9B01C5-1680-4C25-93CA-C07715EF2186}']
    procedure Close;
    procedure Open(const AFileName: string);
  end;
  /// <summary>
  ///   Файл для записи строки
  /// </summary>
  IFileWriter = interface(IFile)
    ['{AD3FE232-AC43-4803-BB68-D15E7AF5468C}']
    procedure WriteString(AString: AnsiString);
    function GetSize: Int64;
    property Size: Int64 read GetSize;

  end;

  /// <summary>
  ///   Файл для чтения строки
  /// </summary>
  IFileReader = interface(IFile)
    ['{C9DCE055-FF56-4BD0-941C-254C35A584ED}']
    /// <summary>
    ///   Определяет четкие границы между строками по приблизительным данным
    /// </summary>
    procedure SetBoundaries(var AStart, AEnd: Int64);
    function ReadString(out AString: AnsiString): Boolean;
    function GetPosition: Int64;
    function GetSize: Int64;

    property Size: Int64 read GetSize;
    property Position: Int64 read GetPosition;
  end;

{$REGION 'TAbstractFile'}

  TAbstractFile = class abstract(TInterfacedObject, IFile)
    procedure Open(const AFileName: string); virtual; abstract;
    procedure Close; virtual; abstract;
  public
    destructor Destroy; override;
  end;
{$ENDREGION}
{$REGION 'TFileReader'}

  TFileReader = class(TAbstractFile, IFileReader)
    FFileStream: TFileStream;
    FReader: TStreamReader;
    FCurrentPosition: Int64;
    FEndPosition: Int64;
    procedure ReturnExactBoundaryLine(var ABoundary: Int64);
    function GetPosition: Int64;
  public

    procedure Open(const AFileName: string); override;
    procedure Close; override;
    procedure SetBoundaries(var AStart, AEnd: Int64);
    function GetSize: Int64;
    function ReadString(out AString: AnsiString): Boolean;
  end;
{$ENDREGION}
{$REGION 'TFileWriter'}

  TFileWriter = class(TAbstractFile, IFileWriter)
    FWriter: TStreamWriter;
  public
    procedure Open(const AFileName: string); override;
    procedure Close; override;
    procedure WriteString(AString: AnsiString);
    function GetSize: Int64;
    class function MakeRandomFileName: string;
  end;
{$ENDREGION}

implementation

{$REGION 'TAbstractFile'}

destructor TAbstractFile.Destroy;
begin
  Close;
  inherited;
end;

{$ENDREGION}
{$REGION 'TFileReader'}

function TFileReader.GetPosition: Int64;
begin
  Result := FCurrentPosition;
end;

function TFileReader.GetSize: Int64;
begin
  Result := FFileStream.Size;
end;

procedure TFileReader.Open(const AFileName: string);
begin
  FFileStream      := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  FReader          := TStreamReader.Create(FFileStream, TEncoding.ANSI);
  FCurrentPosition := 0;
  FEndPosition     := FFileStream.Size;
end;

procedure TFileReader.Close;
begin
  FreeAndnil(FReader);
  FreeAndnil(FFileStream);
end;

function TFileReader.ReadString(out AString: AnsiString): Boolean;
begin
  if FCurrentPosition >= FEndPosition then
  begin
    AString := '';
    Exit(False);
  end;
  AString := AnsiString(FReader.ReadLine);
  Result  := AString <> '';
  if Result then
    Inc(FCurrentPosition, Length(AString) + 2);
end;

procedure TFileReader.ReturnExactBoundaryLine(var ABoundary: Int64);
var
  Buffer   : TStringBuilder;
  BytesRead: Integer;

  S: AnsiString;
  I: Integer;
begin
  Buffer := TStringBuilder.Create;
  try
    // Загрузить данные в буфер с текущей позиции, чтобы определить границу строки
    // Пусть размер будет 0x200
    SetLength(S, $200);
    // Позиция в примерную границу строки
    FFileStream.Position := ABoundary;
    // Количество прочитанных байт
    BytesRead := FFileStream.Read(S[1], $200);
    if BytesRead = 0 then
      Exit;

    // Загружаем строку в буфер
    Buffer.Append(S);
    // Ищем символы #13#10 конца строки
    I := 0;
    while I < Buffer.Length do
    begin
      if (Buffer.Chars[I] = #13) and (Buffer.Chars[I + 1] = #10) then
      begin
        // Начало следующей строки
        ABoundary := ABoundary + I + 2;
        Break;
      end;
      Inc(I);
    end;
  finally
    FreeAndnil(Buffer);
  end;
end;

procedure TFileReader.SetBoundaries(var AStart, AEnd: Int64);
begin
  FCurrentPosition := AStart;
  if FCurrentPosition > 0 then
    ReturnExactBoundaryLine(FCurrentPosition);
  FEndPosition := AEnd;
  if FEndPosition < FFileStream.Size then
  begin
    ReturnExactBoundaryLine(FEndPosition);
    Dec(FEndPosition);
  end;

  FFileStream.Position := FCurrentPosition;

  AStart := FCurrentPosition;
  AEnd   := FEndPosition;
end;

{$ENDREGION}
{$REGION 'TFileWriter'}

procedure TFileWriter.Close;
begin
  FreeAndnil(FWriter);
end;

function TFileWriter.GetSize: Int64;
begin
  Result := FWriter.BaseStream.Size;
end;

class function TFileWriter.MakeRandomFileName: string;
var
  Guid     : TGuid;
  StartChar: Integer;
  EndChar  : Integer;
  Count    : Integer;
begin
  CreateGuid(Guid);
  Result := GuidToString(Guid);

  StartChar := Pos('{', Result) + 1;
  EndChar   := Pos('}', Result) - 1;
  Count     := EndChar - StartChar + 1;

  Result := Copy(Result, StartChar, Count);
  Result := Result + '.temp';
end;

procedure TFileWriter.Open(const AFileName: string);
begin
  FWriter := TStreamWriter.Create(AFileName, False, TEncoding.ANSI);
end;

procedure TFileWriter.WriteString(AString: AnsiString);
begin
  FWriter.Write(String(AString));
  FWriter.WriteLine;
end;

{$ENDREGION}

end.
