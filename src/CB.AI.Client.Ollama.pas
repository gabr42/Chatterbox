unit CB.AI.Client.Ollama;

interface

implementation

uses
  System.SysUtils,
  REST.Json,
  CB.Settings,
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
    SetLength(request.Messages, 2*Length(history) + 1);
    var iMsg := 0;
    for var iHistory := 0 to High(history) do begin
      request.Messages[iMsg] := TOllamaMessage.Create;
      request.Messages[iMsg].role := 'user';
      request.Messages[iMsg].content := history[iHistory].Question;
      request.Messages[iMsg+1] := TOllamaMessage.Create;
      request.Messages[iMsg+1].role := 'assistant';
      request.Messages[iMsg+1].content := history[iHistory].Answer;
      Inc(iMsg, 2);
    end;
    request.Messages[iMsg] := TOllamaMessage.Create;
    request.Messages[iMsg].role := 'user';
    request.Messages[iMsg].content := question;
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
end.
