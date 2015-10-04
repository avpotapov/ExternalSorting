unit ExtSortFile;

interface

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows;

const
  // ������������ ���������� ������������ ��������
  MAX_SIZE_COMPARE_STRING = 50;
  MAX_STRING_SIZE         = 500;

type

  IFile = interface
    ['{0B9B01C5-1680-4C25-93CA-C07715EF2186}']
    procedure Close;
    procedure Open(const AFileName: string);
  end;

  IFileWriter = interface(IFile)
    ['{AD3FE232-AC43-4803-BB68-D15E7AF5468C}']
    procedure WriteString(AString: AnsiString);
    function GetSize: Int64;
    property Size: Int64 read GetSize;

  end;

  IFileReader = interface(IFile)
    ['{C9DCE055-FF56-4BD0-941C-254C35A584ED}']
    procedure SetBoundaries(var AStart, AEnd: Int64);
    function ReadString(out AString: AnsiString): Boolean;
    function GetPosition: Int64;
    function GetSize: Int64;

    property Size: Int64 read GetSize;
    property Position: Int64 read GetPosition;
  end;

  TFileClass = class of TTextFile;

  TTextFile = class(TInterfacedObject, IFile)
    procedure Open(const AFileName: string); virtual; abstract;
    procedure Close; virtual; abstract;
  public
    destructor Destroy; override;
  end;

  TFileReader = class(TTextFile, IFileReader)
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

  TFileWriter = class(TTextFile, IFileWriter)
    FWriter: TStreamWriter;
  public
    procedure Open(const AFileName: string); override;
    procedure Close; override;
    procedure WriteString(AString: AnsiString);
    function GetSize: Int64;
    class function MakeRandomFileName: string;
  end;

implementation

{ TTextFile }

destructor TTextFile.Destroy;
begin
  Close;
  inherited;
end;

{ TTextFile }

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
  FFileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  FReader     := TStreamReader.Create(FFileStream, TEncoding.ANSI);
  FCurrentPosition := 0;
  FEndPosition := FFileStream.Size;
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
    // ��������� ������ � ����� � ������� �������, ����� ���������� ������� ������
    // ����� ������ ����� 0x200
    SetLength(S, $200);
    // ������� � ��������� ������� ������
    FFileStream.Position := ABoundary;
    // ���������� ����������� ����
    BytesRead := FFileStream.Read(S[1], $200);
    if BytesRead = 0 then
      Exit;

    // ��������� ������ � �����
    Buffer.Append(S);
    // ���� ������� #13#10 ����� ������
    I := 0;
    while I < Buffer.Length do
    begin
      if (Buffer.Chars[I] = #13) and (Buffer.Chars[I + 1] = #10) then
      begin
        // ������ ��������� ������
        ABoundary := ABoundary + I + 2;
        Break;
      end;
      Inc(I);
    end;
  finally
    FreeAndNil(Buffer);
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
  AEnd := FEndPosition;
end;

{ TFileWriter }

procedure TFileWriter.Close;
begin
  FreeAndNil(FWriter);
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

end.