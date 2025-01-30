unit CB.UI.Chat;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.StrUtils, System.Actions, System.Skia,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Platform,
  FMX.ListBox, FMX.ActnList, FMX.Skia, FMX.TextLayout,
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
    btnPrevious: TSpeedButton;
    btnNext: TSpeedButton;
    actPrevious: TAction;
    actNext: TAction;
    SkSvg5: TSkSvg;
    SkSvg7: TSkSvg;
    actStop: TAction;
    procedure actClearHistoryExecute(Sender: TObject);
    procedure actClearHistoryUpdate(Sender: TObject);
    procedure actCopyLastAnswerExecute(Sender: TObject);
    procedure actCopyLastAnswerUpdate(Sender: TObject);
    procedure actLoadChatExecute(Sender: TObject);
    procedure actLoadChatUpdate(Sender: TObject);
    procedure actNextExecute(Sender: TObject);
    procedure actPreviousExecute(Sender: TObject);
    procedure actSaveChatExecute(Sender: TObject);
    procedure actSaveChatUpdate(Sender: TObject);
    procedure actSendExecute(Sender: TObject);
    procedure actSendToAllExecute(Sender: TObject);
    procedure actSendToAllUpdate(Sender: TObject);
    procedure actSendUpdate(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
    procedure actStopUpdate(Sender: TObject);
    procedure cbxEnginesChange(Sender: TObject);
    procedure outHistoryChange(Sender: TObject);
    procedure outHistoryEnter(Sender: TObject);
    procedure outHistoryKeyUp(Sender: TObject; var Key: Word; var KeyChar:
        WideChar; Shift: TShiftState);
    procedure outHistoryMouseUp(Sender: TObject; Button: TMouseButton; Shift:
        TShiftState; X, Y: Single);
    procedure tmrSendTimer(Sender: TObject);
  private const
    CConversationDelimiter = '--------------------';
    CConversationQuestion = 'Q>';
    CConversationAnswer = 'A>';
    CConversationReasoning = 'R>';
  private var
    FChat          : IList<TAIInteraction>;
    FChatPosition  : TCaretPosition;
    FConfiguration : TCBSettings;
    FClipBoard     : IFMXClipboardService;
    FEngine        : TCBAIEngineSettings;
    FOnEngineChange: TFrameEngineChange;
    FOnGetChatInfo : TFrameGetChatInfo;
    FOnExecuteInAll: TFrameExecuteInAll;
    FRequest       : INetAsyncRequest;
    FSerializer    : IAISerializer;
  protected
    procedure CheckActions(force: boolean = false);
    function  ExtractReasoning(const response: string; var reasoning: string): string;
    function  FindQA(line, delta: integer; var newLine: integer): boolean;
    procedure JumpInChat(delta: integer);
    procedure LoadChat(chat: TStrings);
    procedure ScrollToLine(memo: TMemo; line: integer);
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

function GetLineHeight(Memo: TMemo; const text: string = 'Ag'): Single;
var
  TextLayout: TTextLayout;
begin
  // Create a TTextLayout instance
  TextLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    TextLayout.BeginUpdate;
    try
      // Assign the memo's font and text settings
      TextLayout.Font.Assign(Memo.Font);
      TextLayout.WordWrap := Memo.WordWrap;
      TextLayout.HorizontalAlign := Memo.TextAlign;
      TextLayout.MaxSize := PointF(Memo.Width - Memo.Padding.Left - Memo.Padding.Right, 9999999);
      TextLayout.Text := text;
    finally
      TextLayout.EndUpdate;
    end;
    // The height of the layout corresponds to a single line height
    Result := TextLayout.Height;
  finally
    TextLayout.Free;
  end;
end;

procedure TfrChat.actNextExecute(Sender: TObject);
begin
  JumpInChat(+1);
end;

procedure TfrChat.actPreviousExecute(Sender: TObject);
begin
  JumpInChat(-1);
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
                               FSerializer.QuestionToJSON(FEngine, FChat.ToArray, not cbDisableSysPrompt.IsChecked, inpQuestion.Text),
                               FEngine.NetTimeoutSec);
  tmrSend.Enabled := true;
  indSend.Visible := true;
  indSend.Enabled := true;
  svgSend.Visible := false;
  btnSend.Action := actStop;
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

procedure TfrChat.actStopExecute(Sender: TObject);
begin
  if not assigned(FRequest) then
    Exit;

  FRequest.Cancel;
  FRequest := nil;

  tmrSend.Enabled := false;
  indSend.Visible := false;
  indSend.Enabled := false;
  svgSend.Visible := true;
  btnSend.Action := actSend;
end;

procedure TfrChat.actStopUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := assigned(FRequest);
end;

procedure TfrChat.AfterConstruction;
begin
  inherited;
  FChat := TCollections.CreateList<TAIInteraction>;
  indSend.Visible := false;
  svgSend.Visible := true;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, FClipBoard) then
    FClipBoard := nil;
  ClearLog;
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

procedure TfrChat.CheckActions(force: boolean);
var
  newLine: integer;
begin
  if force or (FChatPosition <> outHistory.CaretPosition) then begin
    actNext.Enabled := FindQA(outHistory.CaretPosition.Line, +1, newLine);
    actPrevious.Enabled := FindQA(outHistory.CaretPosition.Line, -1, newLine);
  end;
  FChatPosition := outHistory.CaretPosition;
