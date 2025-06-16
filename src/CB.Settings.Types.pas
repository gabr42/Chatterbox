unit CB.Settings.Types;

interface

type
  TCBAIEngineType = (etNone, etAnthropic, etOllama, etOpenAI, etGemini, etDeepSeek);

  TCBAIEngineSettings = record
  public
    Name         : string;
    EngineType   : TCBAIEngineType;
    Model        : string;
    Authorization: string;
    Host         : string;
    SysPrompt    : string;
    MaxTokens    : integer;
    NetTimeoutSec: integer;
    IsDefault    : boolean;
    function DisplayName(showDefault: boolean = true): string;
  end;

var
  CBAIEngineName: array [TCBAIEngineType] of string = ('<none>', 'Anthropic', 'Ollama', 'OpenAI', 'Gemini', 'DeepSeek');

implementation

{ TCBAIEngineSettings }

function TCBAIEngineSettings.DisplayName(showDefault: boolean): string;
begin
  if Name <> '' then
    Result := Name
  else
    Result := CBAIEngineName[EngineType] + '/' + Model;
  if Result = '' then
    Result := '<empty>'
  else if showDefault and IsDefault then
    Result := '* ' + Result;
end;

end.
