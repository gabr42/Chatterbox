unit CB.Settings;

interface

uses
  Spring.Collections;

type
  TCBAIEngineType = (etNone, etOpenAI, etOllama); // etGemini, etClaude

  TCBAIEngineSettings = record
  public
    Name         : string;
    EngineType   : TCBAIEngineType;
    Model        : string;
    Authorization: string;
    Host         : string;
    SysPrompt    : string;
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
  CBAIEngineName: array [TCBAIEngineType] of string = ('<none>', 'OpenAI', 'Ollama');

implementation

uses
  System.SysUtils, System.IniFiles, System.NetEncoding,
  CB.Encryption;

const
  Key = 'V7YTLI1rNionnj1p4t6kgXgoAEwFXCUirBM0eVewAIBh8zdoi1XlYSNz5WOXHYk3';

{ TCBSettings }

constructor TCBSettings.Create;
begin
  inherited Create;
  AIEngines := TCollections.CreateList<TCBAIEngineSettings>;
end;

procedure TCBSettings.Load(const fileName: string);
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
      eng.EngineType := TCBAIEngineType(ini.ReadInteger(section, 'Type', 0));
      eng.Model := ini.ReadString(section, 'Model', '');
      var auth := ini.ReadString(section, 'Auth', '');
      if auth <> '' then
        auth := TEncoding.UTF8.GetString(DecryptAES(TNetEncoding.Base64.DecodeStringToBytes(auth), TEncoding.ANSI.GetBytes(Key)));
      eng.Authorization := auth;
      eng.Host := ini.ReadString(section, 'Host', '');
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
    for var iEng := 0 to AIEngines.Count - 1 do begin
      var eng := AIEngines[iEng];
      var section := 'AIEngine_' + (iEng+1).ToString;
      ini.WriteString(section, 'Name', eng.Name);
      ini.WriteInteger(section, 'Type', Ord(eng.EngineType));
      ini.WriteString(section, 'Model', eng.Model);
      var auth := TNetEncoding.Base64.EncodeBytesToString(EncryptAES(TEncoding.UTF8.GetBytes(eng.Authorization), TEncoding.ANSI.GetBytes(Key)));
      ini.WriteString(section, 'Auth', StringReplace(StringReplace(auth, #13, '', [rfReplaceAll]), #10, '', [rfReplaceAll]));
      ini.WriteString(section, 'Host', eng.Host);
      ini.WriteString(section, 'SystemPrompt', eng.SysPrompt);
      ini.WriteInteger(section, 'IsDefault', Ord(eng.IsDefault));
    end;

    var iEng := AIEngines.Count;
    repeat
      var section := 'AIEngine_' + (iEng+1).ToString;
      if not ini.SectionExists(section) then
        break; //repeat
      ini.EraseSection(section);
      Inc(iEng);
    until false;
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
