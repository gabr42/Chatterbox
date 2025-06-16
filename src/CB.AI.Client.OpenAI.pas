unit CB.AI.Client.OpenAI;

interface

implementation

uses
  System.SysUtils, System.StrUtils,
  REST.Json,
  Spring,
  CB.Settings.Types, CB.Network.Types,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.OpenAI.Types;

type
  TOpenAISerializer = class(TInterfacedObject, IAISerializer)
  public
    function URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): TAIResponse;
    function JSONToModels(const json: string; var errorMsg: string): TArray<string>;
  end;

{ TOpenAISerializer }

function TOpenAISerializer.JSONToAnswer(
  const engineConfig: TCBAIEngineSettings; const json: string;
  var errorMsg: string): TAIResponse;
begin
  errorMsg := '';
  Result := Default(TAIResponse);
  try
    var response := TJson.JsonToObject<TOpenAIResponse>(json);
    try
      if not assigned(response) then
        errorMsg := 'Failed to parse JSON response: ' + json
      else if Length(response.choices) > 0 then begin
        Result.Response := response.choices[0].message.content;
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

function TOpenAISerializer.JSONToModels(const json: string;
  var errorMsg: string): TArray<string>;
begin
  errorMsg := '';
  try
    var models := TJson.JsonToObject<TOpenAIModels>(json);
    try
      SetLength(Result, Length(models.data));
      for var iModel := 0 to High(Result) do
        Result[iModel] := models.data[iModel].id;
    finally FreeAndNil(models); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

function TOpenAISerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
var
  request: TOpenAIRequest;
begin
  request := TOpenAIRequest.Create;
  try
    request.model := engineConfig.Model;
    request.max_completion_tokens := engineConfig.MaxTokens;
    request.LoadMessages(IfThen(sendSystemPrompt, engineConfig.SysPrompt.Trim, ''), not engineConfig.Model.StartsWith('o1-', true), history, question);
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TOpenAISerializer.URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
begin
  case purpose of
    qpChat,
    qpHost:    if engineConfig.Host = '' then
                 Result := 'https://api.openai.com/v1/chat/completions'
               else
                 Result := engineConfig.Host;
    qpAPIKeys: Result := 'https://platform.openai.com/api-keys';
    qpModels:  Result := 'https://api.openai.com/v1/models';
    else raise Exception.Create('Unsupported purpose');
  end;
end;

initialization
  GSerializers[etOpenAI] := TOpenAISerializer.Create;
  GNetworkHeaderProvider.Add(etOpenAI, TNetworkHeader.Create('Authorization', 'Bearer ' + CAuthorizationKeyPlaceholder));
end.
