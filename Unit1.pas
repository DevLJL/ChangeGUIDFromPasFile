unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.FileCtrl,
  Vcl.WinXCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ActivityIndicator1: TActivityIndicator;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure ProcessDirectory(const Directory: string);
    function NextGUID: String;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  lFolderDialog: TFileOpenDialog;
begin
  Button1.Enabled            := False;
  ActivityIndicator1.Animate := True;
  lFolderDialog              := TFileOpenDialog.Create(nil);
  try
    lFolderDialog.Options := [fdoPickFolders];
    if not lFolderDialog.Execute then
      Exit;

    try
      ProcessDirectory(lFolderDialog.FileName);
    except on E: Exception do
      Begin
        ShowMessage(E.Message);
        Raise;
      End;
    end;
    ShowMessage('Processo realizado!');

  finally
    Button1.Enabled            := True;
    ActivityIndicator1.Animate := False;
    lFolderDialog.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;
end;

function TForm1.NextGUID: String;
const
  L_CHARS_TO_REMOVE: TArray<String> = ['[',']','{','}'];
var
  lI: Integer;
begin
  Result := TGUID.NewGuid.ToString;
  for lI := 0 to High(L_CHARS_TO_REMOVE) do
    Result := StringReplace(Result, L_CHARS_TO_REMOVE[lI], '', [rfReplaceAll]);
end;

procedure TForm1.ProcessDirectory(const Directory: string);
const
  L_EXTENSION = '.pas';
  L_GUID_PREFIX = '[''{';
  L_GUID_SUFIX = '}'']';
var
  SearchRec: TSearchRec;
  FilePath: string;
  lI: Integer;
  lStrList: TStringList;
  lHasGUID: Boolean;
  lExtractGUID: String;
  lNewGUID: String;
begin
  try
    lStrList := TStringList.Create;

    // Finalizar se não existir arquivos
    if not (FindFirst(Directory + '\*.*', faAnyFile, SearchRec) = 0) then
    begin
      FindClose(SearchRec);
      Exit;
    end;

    while (FindNext(SearchRec) = 0) do
    begin
      Application.ProcessMessages;

      // ignora as pastas . e ..
      if not ((SearchRec.Name <> '.') and (SearchRec.Name <> '..')) then
        Continue;

      // Se o arquivo for uma pasta, processa a subpasta
      FilePath := Directory + '\' + SearchRec.Name;
      if (SearchRec.Attr and faDirectory) = faDirectory then
      begin
        ProcessDirectory(FilePath);
        Continue;
      end;

      // Verificar a extensão
      if not SameText(ExtractFileExt(SearchRec.Name), L_EXTENSION) then
        Continue;

      // Alterar GUID do arquivo se existir
      lStrList.Clear;
      lStrList.LoadFromFile(FilePath);
      for lI := 0 to Pred(lStrList.Count) do
      begin
        Application.ProcessMessages;
        lHasGUID := (Pos(L_GUID_PREFIX, lStrList[lI]) > 0) and
                    (Pos(L_GUID_SUFIX, lStrList[lI]) > 0) and
                    ((Pos(L_GUID_SUFIX, lStrList[lI]) - Pos(L_GUID_PREFIX, lStrList[lI])) = 39);
        if lHasGUID then
        begin
          lExtractGUID := Copy(lStrList[lI], Pos(L_GUID_PREFIX, lStrList[lI])+3, 36);
          lStrList[lI] := StringReplace(lStrList[lI], lExtractGUID, NextGUID, [rfReplaceAll]);
        end;
      end;

      // salva o conteúdo do objeto TStringList de volta no arquivo
      lStrList.SaveToFile(FilePath);
    end;
  finally
    lStrList.Free;
  end;
end;

end.
