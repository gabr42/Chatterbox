unit CB.Settings;

interface

uses
  Spring.Collections;

type
  TCBAIEngineType = (etNone, etAnthropic, etOllama, etOpenAI, etGemini);

  TCBAIEngineSettings = record
  public
    Name         : string;
    EngineType   : TCBAIEngineType;
    Model        : string;
    Authorization: string;
    Host         : string;
    SysPrompt    : string;
    MaxTokens    : integer;
    IsDefault    : boolean;
    function DisplayName(showDefault: boolean = true): string;
  end;

  TCBSettings = class
  public
    AIEngines: IList<TCBAIEngineSettings>;
    constructor Create;
    procedure Save(const fileName: string);
    procedure Load(const fileName: string);
  end;

var
  CBAIEngineName: array [TCBAIEngineType] of string = ('<none>', 'Anthropic', 'Ollama', 'OpenAI', 'Gemini');

implementation

uses
  System.SysUtils, System.IniFiles, System.NetEncoding,
  CB.Encryption;

const
  Key = 'V7YTLI1rNionnj1p4t6kgXgoAEwFXCUirBM0eVewAIBh8zdoi1XlYSNz5WOXHYk3';

var
  SerializeEngineName: array [TCBAIEngineType] of string = ('None', 'Anthropic', 'Ollama', 'OpenAI', 'Gemini');

{ TCBSettings }

constructor TCBSettings.Create;
begin
  inherited Create;
  AIEngines := TCollections.CreateList<TCBAIEngineSettings>;
end;

procedure TCBSettings.Load(const fileName: string);

  function FindEngineByName(const name: string): TCBAIEngineType;
  begin
    Result := etNone;
    for var engine := Low(TCBAIEngineType) to High(TCBAIEngineType) do
      if SameText(SerializeEngineName[engine], name) then
        Exit(engine);
  end;

begin
  AIEngines.Clear;
  var ini := TIniFile.Create(fileName);
  try
    var iEng := 1;
    repeat
      var section := 'AIEngine_' + iEng.ToString;
      if not ini.SectionExists(section) then
        break; //repeat
      var eng := Default(TCBAIEngineSettings);
      eng.Name := ini.ReadString(section, 'Name', '');
      eng.EngineType := FindEngineByName(ini.ReadString(section, 'Type', ''));
      eng.Model := ini.ReadString(section, 'Model', '');
      var auth := ini.ReadString(section, 'Auth', '');
      if auth <> '' then
        auth := TEncoding.UTF8.GetString(DecryptAES(TNetEncoding.Base64.DecodeStringToBytes(auth), TEncoding.ANSI.GetBytes(Key)));
      eng.Authorization := auth;
      eng.Host := ini.ReadString(section, 'Host', '');
      eng.MaxTokens := ini.ReadInteger(section, 'MaxTokens', 2048);
      eng.SysPrompt := ini.ReadString(section, 'SystemPrompt', '');
      eng.IsDefault := ini.ReadInteger(section, 'IsDefault', 0) <> 0;
      AIEngines.Add(eng);
      Inc(iEng);
    until false;
  finally FreeAndNil(ini); end;
end;

procedure TCBSettings.Save(const fileName: string);
begin
  var ini := TIniFile.Create(fileName);
  try
    var iEng := 1;
    repeat
      var section := 'AIEngine_' + iEng.ToString;
      if not ini.SectionExists(section) then
        break; //repeat
      ini.EraseSection(section);
      Inc(iEng);
    until false;

    for iEng := 0 to AIEngines.Count - 1 do begin
      var eng := AIEngines[iEng];
      var section := 'AIEngine_' + (iEng+1).ToString;
      ini.WriteString(section, 'Name', eng.Name);
      ini.WriteString(section, 'Type', SerializeEngineName[eng.EngineType]);
      ini.WriteString(section, 'Model', eng.Model);
      var auth := TNetEncoding.Base64.EncodeBytesToString(EncryptAES(TEncoding.UTF8.GetBytes(eng.Authorization), TEncoding.ANSI.GetBytes(Key)));
      ini.WriteString(section, 'Auth', StringReplace(StringReplace(auth, #13, '', [rfReplaceAll]), #10, '', [rfReplaceAll]));
      ini.WriteString(section, 'Host', eng.Host);
      ini.WriteInteger(section, 'MaxTokens', eng.MaxTokens);
      ini.WriteString(section, 'SystemPrompt', eng.SysPrompt);
      ini.WriteInteger(section, 'IsDefault', Ord(eng.IsDefault));
    end;
  finally FreeAndNil(ini); end;
end;

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
