unit CB.AI.Client.Gemini;

interface

implementation

uses
  System.SysUtils,
  REST.Json,
  Spring,
  CB.Settings, CB.Network,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Gemini.Types;

type
  TGeminiSerializer = class(TInterfacedObject, IAISerializer)
  public
    function URL(const engineConfig: TCBAIEngineSettings): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var reasoning, errorMsg: string): string;
  end;

{ TGeminiSerializer }

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
    if engineConfig.MaxTokens > 0 then begin
      request.generationConfig := TGeminiGenerationConfig.Create;
      request.generationConfig.temperature := 1; // TODO : make configurable
      request.generationConfig.maxOutputTokens := engineConfig.MaxTokens;
    end;
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TGeminiSerializer.URL(const engineConfig: TCBAIEngineSettings): string;
begin
  Result := engineConfig.Host;
  if not Result.EndsWith('/') then
    Result := Result + '/';
  Result := Result + 'models/' + engineConfig.Model + ':generateContent?key=' + engineConfig.Authorization;
end;

function TGeminiSerializer.JSONToAnswer(const engineConfig: TCBAIEngineSettings;
  const json: string; var reasoning, errorMsg: string): string;
begin
  errorMsg := '';
  Result := '';
  try
    var response := TJson.JsonToObject<TGeminiResponse>(json);
    try
      if Length(response.candidates) > 0 then begin
        for var part in response.candidates[0].content.parts do begin
          if Result <> '' then
            Result := Result + #$0D#$0A;
          Result := Result + part.text;
        end;
      end;
    finally FreeAndNil(response); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

initialization
  GSerializers[etGemini] := TGeminiSerializer.Create;
  GNetworkHeaderProvider.Add(etGemini, TNetworkHeader.Create('x-api-key', CAuthorizationKeyPlaceholder));
  GNetworkHeaderProvider.Add(etGemini, TNetworkHeader.Create('Gemini-version', '2023-06-01'));
end.
