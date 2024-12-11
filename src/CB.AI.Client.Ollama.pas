unit CB.AI.Client.Ollama;

interface

implementation

uses
  System.SysUtils,
  REST.Json,
  Spring,
  CB.Settings, CB.Network,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Ollama.Types;

type
  TOllamaSerializer = class(TInterfacedObject, IAISerializer)
  public
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): string;
  end;

{ TOllamaSerializer }

function TOllamaSerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; const question: string): string;
var
  request: TOllamaRequest;
begin
  request := TOllamaRequest.Create;
  try
    request.Model := engineConfig.Model;
    request.LoadMessages(engineConfig.SysPrompt.Trim, false, history, question);
    request.Stream := false;
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TOllamaSerializer.JSONToAnswer(const engineConfig: TCBAIEngineSettings;
  const json: string; var errorMsg: string): string;
begin
  errorMsg := '';
  Result := '';
  try
    var response := TJson.JsonToObject<TOllamaResponse>(json);
    Result := response.message.content;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

initialization
  GSerializers[etOllama] := TOllamaSerializer.Create;
  GNetworkHeaderProvider.Add(etOllama, TNetworkHeader.Create('Authorization', 'Bearer ' + CAuthorizationKeyPlaceholder));
end.
