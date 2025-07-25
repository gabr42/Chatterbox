unit CB.Network;

interface

uses
  Spring, Spring.Collections, Spring.Collections.Extensions,
  CB.Settings.Types, CB.Network.Types;

type
  INetRequest = interface ['{88B1028B-E8D2-47F3-B753-D4A47DA8B35C}']
    function GetError: string;
    function GetResponse: string;
  //
    procedure Cancel;
    function IsCompleted: boolean;
    property Response: string read GetResponse;
    property Error: string read GetError;
  end;

function MakeHeaders(const engineConfig: TCBAIEngineSettings): IEnumerable<TNetworkHeader>;
function SendAsyncRequest(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string; timeout_sec: integer): INetRequest;
function SendSyncRequest(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string; timeout_sec: integer): INetRequest;

implementation

uses
  System.SysUtils, System.Classes, System.Types, System.Math,
  System.Net.HttpClient, System.Net.URLClient, System.NetConsts, System.NetEncoding,
  CB.AI.Registry;

type
  TAIAsyncRequest = class(TInterfacedObject, INetRequest)
  strict private
    FHttpAsync   : IAsyncResult;
    FHttpClient  : THTTPClient;
    FHttpResponse: IHTTPResponse;
    FPostData    : TStream;
    FResponseData: TStream;
  protected
    function  GetError: string;
    function  GetResponse: string;
  public
    constructor Create(const url: string; const headers: IEnumerable<TNetworkHeader>;
      const request: string; timeout_sec: integer);
    destructor  Destroy; override;
    procedure Cancel;
    function IsCompleted: boolean;
  end;

  TAISyncRequest = class(TInterfacedObject, INetRequest)
  strict private
    FHttpClient  : THTTPClient;
    FHttpResponse: IHTTPResponse;
    FResponseData: TStringStream;
  protected
    function  GetError: string;
    function  GetResponse: string;
  public
    constructor Create(const url: string; const headers: IEnumerable<TNetworkHeader>;
      const request: string; timeout_sec: integer);
    destructor  Destroy; override;
    procedure Cancel;
    function IsCompleted: boolean;
  end;

function MakeHeaders(const engineConfig: TCBAIEngineSettings): IEnumerable<TNetworkHeader>;
begin
  var headers := TCollections.CreateList<TNetworkHeader>;
  for var header in GNetworkHeaderProvider[engineConfig.EngineType] do
    if not header.Value2.Contains(CAuthorizationKeyPlaceholder) then
      headers.Add(header)
    else if engineConfig.Authorization.Trim <> '' then
      headers.Add(TNetworkHeader.Create(header.Value1,
                    StringReplace(header.Value2, CAuthorizationKeyPlaceholder, engineConfig.Authorization, [])));
  Result := headers;
end;

function SendAsyncRequest(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string; timeout_sec: integer): INetRequest;
begin
  Result := TAIAsyncRequest.Create(url, headers, request, timeout_sec);
end;

function SendSyncRequest(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string; timeout_sec: integer): INetRequest;
begin
  Result := TAISyncRequest.Create(url, headers, request, timeout_sec);
end;

{ TAIAsyncRequest }

procedure TAIAsyncRequest.Cancel;
begin
  try
    if assigned(FHttpAsync) then begin
      FHttpAsync.Cancel;
      FHttpResponse := THttpClient.EndAsyncHTTP(FHttpAsync);
    end;
  except
    on E: ENetHTTPClientException do
      ;
  end;
end;

