unit CB.Network;

interface

uses
  Spring, Spring.Collections, Spring.Collections.Extensions,
  CB.Settings;

type
  TNetworkHeader = Tuple<string, string>;

  INetAsyncRequest = interface ['{88B1028B-E8D2-47F3-B753-D4A47DA8B35C}']
    function GetError: string;
    function GetResponse: string;
  //
    function IsCompleted: boolean;
    property Response: string read GetResponse;
    property Error: string read GetError;
  end;

function SendAsyncRequest(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string): INetAsyncRequest;

implementation

uses
  System.SysUtils, System.Classes, System.Types,
  System.Net.HttpClient, System.Net.URLClient, System.NetConsts, System.NetEncoding;

type
  TAIAsyncRequest = class(TInterfacedObject, INetAsyncRequest)
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
    constructor Create(const url: string; const headers: IEnumerable<TNetworkHeader>; const request: string);
    destructor  Destroy; override;
    function IsCompleted: boolean;
  end;

function SendAsyncRequest(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string): INetAsyncRequest;
begin
  Result := TAIAsyncRequest.Create(url, headers, request);
end;

{ TAIAsyncRequest }

constructor TAIAsyncRequest.Create(const url: string; const headers: IEnumerable<TNetworkHeader>;
  const request: string);
begin
  FHttpClient := THTTPClient.Create;
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
  if assigned(FHttpAsync) then
    FHttpResponse := THttpClient.EndAsyncHTTP(FHttpAsync);
  if (FHttpResponse.StatusCode div 100) <> 2 then
    Result := FHttpResponse.StatusCode.ToString + ' ' + FHttpResponse.ContentAsString(TEncoding.UTF8);
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

end.
