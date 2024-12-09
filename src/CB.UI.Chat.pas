unit CB.UI.Chat;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Platform,
  Spring.Collections,
  CB.Network, CB.Settings, CB.AI.Interaction, FMX.ListBox, System.Actions,
  FMX.ActnList;

type
  TFrameEngineChange = procedure (Frame: TFrame; const Engine: TCBAIEngineSettings) of object;

  TfrChat = class(TFrame)
    outHistory: TMemo;
    inpQuestion: TMemo;
    btnSend: TButton;
    btnCopyToClip: TButton;
    btnClear: TButton;
    indSend: TAniIndicator;
    tmrSend: TTimer;
    ToolBar1: TToolBar;
    cbxEngines: TComboBox;
    ActionList1: TActionList;
    actSend: TAction;
    lblActiveEngine: TLabel;
    actCopyLastAnswer: TAction;
    SaveDialog1: TSaveDialog;
    Button1: TButton;
    actSaveChat: TAction;
    procedure actCopyLastAnswerExecute(Sender: TObject);
    procedure actCopyLastAnswerUpdate(Sender: TObject);
    procedure actSaveChatExecute(Sender: TObject);
    procedure actSaveChatUpdate(Sender: TObject);
    procedure actSendExecute(Sender: TObject);
    procedure actSendUpdate(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure cbxEnginesChange(Sender: TObject);
    procedure tmrSendTimer(Sender: TObject);
  private
    FChat          : IList<TAIInteraction>;
    FConfiguration : TCBSettings;
    FClipBoard     : IFMXClipboardService;
    FEngine        : TCBAIEngineSettings;
    FOnEngineChange: TFrameEngineChange;
    FRequest       : INetAsyncRequest;
    FSerializer    : IAISerializer;
  protected
    procedure SetConfiguration(const config: TCBSettings);
  public
    procedure AfterConstruction; override;
    property Configuration: TCBSettings read FConfiguration write SetConfiguration;
    property OnEngineChange: TFrameEngineChange read FOnEngineChange write FOnEngineChange;
  end;

implementation

uses
  GpConsole;

{$R *.fmx}

procedure TfrChat.actCopyLastAnswerExecute(Sender: TObject);
begin
  FClipBoard.SetClipboard(FChat.Last.Answer);
end;

procedure TfrChat.actCopyLastAnswerUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := (not FChat.IsEmpty) and assigned(FClipboard);
end;

procedure TfrChat.actSaveChatExecute(Sender: TObject);
begin
  if SaveDialog1.Execute then begin
    try
      outHistory.Lines.SaveToFile(SaveDialog1.FileName);
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  end;
end;

procedure TfrChat.actSaveChatUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := not FChat.IsEmpty;
end;

procedure TfrChat.actSendExecute(Sender: TObject);
begin
  FRequest := SendAsyncRequest(FSerializer.URL,
                               'Bearer ' + FEngine.Authorization,
                               FSerializer.QuestionToJSON(FEngine, FChat.ToArray, inpQuestion.Text));
  tmrSend.Enabled := true;
  indSend.Visible := true;
  indSend.Enabled := true;
end;

procedure TfrChat.actSendUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := assigned(FSerializer) and (not assigned(FRequest));
end;

procedure TfrChat.AfterConstruction;
begin
  inherited;
  FChat := TCollections.CreateList<TAIInteraction>;
  indSend.Visible := false;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, FClipBoard) then
    FClipBoard := nil;
end;

procedure TfrChat.btnClearClick(Sender: TObject);
begin
  FChat.Clear;
  outHistory.Lines.Clear;
end;

procedure TfrChat.cbxEnginesChange(Sender: TObject);
begin
  if cbxEngines.ItemIndex >= 0 then begin
    FEngine := FConfiguration.AIEngines[cbxEngines.ItemIndex];
    FSerializer := GSerializers[FEngine.EngineType];
  end
  else begin
    FEngine := Default(TCBAIEngineSettings);
    FSerializer := nil;
  end;
  if assigned(OnEngineChange) then
    OnEngineChange(Self, FEngine);
end;

procedure TfrChat.SetConfiguration(const config: TCBSettings);
begin
  FConfiguration := config;
  var defEng := -1;
  cbxEngines.Clear;
  cbxEngines.Items.BeginUpdate;
  try
    for var iEng := 0 to config.AIEngines.Count - 1 do begin
      cbxEngines.Items.Add(config.AIEngines[iEng].DisplayName(false));
      if config.AIEngines[iEng].IsDefault then
        defEng := iEng;
    end;
  finally cbxEngines.Items.EndUpdate; end;
  cbxEngines.ItemIndex := defEng;
  cbxEnginesChange(cbxEngines);
end;

procedure TfrChat.tmrSendTimer(Sender: TObject);
var
  answer: string;
begin
  if not FRequest.IsCompleted then
    Exit;

  var errorMsg := FRequest.Error;
  if errorMsg = '' then
    answer := FSerializer.JSONToAnswer(FEngine, FRequest.Response, errorMsg);

  if errorMsg <> '' then
    ShowMessage('Error: ' + errorMsg)
  else begin
    var int := Default(TAIInteraction);
    int.Question := inpQuestion.Text;
    int.Answer := answer;
    FChat.Add(int);
    outHistory.Lines.BeginUpdate;
    try
      if outHistory.Lines.Count > 0 then
        outHistory.Lines.Add('--------------------');
      outHistory.Lines.Add('Q> ' + inpQuestion.Text);
      outHistory.Lines.Add('');
      outHistory.Lines.Add('A> ' + answer);
      outHistory.Lines.Add('');
    finally
      outHistory.Lines.EndUpdate;
    end;
    inpQuestion.Lines.Clear;
  end;

  FRequest := nil;

  tmrSend.Enabled := false;
  indSend.Visible := false;
  indSend.Enabled := false;
end;

end.
