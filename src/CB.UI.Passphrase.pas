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
    procedure FormCreate(Sender: TObject);
  private
  public
    function Passphrase: string;
  end;

implementation

{$R *.fmx}

procedure TfrmPassphrase.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;
end;

{ TfrmPassphrase }

function TfrmPassphrase.Passphrase: string;
begin
  Result := inpPassphrase.Text;
end;

end.
