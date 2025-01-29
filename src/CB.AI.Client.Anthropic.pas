unit CB.AI.Client.Anthropic;

interface

implementation

uses
  System.SysUtils, System.StrUtils,
  REST.Json,
  Spring,
  CB.Settings, CB.Network,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Anthropic.Types;

type
  TAnthropicSerializer = class(TInterfacedObject, IAISerializer)
  public
    function URL(const engineConfig: TCBAIEngineSettings): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var reasoning, errorMsg: string): string;
  end;

{ TAnthropicSerializer }

function TAnthropicSerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
var
  request: TAnthropicRequest;
begin
  request := TAnthropicRequest.Create;
  try
    request.model := engineConfig.Model;
    request.LoadMessages('', false, history, question);
    request.system := IfThen(sendSystemPrompt, engineConfig.SysPrompt.Trim, '');
    request.max_tokens := engineConfig.MaxTokens;
    request.stream := false;
    Result := TJson.ObjectToJsonString(request);
  finally FreeAndNil(request); end;
end;

function TAnthropicSerializer.URL(const engineConfig: TCBAIEngineSettings): string;
begin
  Result := engineConfig.Host;
end;

function TAnthropicSerializer.JSONToAnswer(const engineConfig: TCBAIEngineSettings;
  const json: string; var reasoning, errorMsg: string): string;
begin
  errorMsg := '';
  Result := '';
  try
    var response := TJson.JsonToObject<TAnthropicResponse>(json);
    try
      for var txt in response.content do begin
        if Result <> '' then
          Result := Result + #$0D#$0A;
        Result := Result + txt.text;
      end;
    finally FreeAndNil(response); end;
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
