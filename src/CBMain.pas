unit CBMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, CB.UI.Chat,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl,
  CB.Settings, System.Actions, FMX.ActnList{, CB.AI.Interaction};

type
  TfrmCBMain = class(TForm)
    tcChatter: TTabControl;
    ToolbarMain: TToolBar;
    btnNewChat: TSpeedButton;
    btnSettings: TSpeedButton;
    ActionList1: TActionList;
    actNewChat: TAction;
    procedure actNewChatExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSettings: TCBSettings;
  protected
    function SettingsFileName: string;
    procedure HandleEngineChange(Frame: TFrame; const Engine: TCBAIEngineSettings);
  public
  end;

var
  frmCBMain: TfrmCBMain;

implementation

{$R *.fmx}

uses
  CB.Encryption,
  CB.UI.Settings,
  CB.AI.Client.OpenAI;

procedure TfrmCBMain.actNewChatExecute(Sender: TObject);
begin
  var ti := tcChatter.Add(TTabItem) as TTabItem;
  ti.Text := 'OpenAI';
  var fr := TfrChat.Create(ti);
  fr.Parent := ti;
  fr.Align := TAlignLayout.Client;
  fr.OnEngineChange := HandleEngineChange; // must be before setting Configuration
  fr.Configuration := FSettings;
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
end;

function TfrmCBMain.SettingsFileName: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'Gp', 'Chatterbox');
  TDirectory.CreateDirectory(Result);
  Result := TPath.Combine(Result, 'settings.ini');
end;

procedure TfrmCBMain.btnSettingsClick(Sender: TObject);
var
  frame: TComponent;
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

procedure TfrmCBMain.FormCreate(Sender: TObject);
begin
  FSettings := TCBSettings.Create;
  if FileExists(SettingsFileName) then begin
    try
      FSettings.Load(SettingsFileName);
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  end;
end;

end.
