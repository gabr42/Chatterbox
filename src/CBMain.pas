unit CBMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils, System.IniFiles, System.Actions, System.Skia,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, CB.UI.Chat,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl, FMX.ActnList, FMX.Skia,
  CB.Settings;

type
  TfrmCBMain = class(TForm)
    tcChatter: TTabControl;
    ToolbarMain: TToolBar;
    btnNewChat: TSpeedButton;
    btnSettings: TSpeedButton;
    ActionList1: TActionList;
    actNewChat: TAction;
    actPrevEngine: TAction;
    actNextEngine: TAction;
    SkSvg1: TSkSvg;
    SkSvg2: TSkSvg;
    actSettings: TAction;
    procedure actNewChatExecute(Sender: TObject);
    procedure actNextEngineExecute(Sender: TObject);
    procedure actPrevEngineExecute(Sender: TObject);
    procedure actSettingsExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tcChatterChange(Sender: TObject);
  private
    FLoadingDesktop: boolean;
    FSettings: TCBSettings;
  protected
    function  CreateChatFrame: TfrChat;
    function  DesktopFileName: string;
    procedure LoadDesktop;
    procedure SaveDesktop;
    function  SettingsFileName: string;
    procedure HandleEngineChange(Frame: TFrame; const Engine: TCBAIEngineSettings);
    procedure HandleGetPassphrase(var passphrase: string; var cancel: boolean);
    procedure HandleRequestClose(Frame: TFrame);
    procedure HandleGetChatInfo(Frame: TFrame; var countChats: integer);
    procedure HandleExecuteInAll(Frame: TFrame; const question: string);
  public
  end;

var
  frmCBMain: TfrmCBMain;

implementation

{$R *.fmx}

uses
  CB.Encryption,
  CB.UI.Settings, CB.UI.Passphrase,
  CB.AI.Client.OpenAI;

procedure TfrmCBMain.actNewChatExecute(Sender: TObject);
begin
  CreateChatFrame;
  SaveDesktop;
end;

procedure TfrmCBMain.actNextEngineExecute(Sender: TObject);
begin
  if tcChatter.TabIndex < (tcChatter.TabCount - 1) then
    tcChatter.TabIndex := tcChatter.TabIndex + 1;
end;

procedure TfrmCBMain.actPrevEngineExecute(Sender: TObject);
begin
  if tcChatter.TabIndex > 0 then
    tcChatter.TabIndex := tcChatter.TabIndex - 1;
end;

procedure TfrmCBMain.actSettingsExecute(Sender: TObject);
begin
  var frmSettings := TfrmSettings.Create(Self);
  try
    frmSettings.LoadFromSettings(FSettings);
    if frmSettings.ShowModal = mrOK then begin
      frmSettings.SaveToSettings(FSettings);
      try
        FSettings.Save(SettingsFileName);
      except
        on E: Exception do
          ShowMessage('Error: ' + E.Message);
      end;
      for var iTab := 0 to tcChatter.TabCount-1 do
        (TControl((tcChatter.Tabs[iTab] as TTabItem).Components[0]).Children[0] as TfrChat).ReloadConfiguration;
    end;
  finally FreeAndNil(frmSettings); end;
end;

procedure TfrmCBMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FSettings);
end;

procedure TfrmCBMain.HandleEngineChange(Frame: TFrame;
  const Engine: TCBAIEngineSettings);
begin
  var ti := Frame.Parent.Parent as TTabItem;
  ti.Text := Engine.DisplayName(false);
  if not FLoadingDesktop then
    SaveDesktop;
end;

procedure TfrmCBMain.HandleExecuteInAll(Frame: TFrame; const question: string);
begin
  for var iTab := 0 to tcChatter.TabCount-1 do
    (TControl((tcChatter.Tabs[iTab] as TTabItem).Components[0]).Children[0] as TfrChat).SendQuestion(question);
end;

procedure TfrmCBMain.HandleGetChatInfo(Frame: TFrame; var countChats: integer);
begin
  countChats := tcChatter.TabCount;
end;

procedure TfrmCBMain.HandleGetPassphrase(var passphrase: string; var cancel: boolean);
begin
  var frmPassphrase := TfrmPassphrase.Create(Self);
  try
    cancel := (frmPassphrase.ShowModal <> mrOK);
    if cancel then
      passPhrase := ''
    else
      passPhrase := frmPassphrase.Passphrase;
  finally FreeAndNil(frmPassphrase); end;
end;

procedure TfrmCBMain.HandleRequestClose(Frame: TFrame);
begin
  var ti := Frame.Parent.Parent as TTabItem;
  tcChatter.RemoveObject(ti);
  SaveDesktop;
end;

procedure TfrmCBMain.LoadDesktop;
begin
  FLoadingDesktop := true;
  try
    var iniFile := TIniFile.Create(DesktopFileName);
    try
      var iTab := 1;
      repeat
        var keyName := 'Tab_' + iTab.ToString;
        if not iniFile.ValueExists('Tabs', keyName) then
          break;
        CreateChatFrame.SetEngine(iniFile.ReadString('Tabs', keyName, ''));
        Inc(iTab);
      until false;
      tcChatter.TabIndex := iniFile.ReadInteger('Tabs', 'ActiveTab', 0);
    finally FreeAndNil(iniFile); end;
  finally FLoadingDesktop := false; end;
end;

function TfrmCBMain.DesktopFileName: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'Gp', 'Chatterbox');
  TDirectory.CreateDirectory(Result);
  Result := TPath.Combine(Result, 'desktop.ini');
end;

procedure TfrmCBMain.SaveDesktop;
begin
  DeleteFile(DesktopFileName);
  var iniFile := TIniFile.Create(DesktopFileName);
  try
    for var iTab := 0 to tcChatter.TabCount-1 do
      iniFile.WriteString('Tabs', 'Tab_' + (iTab+1).ToString, (tcChatter.Tabs[iTab] as TTabItem).Text);
    iniFile.WriteInteger('Tabs', 'ActiveTab', tcChatter.TabIndex);
  finally FreeAndNil(iniFile); end;
end;

function TfrmCBMain.SettingsFileName: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'Gp', 'Chatterbox');
  TDirectory.CreateDirectory(Result);
  Result := TPath.Combine(Result, 'settings.ini');
end;

function TfrmCBMain.CreateChatFrame: TfrChat;
begin
  var ti := tcChatter.Add(TTabItem) as TTabItem;
  ti.Text := 'OpenAI';
  tcChatter.ActiveTab := ti;
  var fr := TfrChat.Create(ti);
  fr.Parent := ti;
  fr.Align := TAlignLayout.Client;
  fr.OnEngineChange := HandleEngineChange; // must be before setting Configuration
  fr.OnRequestClose := HandleRequestClose;
  fr.OnGetChatInfo := HandleGetChatInfo;
  fr.OnExecuteInAll := HandleExecuteInAll;
  fr.Configuration := FSettings;
  Result := fr;
end;

procedure TfrmCBMain.FormCreate(Sender: TObject);
begin
  FSettings := TCBSettings.Create;
  FSettings.OnGetPassphrase := HandleGetPassphrase;
  if FileExists(SettingsFileName) then begin
    try
      FSettings.Load(SettingsFileName);
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  end;
  if FileExists(DesktopFileName) then begin
    try
      LoadDesktop;
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  end;
end;

procedure TfrmCBMain.tcChatterChange(Sender: TObject);
begin
  if not FLoadingDesktop then
    SaveDesktop;
end;

end.
