unit CB.Encryption;

// Requires:
// - https://github.com/Dunhamb4a/DcPCryptV2
// - https://github.com/Delphier/TAES

interface

uses
  System.SysUtils, System.IOUtils;

function EncryptAES(const plainText, key: TBytes): TBytes;
function DecryptAES(const crypText, key: TBytes): TBytes;

implementation

uses
  Prism.Crypto.AES;

function EncryptAES(const plainText, key: TBytes): TBytes;
var
  guid: TGUID;
begin
  var keyBytes := key + key + key + key;
  CreateGuid(guid);
  var IVBytes := Guid.ToByteArray;
  var encBytes := TAES.Encrypt(plainText, keyBytes, Length(keyBytes), IVbytes, cmCBC, pmPKCS7);
  Result := IVBytes + encBytes;
end;

function DecryptAES(const crypText, key: TBytes): TBytes;
begin
  var keyBytes := key + key + key + key;
  var IVBytes := Copy(crypText, 0, 16);
  Result := TAES.Decrypt(Copy(crypText, 16), keyBytes, Length(keyBytes), IVBytes, cmCBC, pmPKCS7);
end;

end.

