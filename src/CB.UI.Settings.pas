unit CB.UI.Settings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListBox,
  FMX.Layouts, FMX.TabControl, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  Spring.Collections,
  CB.Settings, System.Actions, FMX.ActnList;

type
  TfrmSettings = class(TForm)
    ListBox1: TListBox;
    liAIEngines: TListBoxItem;
    liGlobalSettings: TListBoxItem;
    tcSettings: TTabControl;
    tabAIEngines: TTabItem;
    tabGlobalSettings: TTabItem;
    Layout1: TLayout;
    Label1: TLabel;
    Layout2: TLayout;
    sbAddEngine: TSpeedButton;
    btnRemoveEngine: TSpeedButton;
    lbAIEngines: TListBox;
    Button1: TButton;
    Button2: TButton;
    tcEngineTypes: TTabControl;
    tiEngineEmpty: TTabItem;
    tiEngineOpenAI: TTabItem;
    lyCommonAIEngineSettings: TLayout;
    cbxEngineType: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    inpModel: TEdit;
    inpName: TEdit;
    S: TToolBar;
    btnOK: TButton;
    Button4: TButton;
    ActionList1: TActionList;
    actDeleteAIEngine: TAction;
    Label5: TLabel;
    inpAuth: TEdit;
    cbDefault: TCheckBox;
    lblLoadedEngine: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure actDeleteAIEngineExecute(Sender: TObject);
    procedure actDeleteAIEngineUpdate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbDefaultChange(Sender: TObject);
    procedure inpCommonAIChange(Sender: TObject);
    procedure lbAIEnginesClick(Sender: TObject);
    procedure liAIEnginesClick(Sender: TObject);
    procedure liGlobalSettingsClick(Sender: TObject);
    procedure sbAddEngineClick(Sender: TObject);
  private
    FEngines: IList<TCBAIEngineSettings>;
    FUpdate : boolean;
    procedure MakeDefault;
  public
    procedure AfterConstruction; override;
    procedure LoadFromSettings(settings: TCBSettings);
    procedure SaveToSettings(settings: TCBSettings);
  end;

var
  frmSettings: TfrmSettings;

implementation

{$R *.fmx}

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  lyCommonAIEngineSettings.Enabled := false;
end;

procedure TfrmSettings.actDeleteAIEngineExecute(Sender: TObject);
begin
  FEngines.ExtractAt(lbAIEngines.ItemIndex);
  lbAIEngines.Items.Delete(lbAIEngines.ItemIndex);
  MakeDefault;
end;

procedure TfrmSettings.actDeleteAIEngineUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lbAIEngines.ItemIndex >= 0;
end;

procedure TfrmSettings.AfterConstruction;
begin
  inherited;
  FEngines := TCollections.CreateList<TCBAIEngineSettings>;
end;

procedure TfrmSettings.btnOKClick(Sender: TObject);
begin
//  inpCommonAIChange(nil);
  ModalResult := mrOK;
end;

procedure TfrmSettings.cbDefaultChange(Sender: TObject);
begin
  inpCommonAIChange(Sender);

  if cbDefault.IsChecked then
    for var iEngine := 0 to FEngines.Count - 1 do
      if iEngine <> lbAIEngines.ItemIndex then begin
        var stg := FEngines[iEngine];
        stg.IsDefault := false;
        FEngines[iEngine] := stg;
        lbAIEngines.Items[iEngine] := stg.DisplayName;
      end;
end;

procedure TfrmSettings.inpCommonAIChange(Sender: TObject);
begin
  if FUpdate or (lbAIEngines.ItemIndex < 0) then
    Exit;

  var stg := FEngines[lbAIEngines.ItemIndex];
  case cbxEngineType.ItemIndex of
    0:   stg.EngineType := etOpenAI;
    else stg.EngineType := etNone;
  end;
  stg.Model := inpModel.Text;
  stg.Name := inpName.Text;
  stg.Authorization := inpAuth.Text;
  stg.IsDefault := cbDefault.IsChecked;
  FEngines[lbAIEngines.ItemIndex] := stg;

  lbAIEngines.Items[lbAIEngines.ItemIndex] := stg.DisplayName;
  lblLoadedEngine.Text := stg.DisplayName(false);
end;

procedure TfrmSettings.lbAIEnginesClick(Sender: TObject);
begin
  if lbAIEngines.ItemIndex < 0 then begin
    lyCommonAIEngineSettings.Enabled := false;
    lblLoadedEngine.Text := '';
    Exit;
  end;

  FUpdate := true;
  lyCommonAIEngineSettings.Enabled := true;
  var stg := FEngines[lbAIEngines.ItemIndex];
  case stg.EngineType of
    etOpenAI: cbxEngineType.ItemIndex := 0;
    else      cbxEngineType.ItemIndex := -1;
  end;
  inpModel.Text := stg.Model;
  inpName.Text := stg.Name;
  inpAuth.Text := stg.Authorization;
  cbDefault.IsChecked := stg.IsDefault;
  FUpdate := false;

  lblLoadedEngine.Text := stg.DisplayName(false);
end;

procedure TfrmSettings.liAIEnginesClick(Sender: TObject);
begin
  tcSettings.TabIndex := 0;
end;

procedure TfrmSettings.liGlobalSettingsClick(Sender: TObject);
begin
  tcSettings.TabIndex := 1;
end;

procedure TfrmSettings.LoadFromSettings(settings: TCBSettings);
begin
  FEngines.Clear;
  FEngines.AddRange(settings.AIEngines);
  for var eng in FEngines do begin
    var li := TListBoxItem.Create(Self);
    li.Parent := lbAIEngines;
    li.Text := eng.DisplayName;
  end;
  MakeDefault;
end;

procedure TfrmSettings.MakeDefault;
begin
  if FEngines.IsEmpty then
    Exit;

  for var stg in FEngines do
    if stg.IsDefault then
      Exit;

  var stg := FEngines[0];
  stg.IsDefault := true;
  FEngines[0] := stg;
  lbAIEngines.Items[0] := FEngines[0].DisplayName;
end;

procedure TfrmSettings.SaveToSettings(settings: TCBSettings);
begin
  settings.AIEngines.Clear;
  settings.AIEngines.AddRange(FEngines);
end;

procedure TfrmSettings.sbAddEngineClick(Sender: TObject);
begin
  var stg := Default(TCBAIEngineSettings);
  if FEngines.Count = 0 then
    stg.IsDefault := true;
  var li := TListBoxItem.Create(Self);
  li.Parent := lbAIEngines;
  li.Text := stg.DisplayName;
  lbAIEngines.ItemIndex := FEngines.Add(stg);
  lbAIEnginesClick(lbAIEngines);
end;

end.