constructor TAIAsyncRequest.Create(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string; timeout_sec: integer);
begin
  FHttpClient := THTTPClient.Create;
  FHttpClient.ResponseTimeout := IfThen(timeout_sec > 0, timeout_sec * 1000, 60 * 1000);
  var netHeaders: TNetHeaders;
  SetLength(netHeaders, 1 + headers.Count);
  netHeaders[0].Name := 'Content-Type';
  netHeaders[0].Value := 'application/json';
  for var zip in TEnumerable.Zip<integer, TNetworkHeader>(TRangeIterator.Create(1, headers.Count), headers) do begin
    netHeaders[zip.Value1].Name :=  zip.Value2.Value1;
    netHeaders[zip.Value1].Value := zip.Value2.Value2;
  end;
  FPostData := TStringStream.Create(request, TEncoding.UTF8);
  FResponseData := TStringStream.Create('', TEncoding.UTF8);
  FHttpAsync := FHttpClient.BeginPost(url, FPostData, FResponseData, netHeaders);
end;

destructor TAIAsyncRequest.Destroy;
begin
  FreeAndNil(FHTTPClient);
  FreeAndNil(FPostData);
  FreeAndNil(FResponseData);
  inherited;
end;

function TAIAsyncRequest.GetError: string;
begin
  Assert(IsCompleted);
  Result := '';
  try
    if assigned(FHttpAsync) then
      FHttpResponse := THttpClient.EndAsyncHTTP(FHttpAsync);
    if (FHttpResponse.StatusCode div 100) <> 2 then
      Result := FHttpResponse.StatusCode.ToString + ' ' + FHttpResponse.ContentAsString(TEncoding.UTF8);
  except
    on E: ENetHTTPClientException do
      Result := E.Message;
  end;
end;

function TAIAsyncRequest.GetResponse: string;
begin
  Assert(IsCompleted);
  if assigned(FHttpAsync) then
    FHttpResponse := THttpClient.EndAsyncHTTP(FHttpAsync);
  Result := FHttpResponse.ContentAsString(TEncoding.UTF8);
end;

function TAIAsyncRequest.IsCompleted: boolean;
begin
  Result := (not assigned(FHttpAsync)) or FHttpAsync.IsCompleted;
end;

{ TAISyncRequest }

constructor TAISyncRequest.Create(const url: string;
  const headers: IEnumerable<TNetworkHeader>; const request: string;
  timeout_sec: integer);
begin
  inherited Create;
  FHttpClient := THTTPClient.Create;
  FHttpClient.ResponseTimeout := IfThen(timeout_sec > 0, timeout_sec * 1000, 60 * 1000);
  var netHeaders: TNetHeaders;
  SetLength(netHeaders, 1 + headers.Count);
  netHeaders[0].Name := 'Content-Type';
  netHeaders[0].Value := 'application/json';
  for var zip in TEnumerable.Zip<integer, TNetworkHeader>(TRangeIterator.Create(1, headers.Count), headers) do begin
    netHeaders[zip.Value1].Name :=  zip.Value2.Value1;
    netHeaders[zip.Value1].Value := zip.Value2.Value2;
  end;
  FResponseData := TStringStream.Create('', TEncoding.UTF8);
  if request = '' then
    FHttpResponse := FHttpClient.Get(url, FResponseData, netHeaders)
  else begin
    var postData := TStringStream.Create(request, TEncoding.UTF8);
    try
      FHttpResponse := FHttpClient.Post(url, postData, FResponseData, netHeaders);
    finally FreeAndNil(postData); end;
  end;
end;

destructor TAISyncRequest.Destroy;
begin
  FreeAndNil(FHttpClient);
  FreeAndNil(FResponseData);
  inherited;
end;

procedure TAISyncRequest.Cancel;
begin
  // Nothing to do
end;

function TAISyncRequest.GetError: string;
begin
  if (FHttpResponse.StatusCode div 100) <> 2 then
    Result := FHttpResponse.StatusCode.ToString + ' ' + FHttpResponse.ContentAsString(TEncoding.UTF8);
end;

function TAISyncRequest.GetResponse: string;
begin
  Result := FHttpResponse.ContentAsString(TEncoding.UTF8);
end;

function TAISyncRequest.IsCompleted: boolean;
begin
  Result := true;
end;

end.
