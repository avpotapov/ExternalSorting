unit SimpleLogger;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils;

type
  TSimpleLogger = class
  private
    FFileHandle     : TextFile;
    FApplicationName: string;
    FApplicationPath: string;
  public
    constructor Create; overload;
    constructor Create(const AFileName: string); overload;
    destructor Destroy; override;
    function GetApplicationName: string;
    function GetApplicationPath: string;
    procedure LogError(ErrorMessage: string; Location: string); virtual;
    procedure LogWarning(WarningMessage: string; Location: string); virtual;
    procedure LogStatus(StatusMessage: string; Location: string); virtual;
    property ApplicationName: string read GetApplicationName;
    property ApplicationPath: string read GetApplicationPath;
  end;

  TThreadSafeLogger = class(TSimpleLogger)
  private
    FCs: TRtlCriticalSection;
  public
    constructor Create(const AFileName: string); reintroduce;
    destructor Destroy; override;
    procedure LogError(ErrorMessage: string; Location: string); override;
    procedure LogWarning(WarningMessage: string; Location: string); override;
    procedure LogStatus(StatusMessage: string; Location: string); override;
  end;

var
  Logger: TSimpleLogger;

implementation

{ TLogger }
constructor TSimpleLogger.Create;
var
  FileName: string;
begin
  FApplicationName := ExtractFileName(ParamStr(0));
  FApplicationPath := ExtractFilePath(ParamStr(0)) + 'Logs\';
  if not DirectoryExists(FApplicationPath) then
    CreateDir(FApplicationPath);
  FileName := FApplicationPath + ChangeFileExt(FApplicationName, '.log');
  AssignFile(FFileHandle, FileName);
  ReWrite(FFileHandle);
end;

constructor TSimpleLogger.Create(const AFileName: string);
var
  FileName: string;
begin
  FApplicationName := ExtractFileName(ParamStr(0));
  FApplicationPath := ExtractFilePath(ParamStr(0)) + 'Logs\';
  if not DirectoryExists(FApplicationPath) then
    CreateDir(FApplicationPath);
  FileName := FApplicationPath + ChangeFileExt(AFileName, '.log');
  AssignFile(FFileHandle, FileName);
  ReWrite(FFileHandle);
end;

destructor TSimpleLogger.Destroy;
begin
  CloseFile(FFileHandle);
  inherited;
end;

function TSimpleLogger.GetApplicationName: string;
begin
  result := FApplicationName;
end;

function TSimpleLogger.GetApplicationPath: string;
begin
  result := FApplicationPath;
end;

procedure TSimpleLogger.LogError(ErrorMessage, Location: string);
var
  S: string;
begin
  S := '!!! ERROR: ' + #9 + FormatDateTime('hh:nn:ss:zzz', Time) + #9 + ' MSG : ' + ErrorMessage + ' IN : ' + Location + #13#10;
  WriteLn(FFileHandle, S);
  Flush(FFileHandle);
end;

procedure TSimpleLogger.LogStatus(StatusMessage, Location: string);
var
  S: string;
begin
  S := '    STATUS: ' + #9 + FormatDateTime('hh:nn:ss:zzz', Time) + #9 + ' MSG : ' + StatusMessage + ' IN : ' + Location + #13#10;
  WriteLn(FFileHandle, S);
  Flush(FFileHandle);
end;

procedure TSimpleLogger.LogWarning(WarningMessage, Location: string);
var
  S: string;
begin
  S := '--- WARNING: ' + #9 + FormatDateTime('hh:nn:ss:zzz', Time) + #9 + ' MSG : ' + WarningMessage + ' IN : ' + Location + #13#10;
  WriteLn(FFileHandle, S);
  Flush(FFileHandle);
end;

{ TThreadSafeLogger }

constructor TThreadSafeLogger.Create(const AFileName: string);
begin
  inherited Create(AFileName);
  InitializeCriticalSection(FCs);
end;

destructor TThreadSafeLogger.Destroy;
begin
  DeleteCriticalSection(FCs);
  inherited;
end;

procedure TThreadSafeLogger.LogError(ErrorMessage, Location: string);
begin
  EnterCriticalSection(FCs);
  try
    inherited LogError(ErrorMessage, Location);
  finally
    LeaveCriticalSection(FCs);
  end;
end;

procedure TThreadSafeLogger.LogStatus(StatusMessage, Location: string);
begin
  EnterCriticalSection(FCs);
  try
    inherited LogStatus(StatusMessage, Location);
  finally
    LeaveCriticalSection(FCs);
  end;

end;

procedure TThreadSafeLogger.LogWarning(WarningMessage, Location: string);
begin
  EnterCriticalSection(FCs);
  try
    inherited LogWarning(WarningMessage, Location);
  finally
    LeaveCriticalSection(FCs);
  end;

end;

initialization

begin
  Logger := TSimpleLogger.Create;
  Logger.LogStatus('Starting Application', 'Initialization');
end;

finalization

begin
  Logger.LogStatus('Terminating Application', 'Finalization');
  FreeAndNil(Logger);
end;

end.
