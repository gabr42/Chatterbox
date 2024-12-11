unit CB.UI.Chat;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.StrUtils, System.Actions,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Platform,
  FMX.ListBox, FMX.ActnList,
  Spring, Spring.Collections,
  CB.Network, CB.Settings, CB.AI.Interaction;

type
  TFrameEngineChange = procedure (Frame: TFrame; const Engine: TCBAIEngineSettings) of object;
  TFrameNotifyEvent = procedure (Frame: TFrame) of object;

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
    SpeedButton1: TSpeedButton;
    procedure actCopyLastAnswerExecute(Sender: TObject);
    procedure actCopyLastAnswerUpdate(Sender: TObject);
    procedure actSaveChatExecute(Sender: TObject);
    procedure actSaveChatUpdate(Sender: TObject);
    procedure actSendExecute(Sender: TObject);
    procedure actSendUpdate(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure cbxEnginesChange(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure tmrSendTimer(Sender: TObject);
  private
    FChat          : IList<TAIInteraction>;
    FConfiguration : TCBSettings;
    FClipBoard     : IFMXClipboardService;
    FEngine        : TCBAIEngineSettings;
    FOnEngineChange: TFrameEngineChange;
    FOnRequestClose: TFrameNotifyEvent;
    FRequest       : INetAsyncRequest;
    FSerializer    : IAISerializer;
  protected
    procedure SetConfiguration(const config: TCBSettings);
  public
    procedure AfterConstruction; override;
    procedure ReloadConfiguration;
    property Configuration: TCBSettings read FConfiguration write SetConfiguration;
    property OnEngineChange: TFrameEngineChange read FOnEngineChange write FOnEngineChange;
    property OnRequestClose: TFrameNotifyEvent read FOnRequestClose write FOnRequestClose;
  end;

implementation

uses
  CB.AI.Registry;

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
var
  authorization: TNetworkHeader;
begin
  var headers := TCollections.CreateList<TNetworkHeader>;
  for var header in GNetworkHeaderProvider[FEngine.EngineType] do
    if not header.Value2.Contains(CAuthorizationKeyPlaceholder) then
      headers.Add(header)
    else if FEngine.Authorization.Trim <> '' then
      headers.Add(TNetworkHeader.Create(header.Value1,
                    StringReplace(header.Value2, CAuthorizationKeyPlaceholder, FEngine.Authorization, [])));

  FRequest := SendAsyncRequest(FSerializer.URL(FEngine), headers,
                               FSerializer.QuestionToJSON(FEngine, FChat.ToArray, inpQuestion.Text));
  tmrSend.Enabled := true;
  indSend.Visible := true;
  indSend.Enabled := true;
end;

procedure TfrChat.actSendUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := assigned(FSerializer)
                                 and (not assigned(FRequest))
                                 and (FEngine.Host.Trim <> '')
                                 and (inpQuestion.Text.Trim <> '');
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

procedure TfrChat.ReloadConfiguration;
begin
  var activeEngine := cbxEngines.Text;
  var defEng := -1;
  cbxEngines.Clear;
  cbxEngines.Items.BeginUpdate;
  try
    for var iEng := 0 to FConfiguration.AIEngines.Count - 1 do begin
      cbxEngines.Items.Add(FConfiguration.AIEngines[iEng].DisplayName(false));
      if FConfiguration.AIEngines[iEng].IsDefault then
        defEng := iEng;
    end;
  finally cbxEngines.Items.EndUpdate; end;
  if activeEngine <> '' then
    cbxEngines.ItemIndex := cbxEngines.Items.IndexOf(activeEngine)
  else
    cbxEngines.ItemIndex := defEng;
  cbxEnginesChange(cbxEngines);
end;

procedure TfrChat.SetConfiguration(const config: TCBSettings);
begin
  FConfiguration := config;
  ReloadConfiguration;
end;

procedure TfrChat.SpeedButton1Click(Sender: TObject);
begin
  FOnRequestClose(Self);
end;

procedure TfrChat.tmrSendTimer(Sender: TObject);
var
  answer: string;
begin
  if not FRequest.IsCompleted then
    Exit;

  tmrSend.Enabled := false;

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
      outHistory.CaretPosition := Point(0, outHistory.Lines.Count);
      outHistory.Lines.Add('A> ' + answer);
      outHistory.Lines.Add('');
    finally
      outHistory.Lines.EndUpdate;
    end;
    inpQuestion.Lines.Clear;
  end;

  FRequest := nil;

  indSend.Visible := false;
  indSend.Enabled := false;
end;

end.
