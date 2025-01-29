unit CB.UI.Settings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Actions,
  FMX.Platform, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListBox,
  FMX.Layouts, FMX.TabControl, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.ActnList, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.EditBox, FMX.NumberBox,
  Spring.Collections,
  CB.Utils, CB.Settings;

type
  TfrmSettings = class(TForm)
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
    tbSettings: TToolBar;
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
    inpPassphrase: TEdit;
    Label11: TLabel;
    inpPassphraseCheck: TEdit;
    Label12: TLabel;
    actOK: TAction;
    btnGetAPIKey: TButton;
    actGetAPIKey: TAction;
    procedure FormCreate(Sender: TObject);
    procedure actDeleteAIEngineExecute(Sender: TObject);
    procedure actDeleteAIEngineUpdate(Sender: TObject);
    procedure actGetAPIKeyExecute(Sender: TObject);
    procedure actGetAPIKeyUpdate(Sender: TObject);
    procedure actOKExecute(Sender: TObject);
    procedure actOKUpdate(Sender: TObject);
    procedure actResetSettingsExecute(Sender: TObject);
    procedure actResetSettingsUpdate(Sender: TObject);
    procedure cbDefaultChange(Sender: TObject);
    procedure inpCommonAIChange(Sender: TObject);
    procedure lbAIEnginesClick(Sender: TObject);
    procedure liAIEnginesClick(Sender: TObject);
    procedure liSecurityClick(Sender: TObject);
    procedure PassPhraseChange(Sender: TObject);
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

implementation

{$R *.fmx}

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  tcSettings.TabIndex := 0;
  lyCommonAIEngineSettings.Enabled := false;
end;

procedure TfrmSettings.actDeleteAIEngineExecute(Sender: TObject);
begin
  FEngines.ExtractAt(lbAIEngines.ItemIndex);
  lbAIEngines.Items.Delete(lbAIEngines.ItemIndex);
  MakeDefault;
  lbAIEngines.OnClick(lbAIEngines);
end;

procedure TfrmSettings.actDeleteAIEngineUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lbAIEngines.ItemIndex >= 0;
end;

procedure TfrmSettings.actGetAPIKeyExecute(Sender: TObject);
begin
  case FEngines[lbAIEngines.ItemIndex].EngineType of
    etOpenAI:    OpenURL('https://platform.openai.com/api-keys');
    etAnthropic: OpenURL('https://console.anthropic.com/settings/keys');
    etGemini:    OpenURL('https://aistudio.google.com/app/apikey');
    etDeepSeek:  OpenURL('https://platform.deepseek.com/api_keys');
  end;
end;

procedure TfrmSettings.actGetAPIKeyUpdate(Sender: TObject);
begin
  if lbAIEngines.ItemIndex < 0 then
    (Sender as TAction).Enabled := false
  else begin
    var stg := FEngines[lbAIEngines.ItemIndex];
    (Sender as TAction).Enabled := (stg.EngineType in [etOpenAI, etAnthropic, etGemini, etDeepSeek]);
  end;
end;

procedure TfrmSettings.actOKExecute(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TfrmSettings.actOKUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := (inpPassphrase.Text = inpPassphraseCheck.Text);
end;

procedure TfrmSettings.actResetSettingsExecute(Sender: TObject);
begin
  var stg := FEngines[lbAIEngines.ItemIndex];
  FUpdate := true;
  case stg.EngineType of
    etAnthropic:
      begin
        inpHost.Text := 'https://api.anthropic.com/v1/messages';
        inpModel.Text := 'claude-3-5-sonnet-latest';
        inpMaxTokens.Value := 4096;
      end;
    etOllama:
      begin
        inpHost.Text := 'http://localhost:11434/api/chat';
        inpModel.Text := 'codellama';
        inpMaxTokens.Value := 4096;
      end;
    etOpenAI:
      begin
        inpHost.Text := 'https://api.openai.com/v1/chat/completions';
        inpModel.Text := 'o1-mini';
        inpMaxTokens.Value := 4096;
      end;
    etGemini:
      begin
        inpHost.Text := 'https://generativelanguage.googleapis.com/v1beta/';
        inpModel.Text := 'gemini-1.5-pro';
        inpMaxTokens.Value := 4096;
      end;
    etDeepSeek:
      begin
        inpHost.Text := 'https://api.deepseek.com/chat/completions';
        inpModel.Text := 'deepseek-reasoner';
        inpMaxTokens.Value := 4096;
      end;
    else
      inpHost.Text := '';
  end;
  FUpdate := false;
  inpCommonAIChange(nil);
end;

procedure TfrmSettings.actResetSettingsUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lyCommonAIEngineSettings.Enabled
                                 and (cbxEngineType.ItemIndex >= 0);
end;

procedure TfrmSettings.AfterConstruction;
begin
  inherited;
  FEngines := TCollections.CreateList<TCBAIEngineSettings>;
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
  stg.IsDefault := cbDefault.IsChecked;
  case cbxEngineType.ItemIndex of
    0:   stg.EngineType := etAnthropic;
    1:   stg.EngineType := etGemini;
    2:   stg.EngineType := etOllama;
    3:   stg.EngineType := etOpenAI;
    4:   stg.EngineType := etDeepSeek;
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
  cbDefault.IsChecked := stg.IsDefault;
  case stg.EngineType of
    etAnthropic: cbxEngineType.ItemIndex := 0;
    etGemini:    cbxEngineType.ItemIndex := 1;
    etOllama:    cbxEngineType.ItemIndex := 2;
    etOpenAI:    cbxEngineType.ItemIndex := 3;
    etDeepSeek:  cbxEngineType.ItemIndex := 4;
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

procedure TfrmSettings.liAIEnginesClick(Sender: TObject);
begin
  tcSettings.TabIndex := 0;
end;

procedure TfrmSettings.liSecurityClick(Sender: TObject);
begin
  tcSettings.TabIndex := 1;
end;
//
procedure TfrmSettings.LoadFromSettings(settings: TCBSettings);
begin
  inpPassphrase.Text := settings.Passphrase;
  inpPassphraseCheck.Text := settings.Passphrase;
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

procedure TfrmSettings.PassPhraseChange(Sender: TObject);
var
  color: TAlphaColor;
begin
  if inpPassphrase.Text = inpPassphraseCheck.Text then
    color := inpModel.TextSettings.FontColor
  else
    color := TAlphaColors.OrangeRed;
  inpPassphrase.TextSettings.FontColor := color;
  inpPassphraseCheck.TextSettings.FontColor := color;
end;

procedure TfrmSettings.SaveToSettings(settings: TCBSettings);
begin
  settings.Passphrase := inpPassphrase.Text;
  settings.AIEngines.Clear;
  settings.AIEngines.AddRange(FEngines);
end;

procedure TfrmSettings.sbAddEngineClick(Sender: TObject);
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
