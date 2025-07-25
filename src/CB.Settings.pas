unit CB.Settings;

interface

uses
  System.UITypes,
  FMX.Dialogs,
  Spring.Collections,
  CB.Settings.Types;

type
  TCBGetPassphraseEvent = procedure(var passphrase: string; var cancel: boolean) of object;

  TCBSettings = class
  strict private
    FOnGetPassphrase: TCBGetPassphraseEvent;
  strict protected
    function  AskForPassphrase(var passphrase: string): boolean;
    function  SingleLine(const s: string): string;
  public
    Passphrase: string;
    AIEngines : IList<TCBAIEngineSettings>;
    constructor Create;
    procedure Save(const fileName: string);
    procedure Load(const fileName: string);
    property OnGetPassphrase: TCBGetPassphraseEvent read FOnGetPassphrase write FOnGetPassphrase;
  end;

implementation

uses
  System.SysUtils, System.IniFiles, System.NetEncoding,
  CB.Encryption;

const
  Key = 'V7YTLI1rNionnj1p4t6kgXgoAEwFXCUirBM0eVewAIBh8zdoi1XlYSNz5WOXHYk3';

var
  SerializeEngineName: array [TCBAIEngineType] of string = ('None', 'Anthropic', 'Ollama', 'OpenAI', 'Gemini', 'DeepSeek');

function Encrypt(const plaintext, key, passphrase: string): string;
begin
  var bytes := EncryptAES(TEncoding.UTF8.GetBytes(plainText), TEncoding.UTF8.GetBytes(key));
  if passphrase <> '' then
    bytes := EncryptAES(bytes, TEncoding.UTF8.GetBytes(passphrase));
  Result := TNetEncoding.Base64.EncodeBytesToString(bytes);
end;

function Decrypt(const cryptext, key, passphrase: string): string;
begin
  var bytes := TNetEncoding.Base64.DecodeStringToBytes(crypText);
  if passphrase <> '' then
    bytes := DecryptAES(bytes, TEncoding.UTF8.GetBytes(passphrase));
  Result := TEncoding.UTF8.GetString(DecryptAES(bytes, TEncoding.UTF8.GetBytes(key)));
end;

{ TCBSettings }

function TCBSettings.AskForPassphrase(var passphrase: string): boolean;
begin
  var cancel: boolean;
  OnGetPassphrase(passphrase, cancel);
  Result := not cancel;
end;

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
    var cryptPassphrase := ini.ReadString('Security', 'Passphrase', '');
    if cryptPassphrase <> '' then begin
      repeat
        var passphrase: string;
        if not AskForPassphrase(passphrase) then
          Exit;
        if DecryptAES(cryptPassphrase, passphrase) = passphrase then begin
          Self.Passphrase := passphrase;
          break //repeat
        end
        else
          ShowMessage('Incorrect passphrase');
      until false;
    end;

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
        auth := Decrypt(auth, Key, Passphrase);
      eng.Authorization := auth;
      eng.Host := ini.ReadString(section, 'Host', '');
      eng.MaxTokens := ini.ReadInteger(section, 'MaxTokens', 2048);
      eng.SysPrompt := ini.ReadString(section, 'SystemPrompt', '');
      eng.IsDefault := ini.ReadInteger(section, 'IsDefault', 0) <> 0;
      eng.NetTimeoutSec := ini.ReadInteger(section, 'NetworkTimeout', 60);
      if ini.ValueExists(section, 'Temperature') then
        eng.Temperature := ini.ReadFloat(section, 'Temperature', 1);
      AIEngines.Add(eng);
      Inc(iEng);
    until false;
  finally FreeAndNil(ini); end;
end;

procedure TCBSettings.Save(const fileName: string);
begin
  var ini := TIniFile.Create(fileName);
  try
    if Passphrase = '' then
      ini.DeleteKey('Security', 'Passphrase')
    else
      ini.WriteString('Security', 'Passphrase', SingleLine(EncryptAES(Passphrase, Passphrase)));

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
      ini.WriteString(section, 'Auth', SingleLine(Encrypt(eng.Authorization, Key, Passphrase)));
      ini.WriteString(section, 'Host', eng.Host);
      ini.WriteInteger(section, 'MaxTokens', eng.MaxTokens);
      ini.WriteString(section, 'SystemPrompt', eng.SysPrompt);
      ini.WriteInteger(section, 'IsDefault', Ord(eng.IsDefault));
      ini.WriteInteger(section, 'NetworkTimeout', eng.NetTimeoutSec);
      if eng.Temperature.HasValue then
        ini.WriteFloat(section, 'Temperature', eng.Temperature)
      else
        ini.DeleteKey(section, 'Temperature');
    end;
  finally FreeAndNil(ini); end;
end;

function TCBSettings.SingleLine(const s: string): string;
begin
  Result := StringReplace(StringReplace(s, #13, '', [rfReplaceAll]), #10, '', [rfReplaceAll]);
end;

end.