end;

procedure TfrChat.ClearLog;
begin
  actClearHistory.Execute;
  actPrevious.Enabled := false;
  actNext.Enabled := false;
end;

function TfrChat.ExtractReasoning(const response: string;
  var reasoning: string): string;
begin
  if (reasoning <> '') or (not response.StartsWith('<think>')) then
    Exit(response);

  var sl := TStringList.Create;
  try
    sl.Text := response;
    var s2 := TStringList.Create;
    try
      for var i := 1 to sl.Count - 1 do begin
        if sl[i].StartsWith('</think>') then begin
          reasoning := s2.Text;
          s2.Clear;
        end
        else
          s2.Add(sl[i]);
      end;
      Result := s2.Text;
    finally FreeAndNil(s2); end;
  finally FreeAndNil(sl); end;
end;

function TfrChat.FindQA(line, delta: integer; var newLine: integer): boolean;
begin
  repeat
    line := line + delta;
    if (line < 0) or (line >= outHistory.Lines.Count) then
      Exit(false);
    if outHistory.Lines[line].StartsWith(CConversationQuestion)
       or outHistory.Lines[line].StartsWith(CConversationAnswer)
       or outHistory.Lines[line].StartsWith(CConversationReasoning)
    then begin
      newLine := line;
      Exit(true);
    end;
  until false;
end;

procedure TfrChat.JumpInChat(delta: integer);
var
  newLine: integer;
begin
  if not FindQA(outHistory.CaretPosition.Line, delta, newLine) then
    Exit;
  outHistory.CaretPosition := TCaretPosition.Create(newLine, 0);
  ScrollToLine(outHistory, outHistory.CaretPosition.Line);
  CheckActions;
end;

procedure TfrChat.LoadChat(chat: TStrings);
var
  qa    : TAIInteraction;
  inPart: (partQuestion, partAnswer, partReasoning);
begin
  outHistory.Lines.Assign(chat);
  FChat.Clear;
  qa := Default(TAIInteraction);
  inPart := partQuestion;
  for var s in chat do begin
    if SameText(s, CConversationDelimiter) then begin
      FChat.Add(qa);
      qa := Default(TAIInteraction);
    end
    else if s.StartsWith(CConversationQuestion, true) then begin
      inPart := partQuestion;
      qa.Question := s.Remove(0, Length(CConversationQuestion) + 1);
    end
    else if s.StartsWith(CConversationAnswer, true) then begin
      inPart := partAnswer;
      qa.Answer := s.Remove(0, Length(CConversationAnswer) + 1);
    end
    else if s.StartsWith(CConversationReasoning, true) then begin
      inPart := partReasoning;
      qa.Answer := s.Remove(0, Length(CConversationReasoning) + 1);
    end
    else case inPart of
      partQuestion : qa.Question := qa.Question + #$0A + s;
      partAnswer   : qa.Answer := qa.Answer + #$0A + s;
      partReasoning: qa.Reasoning := qa.Reasoning + #$0A + s;
      else raise Exception.Create('Unsupported part: ' + Ord(inPart).ToString);
    end;
  end;
  if qa.Question <> '' then
    FChat.Add(qa);
  CheckActions(true);
end;

procedure TfrChat.outHistoryChange(Sender: TObject);
begin
  CheckActions(true);
end;

procedure TfrChat.outHistoryEnter(Sender: TObject);
begin
  CheckActions;
end;

procedure TfrChat.outHistoryKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
  Shift: TShiftState);
begin
  CheckActions;
end;

procedure TfrChat.outHistoryMouseUp(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single);
begin
  CheckActions;
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

procedure TfrChat.ScrollToLine(memo: TMemo; line: integer);
var
  height: Single;
begin
  var sl := TStringList.Create;
  try
    if line = 0 then
      height := 0
    else begin
      for var i := 0 to line - 1 do
        sl.Add(memo.Lines[i]);
      height := GetLineHeight(outHistory, sl.Text);
    end;
    memo.VScrollBar.Value := height;
  finally FreeAndNil(sl); end;
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
  answer   : string;
  reasoning: string;
begin
  if not FRequest.IsCompleted then
    Exit;

  tmrSend.Enabled := false;

  var errorMsg := FRequest.Error;
  if errorMsg = '' then
    answer := FSerializer.JSONToAnswer(FEngine, FRequest.Response, reasoning, errorMsg);

  if errorMsg <> '' then
    ShowMessage(FEngine.Name + #13#10#13#10'Error : ' + errorMsg)
  else begin
    answer := ExtractReasoning(answer, reasoning).Trim([#13, #10]);
    reasoning := reasoning.Trim([#13, #10]);
    var int := Default(TAIInteraction);
    int.Question := inpQuestion.Text;
    int.Answer := answer;
    int.Reasoning := reasoning;
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
      if reasoning.Trim <> '' then begin
        outHistory.Lines.Add(CConversationReasoning + ' ' + reasoning);
        outHistory.Lines.Add('');
      end;
    finally
      outHistory.Lines.EndUpdate;
    end;
    inpQuestion.Lines.Clear;
    CheckActions(true);
  end;

  FRequest := nil;

  indSend.Visible := false;
  indSend.Enabled := false;
  svgSend.Visible := true;
  btnSend.Action := actSend;
end;

end.
