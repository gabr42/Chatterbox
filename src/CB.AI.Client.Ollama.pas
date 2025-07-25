unit CB.AI.Client.Ollama;

interface

implementation

uses
  System.SysUtils, System.StrUtils,
  REST.Json,
  Spring,
  CB.Utils, CB.Settings.Types, CB.Network.Types,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Ollama.Types;

type
  TOllamaSerializer = class(TInterfacedObject, IAISerializer)
  public
    function EngineType: TCBAIEngineType;
    function URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings;
      const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings;
      const json: string; var errorMsg: string): TAIResponse;
    function JSONToModels(const json: string; var errorMsg: string): TArray<string>;
  end;

{ TOllamaSerializer }

function TOllamaSerializer.EngineType: TCBAIEngineType;
begin
  Result := etOllama;
end;

function TOllamaSerializer.JSONToModels(const json: string;
  var errorMsg: string): TArray<string>;
begin
  errorMsg := '';
  try
    var models := TJson.JsonToObject<TOllamaModels>(json);
    try
      SetLength(Result, Length(models.models));
      for var iModel := 0 to High(Result) do
        Result[iModel] := models.models[iModel].model;
    finally FreeAndNil(models); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

function TOllamaSerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; sendSystemPrompt: boolean;
  const question: string): string;
var
  request: TOllamaRequest;
begin
  request := TOllamaRequest.Create;
  try
    request.model := engineConfig.Model;
    request.max_tokens := engineConfig.MaxTokens;
    request.stream := false;
    request.LoadMessages(IfThen(sendSystemPrompt, engineConfig.SysPrompt.Trim, ''), false, history, question);
    if engineConfig.OutputSchema <> '' then begin
      request.response_format := TOllamaResponseFormat.Create;
      request.response_format.&type := 'json_schema';
      request.response_format.json_schema := '<([json_schema])>';
    end;
    if engineConfig.Temperature.HasValue then
      request.temperature := engineConfig.Temperature
    else
      request.temperature := 1;
    Result := TJson.ObjectToJsonString(request, TJson.CDefaultOptions + [joIgnoreEmptyStrings, joIgnoreEmptyArrays]);
    if engineConfig.OutputSchema <> '' then begin
      var schema := TOllamaJsonSchema.Create;
      try
        schema.name := 'JSON_schema';
        schema.schema := '<([schema])>';
        Result := StringReplace(Result, '"<([json_schema])>"', TJson.ObjectToJsonString(schema), []);
        Result := StringReplace(Result, '"<([schema])>"', engineConfig.OutputSchema, []);
      finally FreeAndNil(schema); end;
    end;
  finally FreeAndNil(request); end;
end;

function TOllamaSerializer.URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
begin
  case purpose of
    qpChat,
    qpHost:    if engineConfig.Host = '' then
                 Result := 'http://localhost:11434/api/chat'
               else
                 Result := engineConfig.Host;
    qpAPIKeys: Result := '';
    qpModels:  Result := FirstPartEndingWith(URL(engineConfig, qpHost), '/api/') + 'tags';
  end;
end;

function TOllamaSerializer.JSONToAnswer(
  const engineConfig: TCBAIEngineSettings; const json: string;
  var errorMsg: string): TAIResponse;
begin
  errorMsg := '';
  Result := Default(TAIResponse);
  try
    var response := TJson.JsonToObject<TOllamaResponse>(json);
    try
      if not assigned(response) then
        errorMsg := 'Failed to parse JSON response: ' + json
      else begin
        Result.Response := response.message.content;
        Result.Done := response.done;
        Result.DoneReason := response.done_reason;
        Result.Duration_ms := Round(response.total_duration / 1_000_000);
        Result.PromptTokens := response.prompt_eval_count;
        Result.ResponseTokens := response.eval_count;
        Result.Model := response.model;
      end;
    finally FreeAndNil(response); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

initialization
  GSerializers[etOllama] := TOllamaSerializer.Create;
  GNetworkHeaderProvider.Add(etOllama, TNetworkHeader.Create('Authorization', 'Bearer ' + CAuthorizationKeyPlaceholder));
end.
