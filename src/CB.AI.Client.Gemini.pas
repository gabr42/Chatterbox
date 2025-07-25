unit CB.AI.Client.Gemini;

interface

implementation

uses
  System.SysUtils, System.Math,
  REST.Json,
  Spring,
  CB.Settings.Types, CB.Network.Types,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Gemini.Types;

type
  TGeminiSerializer = class(TInterfacedObject, IAISerializer)
  public
    function EngineType: TCBAIEngineType;
    function URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings;
      const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings;
      const json: string; var errorMsg: string): TAIResponse;
    function JSONToModels(const json: string; var errorMsg: string): TArray<string>;
  end;

{ TGeminiSerializer }

function TGeminiSerializer.EngineType: TCBAIEngineType;
begin
  Result := etGemini;
end;

function TGeminiSerializer.JSONToAnswer(
  const engineConfig: TCBAIEngineSettings; const json: string;
  var errorMsg: string): TAIResponse;
begin
  errorMsg := '';
  Result := Default(TAIResponse);
  try
    var response := TJson.JsonToObject<TGeminiResponse>(json);
    try
      if not assigned(response) then
        errorMsg := 'Failed to parse JSON response: ' + json
      else if Length(response.candidates) > 0 then begin
        Result.Done := true;
        Result.DoneReason := response.candidates[0].finishReason;
        Result.PromptTokens := response.usageMetadata.promptTokenCount;
        Result.ResponseTokens := response.usageMetadata.candidatesTokenCount;
        Result.Model := response.modelVersion;
        for var part in response.candidates[0].content.parts do begin
          if Result.Response <> '' then
            Result.Response := Result.Response + #$0D#$0A;
          Result.Response := Result.Response + part.text;
        end;
      end;
    finally FreeAndNil(response); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

function TGeminiSerializer.JSONToModels(const json: string;
  var errorMsg: string): TArray<string>;
begin
  errorMsg := '';
  try
    var models := TJson.JsonToObject<TGeminiModels>(json);
    try
      SetLength(Result, Length(models.models));
      for var iModel := 0 to High(Result) do begin
        Result[iModel] := models.models[iModel].name;
        if Result[iModel].StartsWith('models/', true) then
          Result[iModel] := Copy(Result[iModel], Length('models/') + 1);
      end;
    finally FreeAndNil(models); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

function TGeminiSerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
var
  request : TGeminiRequest;
  messages: TArray<TGeminiMessage>;
begin
  request := TGeminiRequest.Create;
  try
    var sysPrompt := engineConfig.SysPrompt.Trim;
    if sendSystemPrompt and (sysPrompt <> '') then begin
      request.system_instruction := TGeminiParts.Create;
      request.system_instruction.parts := TArray<TGeminiPart>.Create(TGeminiPart.Create(sysPrompt));
    end;
    SetLength(messages, 2*Length(history) + 1);
    var iMsg := 0;
    for var iHistory := 0 to High(history) do begin
      messages[iMsg] := TGeminiMessage.Create('user', history[iHistory].Question);
      messages[iMsg+1] := TGeminiMessage.Create('model', history[iHistory].Answer);
      Inc(iMsg, 2);
    end;
    messages[iMsg] := TGeminiMessage.Create('user', question);
    request.contents := messages;
    if engineConfig.Temperature.HasValue or (engineConfig.MaxTokens > 0) or (engineConfig.OutputSchema <> '') then begin
      request.generationConfig := TGeminiGenerationConfig.Create;
      if engineConfig.Temperature.HasValue then
        request.generationConfig.temperature := engineConfig.Temperature
      else
        request.generationConfig.temperature := 1;
      request.generationConfig.maxOutputTokens := IfThen(engineConfig.MaxTokens = 0, 4096, engineConfig.MaxTokens);
      if engineConfig.OutputSchema = '' then
        request.generationConfig.responseMimeType := 'text/plain'
      else begin
        request.generationConfig.responseMimeType := 'application/json';
        request.generationConfig.responseSchema := '<([schema])>';
      end;
    end;
    Result := TJson.ObjectToJsonString(request, TJson.CDefaultOptions + [joIgnoreEmptyStrings, joIgnoreEmptyArrays]);
    if engineConfig.OutputSchema <> '' then
      Result := StringReplace(Result, '"<([schema])>"', engineConfig.OutputSchema, []);
  finally FreeAndNil(request); end;
end;

function TGeminiSerializer.URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
begin
  case purpose of
    qpHost:    if engineConfig.Host = '' then
                 Result := 'https://generativelanguage.googleapis.com/v1beta/'
               else
                 Result := engineConfig.Host;

    qpChat: begin
      Result := URL(engineConfig, qpHost);
      if not Result.EndsWith('/') then
        Result := Result + '/';
      Result := Result + 'models/' + engineConfig.Model + ':generateContent?key=' + engineConfig.Authorization;
    end;
    qpAPIKeys: Result := 'https://aistudio.google.com/app/apikey';
    qpModels: Result := 'https://generativelanguage.googleapis.com/v1beta/models?key=' + engineConfig.Authorization;
    else raise Exception.Create('Unexpected purpose');
  end;
end;

initialization
  GSerializers[etGemini] := TGeminiSerializer.Create;
  GNetworkHeaderProvider.Add(etGemini, TNetworkHeader.Create('x-api-key', CAuthorizationKeyPlaceholder));
  GNetworkHeaderProvider.Add(etGemini, TNetworkHeader.Create('Gemini-version', '2023-06-01'));
end.
