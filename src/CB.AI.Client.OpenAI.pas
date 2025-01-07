unit CB.AI.Client.OpenAI;

interface

implementation

uses
  System.SysUtils, System.StrUtils,
  REST.Json,
  Spring,
  CB.Settings, CB.Network,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.OpenAI.Types;

type
  TOpenAISerializer = class(TInterfacedObject, IAISerializer)
  public
    function URL(const engineConfig: TCBAIEngineSettings): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; sendSystemPrompt: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): string;
  end;

{ TOpenAISerializer }

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

function TOpenAISerializer.URL(const engineConfig: TCBAIEngineSettings): string;
begin
  Result := engineConfig.Host;
end;

function TOpenAISerializer.JSONToAnswer(const engineConfig: TCBAIEngineSettings;
  const json: string; var errorMsg: string): string;
begin
  errorMsg := '';
  Result := '';
  try
    var response := TJson.JsonToObject<TOpenAIResponse>(json);
    try
      if Length(response.choices) > 0 then
        Result := response.choices[0].message.content;
    finally FreeAndNil(response); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

initialization
  GSerializers[etOpenAI] := TOpenAISerializer.Create;
  GNetworkHeaderProvider.Add(etOpenAI, TNetworkHeader.Create('Authorization', 'Bearer ' + CAuthorizationKeyPlaceholder));
end.
