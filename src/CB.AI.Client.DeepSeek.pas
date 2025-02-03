unit CB.AI.Client.DeepSeek;

interface

implementation

uses
  System.SysUtils, System.StrUtils, System.Classes,
  REST.Json,
  Spring,
  CB.Settings, CB.Network,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.DeepSeek.Types;

type
  TDeepSeekSerializer = class(TInterfacedObject, IAISerializer)
  public
    function URL(const engineConfig: TCBAIEngineSettings): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): TAIResponse;
  end;

{ TDeepSeekSerializer }

function TDeepSeekSerializer.JSONToAnswer(
  const engineConfig: TCBAIEngineSettings; const json: string;
  var errorMsg: string): TAIResponse;
begin
  errorMsg := '';
  Result := Default(TAIResponse);
  try
    var response := TJson.JsonToObject<TDeepSeekResponse>(json);
    try
      if not assigned(response) then
        errorMsg := 'Failed to parse JSON response: ' + json
      else if Length(response.choices) > 0 then begin
        Result.Response := response.choices[0].message.content;
        Result.Reasoning := response.choices[0].message.reasoning_content;
        Result.Done := true;
        Result.DoneReason := response.choices[0].finish_reason;
        Result.PromptTokens := response.usage.prompt_tokens;
        Result.ResponseTokens := response.usage.completion_tokens;
        Result.Model := response.model;
      end;
    finally FreeAndNil(response); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

function TDeepSeekSerializer.QuestionToJSON(
  const engineConfig: TCBAIEngineSettings; const history: TAIChat;
  sendSystemPrompt: boolean; const question: string): string;
var
  request: TDeepSeekRequest;
begin
  request := TDeepSeekRequest.Create;
  try
    request.model := engineConfig.Model;
    request.max_tokens := engineConfig.MaxTokens;
    request.LoadMessages(engineConfig.SysPrompt.Trim, sendSystemPrompt, history, question);
    request.stream := false;
    request.temperature := 0;
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TDeepSeekSerializer.URL(
  const engineConfig: TCBAIEngineSettings): string;
begin
  Result := engineConfig.Host;
end;

initialization
  GSerializers[etDeepSeek] := TDeepSeekSerializer.Create;
  GNetworkHeaderProvider.Add(etDeepSeek, TNetworkHeader.Create('Authorization', 'Bearer ' + CAuthorizationKeyPlaceholder));
end.
