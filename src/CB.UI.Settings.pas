unit CB.UI.Settings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Actions, System.Skia, System.Generics.Defaults, System.Generics.Collections,
  FMX.Platform, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListBox,
  FMX.Layouts, FMX.TabControl, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.ActnList, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.EditBox, FMX.NumberBox, FMX.Skia,
  Spring.Collections,
  CB.Utils, CB.Settings, CB.AI.Registry, CB.AI.Interaction, CB.Network,
  FMX.ComboEdit;

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
    Layout2: TFlowLayout;
    sbAddEngine: TSpeedButton;
    sbRemoveEngine: TSpeedButton;
    lbAIEngines: TListBox;
    Button1: TButton;
    Button2: TButton;
    lyCommonAIEngineSettings: TLayout;
    cbxEngineType: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    inpName: TEdit;
    tbSettings: TToolBar;
    btnOK: TButton;
    Button4: TButton;
    ActionList1: TActionList;
    actDeleteAIEngine: TAction;
    Label5: TLabel;
    inpAuth: TEdit;
    lblLoadedEngine: TLabel;
    Label8: TLabel;
    inpHost: TEdit;
    cbDefault: TCheckBox;
    inpSystemPrompt: TMemo;
    Label6: TLabel;
    btnSetToDefault: TButton;
    actResetSettings: TAction;
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
    Label13: TLabel;
    inpNetworkTimeout: TNumberBox;
    sbDuplicateEngine: TSpeedButton;
    actDuplicateAIEngine: TAction;
    SkSvg6: TSkSvg;
    SkSvg1: TSkSvg;
    SkSvg2: TSkSvg;
    sbMoveUp: TSpeedButton;
    SkSvg3: TSkSvg;
    sbMoveDown: TSpeedButton;
    SkSvg4: TSkSvg;
    actMoveUp: TAction;
    actMoveDown: TAction;
    sbRefreshModels: TSpeedButton;
    cbxModel: TComboEdit;
    lblSettingLocation: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure actDeleteAIEngineExecute(Sender: TObject);
    procedure actDeleteAIEngineUpdate(Sender: TObject);
    procedure actDuplicateAIEngineExecute(Sender: TObject);
    procedure actDuplicateAIEngineUpdate(Sender: TObject);
    procedure actGetAPIKeyExecute(Sender: TObject);
    procedure actGetAPIKeyUpdate(Sender: TObject);
    procedure actMoveDownExecute(Sender: TObject);
    procedure actMoveDownUpdate(Sender: TObject);
    procedure actMoveUpExecute(Sender: TObject);
    procedure actMoveUpUpdate(Sender: TObject);
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
    procedure RefreshModels(const engineConfig: TCBAIEngineSettings);
    procedure SelectModel(const models: TArray<string>);
    procedure Swap(idx1, idx2: integer);
    procedure SetLocation(const value: string);
  public
    procedure AfterConstruction; override;
    procedure LoadFromSettings(settings: TCBSettings);
    procedure SaveToSettings(settings: TCBSettings);
    property Location: string write SetLocation;
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

procedure TfrmSettings.actDuplicateAIEngineExecute(Sender: TObject);
begin
  var stg := FEngines[lbAIEngines.ItemIndex];
  stg.IsDefault := false;
  var li := TListBoxItem.Create(Self);
  li.Parent := lbAIEngines;
  li.Text := stg.DisplayName;
  lbAIEngines.ItemIndex := FEngines.Add(stg);
  lbAIEnginesClick(lbAIEngines);
end;

procedure TfrmSettings.actDuplicateAIEngineUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lbAIEngines.ItemIndex >= 0;
end;

procedure TfrmSettings.actGetAPIKeyExecute(Sender: TObject);
begin
  var keyUrl := GSerializers[FEngines[lbAIEngines.ItemIndex].EngineType].URL(FEngines[lbAIEngines.ItemIndex], qpAPIKeys);
  if keyUrl <> '' then
    OpenURL(keyURL);
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

procedure TfrmSettings.actMoveDownExecute(Sender: TObject);
begin
  Swap(lbAIEngines.ItemIndex, lbAIEngines.ItemIndex + 1);
end;

procedure TfrmSettings.actMoveDownUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lbAIEngines.ItemIndex < (lbAIEngines.Count - 1);
end;

procedure TfrmSettings.actMoveUpExecute(Sender: TObject);
begin
  Swap(lbAIEngines.ItemIndex, lbAIEngines.ItemIndex - 1);
end;

