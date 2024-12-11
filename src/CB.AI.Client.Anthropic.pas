unit CB.AI.Client.Anthropic;

interface

implementation

uses
  System.SysUtils,
  REST.Json,
  Spring,
  CB.Settings, CB.Network,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Anthropic.Types;

type
  TAnthropicSerializer = class(TInterfacedObject, IAISerializer)
  public
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): string;
  end;

{ TAnthropicSerializer }

function TAnthropicSerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; const question: string): string;
var
  request: TAnthropicRequest;
begin
  request := TAnthropicRequest.Create;
  try
    request.model := engineConfig.Model;
    request.LoadMessages('', false, history, question);
    request.system := engineConfig.SysPrompt.Trim;
    request.stream := false;
    request.max_tokens := 1024; // TODO : Make configurable
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TAnthropicSerializer.JSONToAnswer(const engineConfig: TCBAIEngineSettings;
  const json: string; var errorMsg: string): string;
begin
  errorMsg := '';
  Result := '';
  try
    var response := TJson.JsonToObject<TAnthropicResponse>(json);
    for var txt in response.content do begin
      if Result <> '' then
        Result := Result + #$0D#$0A;
      Result := Result + txt.text;
    end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

initialization
  GSerializers[etAnthropic] := TAnthropicSerializer.Create;
  GNetworkHeaderProvider.Add(etAnthropic, TNetworkHeader.Create('x-api-key', CAuthorizationKeyPlaceholder));
  GNetworkHeaderProvider.Add(etAnthropic, TNetworkHeader.Create('anthropic-version', '2023-06-01'));
end.
