unit CB.AI.Client.Anthropic;

interface

implementation

uses
  System.SysUtils, System.StrUtils,
  System.JSON,
  REST.Json,
  Spring, Spring.Collections,
  CB.Settings.Types, CB.Network.Types,
  CB.AI.Registry,
  CB.AI.Interaction,
  CB.AI.Client.Anthropic.Types;

type
  TAnthropicSerializer = class(TInterfacedObject, IAISerializer)
  public
    function EngineType: TCBAIEngineType;
    function URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings;
      const history: TAIChat; sendSystemPrompt: boolean; const question: string;
      const outputSchema: string = ''): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings;
      const json: string; var errorMsg: string): TAIResponse;
    function JSONToModels(const json: string; var errorMsg: string): TArray<string>;
  end;

{ TAnthropicSerializer }

function TAnthropicSerializer.EngineType: TCBAIEngineType;
begin
  Result := etAnthropic;
end;

function TAnthropicSerializer.JSONToModels(const json: string;
  var errorMsg: string): TArray<string>;
begin
  errorMsg := '';
  try
    var models := TJson.JsonToObject<TAnthropicModels>(json);
    try
      var lModels := TCollections.CreateList<string>;
      for var iModel := 0 to Length(models.data) - 1 do
        if SameText(models.data[iModel].&type, 'model') then
          lModels.Add(models.data[iModel].id);
      Result := lModels.ToArray;
    finally FreeAndNil(models); end;
  except
    on E: Exception do
      errorMsg := E.Message;
  end;
end;

function TAnthropicSerializer.QuestionToJSON(const engineConfig: TCBAIEngineSettings;
  const history: TAIChat; sendSystemPrompt: boolean; const question: string;
  const outputSchema: string): string;
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
    if outputSchema <> '' then begin
      var tool := TAnthropicTool.Create;
      tool.name := 'JSON_schema';
      tool.description := 'A tool describing the output schema.';
      tool.input_schema := '<([schema])>';
      request.tools := [tool];
    end;
    Result := TJson.ObjectToJsonString(request);
    if outputSchema <> '' then
      Result := StringReplace(Result, '"<([schema])>"', outputSchema, []);
  finally FreeAndNil(request); end;
end;

function TAnthropicSerializer.URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
begin
  case purpose of
    qpChat,
    qpHost:    if engineConfig.Host = '' then
                 Result := 'https://api.anthropic.com/v1/messages'
               else
                 Result := engineConfig.Host;
    qpAPIKeys: Result := 'https://console.anthropic.com/settings/keys';
    qpModels:  Result := 'https://api.anthropic.com/v1/models';
    else raise Exception.Create('Unknown purpose');
  end;
end;

function TAnthropicSerializer.JSONToAnswer(
  const engineConfig: TCBAIEngineSettings; const json: string;
  var errorMsg: string): TAIResponse;
begin
  errorMsg := '';
  Result := Default(TAIResponse);
  try
    var response := TJson.JsonToObject<TAnthropicResponse>(json);
    try
      if not assigned(response) then
        errorMsg := 'Failed to parse JSON response: ' + json
      else if Length(response.content) > 0 then begin
        Result.Done := true;
        Result.DoneReason := response.stop_reason;
        Result.PromptTokens := response.usage.input_tokens;
        Result.ResponseTokens := response.usage.output_tokens;
        Result.Model := response.model;
        for var txt in response.content do
          if txt.name = 'JSON_schema' then begin
            // extract 'input' field
            var js := TJSONObject.ParseJSONValue(json) as TJSONObject;
            if assigned(js) then try
              var contArr := js.GetValue('content') as TJSONArray;
              if assigned(contArr) then begin
                for var contItem in contArr do begin
                  var name := TJSONObject(contItem).GetValue('name');
                  if assigned(name) and (name is TJSONString) and (TJSONString(name).Value = 'JSON_schema') then begin
                    var input := TJSONObject(contItem).GetValue('input');
                    if assigned(input) then begin
                      Result.Response := input.ToString;
                      Exit; // ignore other segments
                    end;
                  end;
                end;
              end;
            finally FreeAndNil(js); end;
          end;

        for var txt in response.content do begin
          if Result.Response <> '' then
            Result.Response := Result.Response + #$0D#$0A;
          Result.Response := Result.Response + txt.text;
        end;
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
