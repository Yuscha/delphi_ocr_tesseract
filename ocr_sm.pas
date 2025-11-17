unit OCR_DM;

interface

uses
  System.SysUtils, System.Classes,Winapi.Windows, Winapi.ShellAPI;

type
  TfOCR_DM = class(TDataModule)
  private
    { Private-Deklarationen }
    function RunProcessAndCheckSuccess(const ExeFile, Params: string; Wait: Boolean = True; TimeoutMs: DWORD = INFINITE): Boolean;

  public
    { Public-Deklarationen }
    function ConvertPDFToTIFF(const PDFFile: string; const OutputDir: string): TArray<string>;

    function DateiOCR(Datei:string):string; overload;
    function DateiOCR(Datei,AusgabeDatei:string):boolean; overload;
  end;

var
  fOCR_DM: TfOCR_DM;

implementation

function TfOCR_DM.ConvertPDFToTIFF(const PDFFile: string; const OutputDir: string): TArray<string>;
var
  GSPath, OutputFileBase, Cmd, OutputFile: string;
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Ret: BOOL;
  FileList: TStringList;
  SR: TSearchRec;
begin
  // Pfad zur Ghostscript-EXE anpassen
  GSPath := '"'+extractfilepath(paramstr(0))+'\GhostScript\bin\gswin64c.exe"';

  // Basisname für Ausgabedateien
  OutputFileBase := IncludeTrailingPathDelimiter(OutputDir) + ChangeFileExt(ExtractFileName(PDFFile), '');

  // Ghostscript-Befehl
  Cmd := Format('%s -dNOPAUSE -dBATCH -sDEVICE=tiff24nc -r300 ' +
                '-sOutputFile="%s_%%03d.tif" "%s"',
                [GSPath, OutputFileBase, PDFFile]);

  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  StartInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartInfo.wShowWindow := SW_HIDE;

  Ret := CreateProcess(nil, PChar(Cmd), nil, nil, False, 0, nil, nil, StartInfo, ProcInfo);
  if Ret then
  begin
    WaitForSingleObject(ProcInfo.hProcess, INFINITE);
    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
  end
  else
    raise Exception.Create('Ghostscript konnte nicht gestartet werden.');

  // Liste der erzeugten TIFF-Dateien sammeln
  FileList := TStringList.Create;
  try
    if FindFirst(OutputFileBase + '_*.tif', faAnyFile, SR) = 0 then
    repeat
      FileList.Add(OutputDir + '\' + SR.Name);
    until FindNext(SR) <> 0;
    System.SysUtils.FindClose(SR);

    Result := FileList.ToStringArray;
  finally
    FileList.Free;
  end;
end;

function TfOCR_DM.RunProcessAndCheckSuccess(const ExeFile, Params: string; Wait: Boolean = True; TimeoutMs: DWORD = INFINITE): Boolean;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CommandLine: string;
  ExitCode: DWORD;
  WaitResult: DWORD;
begin
  Result := False;
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  FillChar(ProcInfo, SizeOf(ProcInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  StartInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartInfo.wShowWindow := SW_HIDE; // oder SW_SHOWNORMAL, wenn Fenster sichtbar sein soll

  // CommandLine muss veränderlich sein (PChar kann sie intern modifizieren)
  CommandLine := '"' + ExeFile + '" ' + Params;

  if not CreateProcess(nil, PChar(CommandLine), nil, nil, False, 0, nil, nil, StartInfo, ProcInfo) then
    raise Exception.CreateFmt('Fehler beim Starten von "%s". (Code %d)', [ExeFile, GetLastError]);

  try
    if Wait then
    begin
      WaitResult := WaitForSingleObject(ProcInfo.hProcess, TimeoutMs);
      case WaitResult of
        WAIT_OBJECT_0:
          begin
            if GetExitCodeProcess(ProcInfo.hProcess, ExitCode) then
              Result := (ExitCode = 0) // Erfolg, wenn ExitCode == 0
            else
              raise Exception.Create('Fehler beim Ermitteln des ExitCodes: ' + SysErrorMessage(GetLastError));
          end;
        WAIT_TIMEOUT:
          raise Exception.Create('Timeout: Prozess hat zu lange gebraucht.');
      else
        raise Exception.Create('Fehler beim Warten auf den Prozess: ' + SysErrorMessage(GetLastError));
      end;
    end
    else
      Result := True; // Prozess erfolgreich gestartet (aber nicht auf Exit gewartet)
  finally
    if ProcInfo.hProcess <> 0 then CloseHandle(ProcInfo.hProcess);
    if ProcInfo.hThread <> 0 then CloseHandle(ProcInfo.hThread);
  end;
end;

function TfOCR_DM.DateiOCR(Datei:string):string;
// datei ORC erkennung durchführen und zurückmelden
var
  FileName,Parameters:string;
  ergebnis:TSTringlist;

  TextDateiPfad:string;
  Rueckgabe:integer;
begin
  ergebnis:=TStringList.Create;
  ergebnis.Clear;

  // shell aufruf
  TextDateiPfad := 'ausgabe';

  FileName := extractfilepath(paramstr(0))+'\Tesseract-OCR\tesseract.exe';     // oder Pfad zu einer Datei
  Parameters := '"'+datei+'" "'+TextDateiPfad+'" -l deu txt';  // optional


  try
    // aufruf ausführen
    if RunProcessAndCheckSuccess(FileName, Parameters) then
    begin
      // aufruf ohne Fehler
      ergebnis.LoadFromFile(TextDateiPfad+'.txt',tencoding.UTF8);

      // nach erfolgreichen Laden TXT löschen
      DeleteFile(PChar(TextDateiPfad+'.txt'));
    end
    else
    begin
      // aufruf mit Fehler
      ergebnis.Add('Fehler');
    end;
  except
    on E: Exception do
      ergebnis.Add('Fehler: ' + E.Message);
  end;

  // Text zurück geben
  result:=ergebnis.Text;
  ergebnis.Free;
end;

function TfOCR_DM.DateiOCR(Datei,AusgabeDatei:string):boolean;
var
  FileName,Parameters:string;
  Rueckgabe:integer;

begin
  FileName := extractfilepath(paramstr(0))+'\Tesseract-OCR\tesseract.exe';     // oder Pfad zu einer Datei
  Parameters := '"'+datei+'" "'+AusgabeDatei+'" -l deu txt';  // optional

  try
    if RunProcessAndCheckSuccess(FileName, Parameters) then
      result:=true
    else
      result:=false;
  except
    result:=false;
  end;

end;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
