program ROStatus;

uses
  Vcl.Forms,
  UFrm in 'UFrm.pas' {Frm},
  UProcFunc in 'UProcFunc.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrm, Frm);
  Application.Run;
end.