procedure TfrmSettings.actMoveUpUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := lbAIEngines.ItemIndex > 0;
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
  inpHost.Text := GSerializers[stg.EngineType].URL(stg, qpChat);
  case stg.EngineType of
    etAnthropic:
      begin
        SelectModel(['claude-3-5-sonnet-latest']);
        inpMaxTokens.Value := 4096;
      end;
    etOllama:
      begin
        SelectModel(['codellama', 'deepseek-coder']);
        inpMaxTokens.Value := 4096;
      end;
    etOpenAI:
      begin
        SelectModel(['o3-mini', 'o1-mini']);
        inpMaxTokens.Value := 4096;
      end;
    etGemini:
      begin
        SelectModel(['gemini-2.0-flash', 'gemini-1.5-pro']);
        inpMaxTokens.Value := 4096;
      end;
    etDeepSeek:
      begin
        SelectModel(['deepseek-reasoner']);
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
  stg.Name := inpName.Text;
  stg.Authorization := inpAuth.Text;
  stg.Host := inpHost.Text;
  stg.SysPrompt := StringReplace(StringReplace(inpSystemPrompt.Text, #$0D, ' ', [rfReplaceAll]), #$0A, ' ', [rfReplaceAll]);
  stg.MaxTokens := Round(inpMaxTokens.Value);
  stg.NetTimeoutSec := Round(inpNetworkTimeout.Value);
  RefreshModels(stg);
  stg.Model := cbxModel.Text;
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
  cbDefault.IsChecked := stg.IsDefault;
  case stg.EngineType of
    etAnthropic: cbxEngineType.ItemIndex := 0;
    etGemini:    cbxEngineType.ItemIndex := 1;
    etOllama:    cbxEngineType.ItemIndex := 2;
    etOpenAI:    cbxEngineType.ItemIndex := 3;
    etDeepSeek:  cbxEngineType.ItemIndex := 4;
    else         cbxEngineType.ItemIndex := -1;
  end;
  RefreshModels(stg);
  SelectModel([stg.Model]);
  inpName.Text := stg.Name;
  inpAuth.Text := stg.Authorization;
  inpSystemPrompt.Text := stg.SysPrompt;
  inpHost.Text := stg.Host;
  inpMaxTokens.Value := stg.MaxTokens;
  inpNetworkTimeout.Value := stg.NetTimeoutSec;
  FUpdate := false;

  lblLoadedEngine.Text := stg.DisplayName(false);
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
    color := inpName.TextSettings.FontColor
  else
    color := TAlphaColors.OrangeRed;
  inpPassphrase.TextSettings.FontColor := color;
  inpPassphraseCheck.TextSettings.FontColor := color;
end;

procedure TfrmSettings.RefreshModels(const engineConfig: TCBAIEngineSettings);
var
  serializer: IAISerializer;
begin
  var model := cbxModel.Text;
  if not GSerializers.TryGetValue(engineConfig.engineType, serializer) then
    Exit;
  var url := serializer.URL(engineConfig, qpModels);
  if url = '' then begin
    cbxModel.Items.Clear;
    SelectModel([model]);
    Exit;
  end;

  var request := SendSyncRequest(url, MakeHeaders(engineConfig), '', engineConfig.NetTimeoutSec);
  var errorMsg := request.Error;
  if errorMsg = '' then begin
    cbxModel.Items.Clear;
    var models := serializer.JSONToModels(request.Response, errorMsg);
    TArray.Sort<string>(models, TIStringComparer.Ordinal);
    cbxModel.Items.AddStrings(models);
    SelectModel([model]);
  end;

  if errorMsg <> '' then
    ShowMessage(engineConfig.Name + #13#10#13#10'Error : ' + errorMsg)
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
  stg.NetTimeoutSec := 60;
  if FEngines.Count = 0 then
    stg.IsDefault := true;
  stg.MaxTokens := 2048;
  var li := TListBoxItem.Create(Self);
  li.Parent := lbAIEngines;
  li.Text := stg.DisplayName;
  lbAIEngines.ItemIndex := FEngines.Add(stg);
  lbAIEnginesClick(lbAIEngines);
end;

procedure TfrmSettings.SelectModel(const models: TArray<string>);
begin
  for var model in models do begin
    for var iModel := 0 to cbxModel.Items.Count - 1 do
      if SameText(model, cbxModel.Items[iModel]) then begin
        cbxModel.ItemIndex := iModel;
        Exit;
      end;
  end;
  cbxModel.ItemIndex := -1;
  cbxModel.Text := models[0];
end;

procedure TfrmSettings.SetLocation(const value: string);
begin
  lblSettingLocation.Text := 'Settings location: ' + value;
end;

procedure TfrmSettings.Swap(idx1, idx2: integer);
begin
  var stg := FEngines[idx1];
  FEngines[idx1] := FEngines[idx2];
  FEngines[idx2] := stg;
  lbAIEngines.ListItems[idx1].Text := FEngines[idx1].DisplayName;
  lbAIEngines.ListItems[idx2].Text := FEngines[idx2].DisplayName;
  lbAIEngines.ItemIndex := idx2;
  lbAIEnginesClick(lbAIEngines);
end;

end.
