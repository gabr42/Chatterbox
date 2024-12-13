unit CB.Encryption;

// Requires:
// - https://github.com/Dunhamb4a/DcPCryptV2
// - https://github.com/Delphier/TAES

interface

uses
  System.SysUtils, System.IOUtils, System.NetEncoding;

function EncryptAES(const plainText, key: TBytes): TBytes; overload;
function EncryptAES(const plainText, key: string): string; overload;
function DecryptAES(const crypText, key: TBytes): TBytes; overload;
function DecryptAES(const crypText, key: string): string; overload;

implementation

uses
  DCPrijndael,
  Prism.Crypto.AES;

function EncryptAES(const plainText, key: TBytes): TBytes;
var
  guid: TGUID;
begin
  var keyBytes := key + key + key + key;
  if Length(keyBytes) > TDCP_rijndael.GetMaxKeySize then
    keyBytes := Copy(keyBytes, 1, TDCP_rijndael.GetMaxKeySize);
  CreateGuid(guid);
  var IVBytes := Guid.ToByteArray;
  var encBytes := TAES.Encrypt(plainText, keyBytes, Length(keyBytes), IVbytes, cmCBC, pmPKCS7);
  Result := IVBytes + encBytes;
end;

function EncryptAES(const plainText, key: string): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(
              EncryptAES(TEncoding.UTF8.GetBytes(plainText),
                         TEncoding.UTF8.GetBytes(key)));
end;

function DecryptAES(const crypText, key: TBytes): TBytes;
begin
  var keyBytes := key + key + key + key;
  if Length(keyBytes) > TDCP_rijndael.GetMaxKeySize then
    keyBytes := Copy(keyBytes, 1, TDCP_rijndael.GetMaxKeySize);
  var IVBytes := Copy(crypText, 0, 16);
  try
    Result := TAES.Decrypt(Copy(crypText, 16), keyBytes, Length(keyBytes), IVBytes, cmCBC, pmPKCS7);
  except // can happen when key is incorrect
    Result := nil;
  end;
end;

function DecryptAES(const crypText, key: string): string;
begin
  Result := TEncoding.UTF8.GetString(
              DecryptAES(TNetEncoding.Base64.DecodeStringToBytes(crypText),
                         TEncoding.UTF8.GetBytes(key)));
end;


end.

