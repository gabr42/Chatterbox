unit CB.AI.Client.OpenAI;

interface

implementation

uses
  System.SysUtils,
  REST.Json,
  CB.Settings,
  CB.AI.Interaction,
  CB.AI.Client.OpenAI.Types;

type
  TOpenAISerializer = class(TInterfacedObject, IAISerializer)
  public
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): string;
  end;

{ TOpenAISerializer }

function TOpenAISerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; const question: string): string;
var
  request: TOpenAIRequest;
begin
  request := TOpenAIRequest.Create;
  try
    request.Model := engineConfig.Model;
    var sysPrompt := engineConfig.SysPrompt.Trim;
    var iso1 := engineConfig.Model.StartsWith('o1-', true);
    SetLength(request.Messages, 2*Length(history) + 1 + Ord(sysPrompt <> ''));
    var iMsg := 0;
    if (sysPrompt <> '') and (not iso1) then begin
      request.Messages[iMsg] := TOpenAIMessage.Create;
      request.Messages[iMsg].role := 'system';
      request.Messages[iMsg].content := sysPrompt.Trim;
      Inc(iMsg);
    end;
    for var iHistory := 0 to High(history) do begin
      request.Messages[iMsg] := TOpenAIMessage.Create;
      request.Messages[iMsg].role := 'user';
      request.Messages[iMsg].content := history[iHistory].Question;
      request.Messages[iMsg+1] := TOpenAIMessage.Create;
      request.Messages[iMsg+1].role := 'assistant';
      request.Messages[iMsg+1].content := history[iHistory].Answer;
      Inc(iMsg, 2);
    end;
    if (sysPrompt <> '') and iso1 then begin
      request.Messages[iMsg] := TOpenAIMessage.Create;
      request.Messages[iMsg].role := 'user';
      request.Messages[iMsg].content := sysPrompt.Trim;
      Inc(iMsg);
    end;
    request.Messages[iMsg] := TOpenAIMessage.Create;
    request.Messages[iMsg].role := 'user';
    request.Messages[iMsg].content := question;
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TOpenAISerializer.JSONToAnswer(const engineConfig: TCBAIEngineSettings;
  const json: string; var errorMsg: string): string;
begin
  errorMsg := '';
  Result := '';
  try
    var response := TJson.JsonToObject<TOpenAIResponse>(json);
    if Length(response.choices) > 0 then
      Result := response.choices[0].message.content;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

initialization
  GSerializers[etOpenAI] := TOpenAISerializer.Create;
end.
