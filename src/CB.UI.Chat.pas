unit CB.UI.Chat;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.StrUtils, System.Actions, System.Skia,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Platform,
  FMX.ListBox, FMX.ActnList, FMX.Skia,
  Spring, Spring.Collections,
  CB.Network, CB.Settings, CB.AI.Interaction, FMX.Layouts;

type
  TFrameEngineChange = procedure (Frame: TFrame; const Engine: TCBAIEngineSettings) of object;
  TFrameNotifyEvent = procedure (Frame: TFrame) of object;
  TFrameGetChatInfo = procedure (Frame: TFrame; var countChats: integer) of object;
  TFrameExecuteInAll = procedure (Frame: TFrame; const question: string) of object;

  TfrChat = class(TFrame)
    outHistory: TMemo;
    inpQuestion: TMemo;
    tmrSend: TTimer;
    tbChat: TToolBar;
    cbxEngines: TComboBox;
    ActionList1: TActionList;
    actSend: TAction;
    lblActiveEngine: TLabel;
    actCopyLastAnswer: TAction;
    SaveDialog1: TSaveDialog;
    actSaveChat: TAction;
    actSendToAll: TAction;
    actLoadChat: TAction;
    OpenDialog1: TOpenDialog;
    btnSaveChat: TSpeedButton;
    SkSvg1: TSkSvg;
    btnLoadChat: TSpeedButton;
    SkSvg2: TSkSvg;
    btnCopy: TSpeedButton;
    SkSvg3: TSkSvg;
    actClearHistory: TAction;
    btnClearChat: TSpeedButton;
    SkSvg4: TSkSvg;
    btnSend: TSpeedButton;
    svgSend: TSkSvg;
    indSend: TAniIndicator;
    btnSendToAll: TSpeedButton;
    SkSvg6: TSkSvg;
    lyEngine: TFlowLayout;
    lyTools: TFlowLayout;
    lySpacer: TLayout;
    cbDisableSysPrompt: TCheckBox;
    procedure actClearHistoryExecute(Sender: TObject);
    procedure actClearHistoryUpdate(Sender: TObject);
    procedure actCopyLastAnswerExecute(Sender: TObject);
    procedure actCopyLastAnswerUpdate(Sender: TObject);
    procedure actLoadChatExecute(Sender: TObject);
    procedure actLoadChatUpdate(Sender: TObject);
    procedure actSaveChatExecute(Sender: TObject);
    procedure actSaveChatUpdate(Sender: TObject);
    procedure actSendExecute(Sender: TObject);
    procedure actSendToAllExecute(Sender: TObject);
    procedure actSendToAllUpdate(Sender: TObject);
    procedure actSendUpdate(Sender: TObject);
    procedure cbxEnginesChange(Sender: TObject);
    procedure tmrSendTimer(Sender: TObject);
  private const
    CConversationDelimiter = '--------------------';
    CConversationQuestion = 'Q>';
    CConversationAnswer = 'A>';
  private var
    FChat          : IList<TAIInteraction>;
    FConfiguration : TCBSettings;
    FClipBoard     : IFMXClipboardService;
    FEngine        : TCBAIEngineSettings;
    FOnEngineChange: TFrameEngineChange;
    FOnGetChatInfo : TFrameGetChatInfo;
    FOnExecuteInAll: TFrameExecuteInAll;
    FRequest       : INetAsyncRequest;
    FSerializer    : IAISerializer;
  protected
    procedure LoadChat(chat: TStrings);
    procedure SetConfiguration(const config: TCBSettings);
  public
    procedure AfterConstruction; override;
    procedure ClearLog;
    procedure ReloadConfiguration;
    procedure SendQuestion(const question: string);
    procedure SetEngine(const engName: string);
    property Configuration: TCBSettings read FConfiguration write SetConfiguration;
    property OnEngineChange: TFrameEngineChange read FOnEngineChange write FOnEngineChange;
    property OnGetChatInfo: TFrameGetChatInfo read FOnGetChatInfo write FOnGetChatInfo;
    property OnExecuteInAll: TFrameExecuteInAll read FOnExecuteInAll write FOnExecuteInAll;
  end;

implementation

uses
  CB.AI.Registry;

{$R *.fmx}

procedure TfrChat.actClearHistoryExecute(Sender: TObject);
begin
  FChat.Clear;
  outHistory.Lines.Clear;
end;

procedure TfrChat.actClearHistoryUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := not FChat.IsEmpty;
end;

procedure TfrChat.actCopyLastAnswerExecute(Sender: TObject);
begin
  FClipBoard.SetClipboard(FChat.Last.Answer);
end;

procedure TfrChat.actCopyLastAnswerUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := (not FChat.IsEmpty) and assigned(FClipboard);
end;

