unit UFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdAuthentication,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Vcl.ExtCtrls, Data.DB, Data.Win.ADODB;

type
  TFrm = class(TForm)
    Label1: TLabel;
    conn: TADOConnection;
    tmrObrada: TTimer;
    HTTP: TIdHTTP;
    SSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    btnTransfer: TButton;
    qryROStatus: TADOQuery;
    qryTmp: TADOQuery;
    qryROStatusHOTELID: TIntegerField;
    qryROStatusID: TIntegerField;
    qryROStatusSTATUS: TIntegerField;
    qryROStatusSTATUS_SINK: TIntegerField;
    procedure FormDblClick(Sender: TObject);
    procedure tmrObradaTimer(Sender: TObject);
    procedure btnTransferClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Frm: TFrm;

  v_adresa       : String;
  v_logovi       : String;


implementation

{$R *.dfm}

uses UProcFunc;

procedure TFrm.btnTransferClick(Sender: TObject);
begin
  tmrObradaTimer(Sender);
end;

procedure TFrm.FormCreate(Sender: TObject);
begin
  v_adresa := ExtractFilePath(ParamStr(0));

  if not DirectoryExists(v_adresa + 'logovi') then
  begin
    try
      {$IOChecks off}
      MkDir(v_adresa + 'logovi');

      if IOResult<>0 then
        v_logovi := ''
      else
        v_logovi := 'logovi\';
    finally
      {$IOChecks on}
    end;
  end
  else
    v_logovi := 'logovi\';

  p_IspisLog('***** PROGRAM POKRENUT *****');

  if not f_Baza('oracle', conn) then
    Application.Terminate;
end;

procedure TFrm.FormDblClick(Sender: TObject);
begin
  btnTransfer.Visible := not btnTransfer.Visible;
end;

procedure TFrm.tmrObradaTimer(Sender: TObject);
begin
  p_Transfer;
end;

end.
