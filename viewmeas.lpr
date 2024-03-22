program ViewMeas;

{$MODE Delphi}

uses
  Forms, tachartlazaruspkg, Interfaces,
  ViewForm in 'ViewForm.pas' {fViewMeas};

{$R *.res}

begin
    Application.Title:='ViewMeas';
  Application.Initialize;
  Application.CreateForm(TfViewMeas, fViewMeas);
  Application.Run;
end.

