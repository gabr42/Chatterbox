unit CB.AI.Client.Ollama;

interface

implementation

uses
  System.SysUtils, System.StrUtils,
  REST.Json,
  Spring,
  CB.Settings, CB.Network,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Ollama.Types;

type
  TOllamaSerializer = class(TInterfacedObject, IAISerializer)
  public
    function URL(const engineConfig: TCBAIEngineSettings): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): string;
  end;

{ TOllamaSerializer }

function TOllamaSerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
var
  request: TOllamaRequest;
begin
  request := TOllamaRequest.Create;
  try
    request.model := engineConfig.Model;
    request.max_tokens := engineConfig.MaxTokens;
    request.stream := false;
    request.LoadMessages(IfThen(sendSystemPrompt, engineConfig.SysPrompt.Trim, ''), false, history, question);
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TOllamaSerializer.URL(const engineConfig: TCBAIEngineSettings): string;
begin
  Result := engineConfig.Host;
end;

function TOllamaSerializer.JSONToAnswer(const engineConfig: TCBAIEngineSettings;
  const json: string; var errorMsg: string): string;
begin
  errorMsg := '';
  Result := '';
  try
    var response := TJson.JsonToObject<TOllamaResponse>(json);
    try
      Result := response.message.content;
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
