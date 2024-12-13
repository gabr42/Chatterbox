unit CB.UI.Passphrase;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit;

type
  TfrmPassphrase = class(TForm)
    Label1: TLabel;
    inpPassphrase: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
  private
  public
    function Passphrase: string;
  end;

implementation

{$R *.fmx}

{ TfrmPassphrase }

function TfrmPassphrase.Passphrase: string;
begin
  Result := inpPassphrase.Text;
end;

end.
