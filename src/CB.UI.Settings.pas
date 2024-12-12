unit CB.UI.Settings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Actions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListBox,
  FMX.Layouts, FMX.TabControl, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.ActnList, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  Spring.Collections,
  CB.Settings, FMX.EditBox, FMX.NumberBox;

type
  TS = class(TForm)
    ListBox1: TListBox;
    liAIEngines: TListBoxItem;
    liSecurity: TListBoxItem;
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
    tcAIEngineSettings: TTabControl;
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
    lblLoadedEngine: TLabel;
    tiEngineOllama: TTabItem;
    Label8: TLabel;
    inpHost: TEdit;
    cbDefault: TCheckBox;
    inpSystemPrompt: TMemo;
    Label6: TLabel;
    tcEngineAnthropic: TTabItem;
    btnResetEngine: TButton;
    actResetSettings: TAction;
    tiEngineGemini: TTabItem;
    Label7: TLabel;
    inpMaxTokens: TNumberBox;
    Label9: TLabel;
    Label10: TLabel;
    Edit1: TEdit;
    Label11: TLabel;
    Edit2: TEdit;
    Label12: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure actDeleteAIEngineExecute(Sender: TObject);
    procedure actDeleteAIEngineUpdate(Sender: TObject);
    procedure actResetSettingsExecute(Sender: TObject);
    procedure actResetSettingsUpdate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbDefaultChange(Sender: TObject);
    procedure inpCommonAIChange(Sender: TObject);
    procedure lbAIEnginesClick(Sender: TObject);
    procedure liAIEnginesClick(Sender: TObject);
    procedure liSecurityClick(Sender: TObject);
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
  S: TS;

implementation

{$R *.fmx}

procedure TS.FormCreate(Sender: TObject);
begin
  tcSettings.TabIndex := 0;
  lyCommonAIEngineSettings.Enabled := false;
end;

procedure TS.actDeleteAIEngineExecute(Sender: TObject);
begin
  FEngines.ExtractAt(lbAIEngines.ItemIndex);
  lbAIEngines.Items.Delete(lbAIEngines.ItemIndex);
  MakeDefault;
  lbAIEngines.OnClick(lbAIEngines);
end;

procedure TS.actDeleteAIEngineUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lbAIEngines.ItemIndex >= 0;
end;

procedure TS.actResetSettingsExecute(Sender: TObject);
begin
  var stg := FEngines[lbAIEngines.ItemIndex];
  FUpdate := true;
  case stg.EngineType of
    etAnthropic:
      begin
        inpHost.Text := 'https://api.anthropic.com/v1/messages';
        inpModel.Text := 'claude-3-5-sonnet-latest';
        inpMaxTokens.Value := 2048;
      end;
    etOllama:
      begin
        inpHost.Text := 'http://localhost:11434/api/chat';
        inpModel.Text := 'codellama';
        inpMaxTokens.Value := 2048;
      end;
    etOpenAI:
      begin
        inpHost.Text := 'https://api.openai.com/v1/chat/completions';
        inpModel.Text := 'o1-mini';
        inpMaxTokens.Value := 2048;
      end;
    etGemini:
      begin
        inpHost.Text := 'https://generativelanguage.googleapis.com/v1beta/';
        inpModel.Text := 'gemini-1.5-pro';
        inpMaxTokens.Value := 2048;
      end
    else
      inpHost.Text := '';
  end;
  FUpdate := false;
  inpCommonAIChange(nil);
end;

procedure TS.actResetSettingsUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lyCommonAIEngineSettings.Enabled
                                 and (cbxEngineType.ItemIndex >= 0);
end;

procedure TS.AfterConstruction;
begin
  inherited;
  FEngines := TCollections.CreateList<TCBAIEngineSettings>;
end;

procedure TS.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TS.cbDefaultChange(Sender: TObject);
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

procedure TS.inpCommonAIChange(Sender: TObject);
begin
  if FUpdate or (lbAIEngines.ItemIndex < 0) then
    Exit;

  var stg := FEngines[lbAIEngines.ItemIndex];
  stg.IsDefault := cbDefault.IsChecked;
  case cbxEngineType.ItemIndex of
    0:   stg.EngineType := etAnthropic;
    1:   stg.EngineType := etGemini;
    2:   stg.EngineType := etOllama;
    3:   stg.EngineType := etOpenAI;
    else stg.EngineType := etNone;
  end;
  stg.Model := inpModel.Text;
  stg.Name := inpName.Text;
  stg.Authorization := inpAuth.Text;
  stg.Host := inpHost.Text;
  stg.SysPrompt := StringReplace(StringReplace(inpSystemPrompt.Text, #$0D, ' ', [rfReplaceAll]), #$0A, ' ', [rfReplaceAll]);
  stg.MaxTokens := Round(inpMaxTokens.Value);
  FEngines[lbAIEngines.ItemIndex] := stg;

  lbAIEngines.Items[lbAIEngines.ItemIndex] := stg.DisplayName;
  lblLoadedEngine.Text := stg.DisplayName(false);
  tcAIEngineSettings.TabIndex := Ord(stg.EngineType);
end;

procedure TS.lbAIEnginesClick(Sender: TObject);
begin
  if lbAIEngines.ItemIndex < 0 then begin
    lyCommonAIEngineSettings.Enabled := false;
    lblLoadedEngine.Text := '';
    Exit;
  end;

  FUpdate := true;
  lyCommonAIEngineSettings.Enabled := true;
  var stg := FEngines[lbAIEngines.ItemIndex];
  cbDefault.IsChecked := stg.IsDefault;
  case stg.EngineType of
    etAnthropic: cbxEngineType.ItemIndex := 0;
    etGemini:    cbxEngineType.ItemIndex := 1;
    etOllama:    cbxEngineType.ItemIndex := 2;
    etOpenAI:    cbxEngineType.ItemIndex := 3;
    else         cbxEngineType.ItemIndex := -1;
  end;
  inpModel.Text := stg.Model;
  inpName.Text := stg.Name;
  inpAuth.Text := stg.Authorization;
  inpSystemPrompt.Text := stg.SysPrompt;
  inpHost.Text := stg.Host;
  inpMaxTokens.Value := stg.MaxTokens;
  FUpdate := false;

  lblLoadedEngine.Text := stg.DisplayName(false);
  tcAIEngineSettings.TabIndex := Ord(stg.EngineType);
end;

procedure TS.liAIEnginesClick(Sender: TObject);
begin
  tcSettings.TabIndex := 0;
end;

procedure TS.liSecurityClick(Sender: TObject);
begin
  tcSettings.TabIndex := 1;
end;

procedure TS.LoadFromSettings(settings: TCBSettings);
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

procedure TS.MakeDefault;
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

procedure TS.SaveToSettings(settings: TCBSettings);
begin
  settings.AIEngines.Clear;
  settings.AIEngines.AddRange(FEngines);
end;

procedure TS.sbAddEngineClick(Sender: TObject);
begin
  var stg := Default(TCBAIEngineSettings);
  if FEngines.Count = 0 then
    stg.IsDefault := true;
  stg.MaxTokens := 2048;
  var li := TListBoxItem.Create(Self);
  li.Parent := lbAIEngines;
  li.Text := stg.DisplayName;
  lbAIEngines.ItemIndex := FEngines.Add(stg);
  lbAIEnginesClick(lbAIEngines);
end;

end.
