unit engineDemo.SelectModelDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmSelectModel = class(TForm)
    lbModels: TListBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure lbModelsDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TfrmSelectModel.lbModelsDblClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

end.