procedure TfrChat.actLoadChatExecute(Sender: TObject);
begin
  if OpenDialog1.Execute then begin
    var chat := TStringList.Create;
    try
      try
        chat.LoadFromFile(OpenDialog1.FileName);
        LoadChat(chat);
      except
        on E: Exception do
          ShowMessage('Error: ' + E.Message);
      end;
    finally FreeAndNil(chat); end;
  end;
end;

procedure TfrChat.actLoadChatUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := not assigned(FRequest);
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
  var headers := TCollections.CreateList<TNetworkHeader>;
  for var header in GNetworkHeaderProvider[FEngine.EngineType] do
    if not header.Value2.Contains(CAuthorizationKeyPlaceholder) then
      headers.Add(header)
    else if FEngine.Authorization.Trim <> '' then
      headers.Add(TNetworkHeader.Create(header.Value1,
                    StringReplace(header.Value2, CAuthorizationKeyPlaceholder, FEngine.Authorization, [])));

  FRequest := SendAsyncRequest(FSerializer.URL(FEngine), headers,
                               FSerializer.QuestionToJSON(FEngine, FChat.ToArray, not cbDisableSysPrompt.IsChecked, inpQuestion.Text));
  tmrSend.Enabled := true;
  indSend.Visible := true;
  indSend.Enabled := true;
  svgSend.Visible := false;
end;

procedure TfrChat.actSendUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := assigned(FSerializer)
                                 and (not assigned(FRequest))
                                 and (FEngine.Host.Trim <> '')
                                 and (inpQuestion.Text.Trim <> '');
end;

procedure TfrChat.actSendToAllExecute(Sender: TObject);
begin
  FOnExecuteInAll(Self, inpQuestion.Text);
end;

procedure TfrChat.actSendToAllUpdate(Sender: TObject);
var
  count: integer;
begin
  count := 0;
  if assigned(FOnGetChatInfo) then
    FOnGetChatInfo(Self, count);
  (Sender as TAction).Enabled := actSend.Enabled and (count > 1) and (assigned(FOnExecuteInAll));
end;

procedure TfrChat.AfterConstruction;
begin
  inherited;
  FChat := TCollections.CreateList<TAIInteraction>;
  indSend.Visible := false;
  svgSend.Visible := true;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, FClipBoard) then
    FClipBoard := nil;
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

procedure TfrChat.ClearLog;
begin
  actClearHistory.Execute;
end;

procedure TfrChat.LoadChat(chat: TStrings);
var
  qa: TAIInteraction;
begin
  outHistory.Lines.Assign(chat);
  FChat.Clear;
  qa := Default(TAIInteraction);
  var inQuestion := true;
  for var s in chat do begin
    if SameText(s, CConversationDelimiter) then begin
      FChat.Add(qa);
      qa := Default(TAIInteraction);
    end
    else if s.StartsWith(CConversationQuestion, true) then begin
      inQuestion := true;
      qa.Question := s.Remove(0, Length(CConversationQuestion) + 1);
    end
    else if s.StartsWith(CConversationAnswer, true) then begin
      inQuestion := false;
      qa.Answer := s.Remove(0, Length(CConversationAnswer) + 1);
    end
    else if inQuestion then
      qa.Question := qa.Question + #$0A + s
    else
      qa.Answer := qa.Answer + #$0A + s;
  end;
  if qa.Question <> '' then
    FChat.Add(qa);
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

procedure TfrChat.SendQuestion(const question: string);
begin
  inpQuestion.Text := question;
  actSend.Execute;
end;

procedure TfrChat.SetConfiguration(const config: TCBSettings);
begin
  FConfiguration := config;
  ReloadConfiguration;
end;

procedure TfrChat.SetEngine(const engName: string);
begin
  cbxEngines.ItemIndex := -1;
  for var iEngine := 0 to FConfiguration.AIEngines.Count - 1 do
    if SameText(engName, FConfiguration.AIEngines[iEngine].DisplayName(false)) then begin
      cbxEngines.ItemIndex := iEngine;
      break; //for iEngine
    end;
  cbxEngines.OnChange(cbxEngines);
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
        outHistory.Lines.Add(CConversationDelimiter);
      outHistory.Lines.Add(CConversationQuestion + ' ' + inpQuestion.Text);
      outHistory.Lines.Add('');
      outHistory.CaretPosition := Point(0, outHistory.Lines.Count);
      outHistory.Lines.Add(CConversationAnswer + ' ' + answer);
      outHistory.Lines.Add('');
    finally
      outHistory.Lines.EndUpdate;
    end;
    inpQuestion.Lines.Clear;
  end;

  FRequest := nil;

  indSend.Visible := false;
  indSend.Enabled := false;
  svgSend.Visible := true;
end;

end.
