unit engineDemoMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  System.Net.HttpClient, System.Net.URLClient,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Spring.Collections,
  CB.Settings.Types, CB.AI.Interaction, CB.AI.Registry, CB.Network.Types;

type
  TfrmEngineDemo = class(TForm)
    lblEngineType: TLabel;
    cbxEngineType: TComboBox;
    lblAPIKey: TLabel;
    inpAPIKey: TEdit;
    lblMode: TLabel;
    inpModel: TEdit;
    btnListModels: TButton;
    inpURL: TEdit;
    Label1: TLabel;
    btnGetAPIKey: TButton;
    lblQuery: TLabel;
    inpQuery: TMemo;
    btnRunQuery: TButton;
    outResponse: TMemo;
    lblResponse: TLabel;
    procedure btnGetAPIKeyClick(Sender: TObject);
    procedure btnListModelsClick(Sender: TObject);
    procedure btnRunQueryClick(Sender: TObject);
    procedure cbxEngineTypeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSerializer: IAISerializer;
    function EngineConfig: TCBAIEngineSettings;
    function ExecuteHttp(const url, body: string; const headers: TNetHeaders): IHTTPResponse;
    function MakeHeaders: TNetHeaders;
  public
  end;

var
  frmEngineDemo: TfrmEngineDemo;

implementation

uses
  ShellAPI,
  engineDemo.SelectModelDlg;

{$R *.dfm}

procedure TfrmEngineDemo.btnGetAPIKeyClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(FSerializer.URL(EngineConfig, qpAPIKeys)), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmEngineDemo.btnListModelsClick(Sender: TObject);
var
  errorMsg: string;
begin
  var response := ExecuteHttp(FSerializer.URL(EngineConfig, qpModels), '', MakeHeaders);
  if (response.StatusCode div 100) <> 2 then
    ShowMessage(response.ContentAsString)
  else begin
    var models := FSerializer.JSONToModels(response.ContentAsString, errorMsg);
    if errorMsg <> '' then
      ShowMessage(errorMsg)
    else begin
      var selector := TfrmSelectModel.Create(Self);
      try
        selector.lbModels.Items.AddStrings(models);
        if (selector.ShowModal = mrOK) and (selector.lbModels.ItemIndex >= 0) then
          inpModel.Text := selector.lbModels.Items[selector.lbModels.ItemIndex];
      finally FreeAndNil(selector); end;
    end;
  end;
end;

procedure TfrmEngineDemo.btnRunQueryClick(Sender: TObject);
var
  errorMsg: string;
begin
  var response := ExecuteHttp(FSerializer.URL(EngineConfig, qpChat),
                    FSerializer.QuestionToJSON(EngineConfig, [], false, inpQuery.Text),
                    MakeHeaders);
  if (response.StatusCode div 100) <> 2 then
    ShowMessage(response.ContentAsString)
  else begin
    var answer := FSerializer.JSONToAnswer(EngineConfig, response.ContentAsString, errorMsg);
    if errorMsg <> '' then
      ShowMessage(errorMsg)
    else
      outResponse.Text := StringReplace(answer.Response, #10, #13#10, [rfReplaceAll]);
  end;
end;

procedure TfrmEngineDemo.cbxEngineTypeChange(Sender: TObject);
begin
  var engine := EngineType(cbxEngineType.Text);
  if assigned(FSerializer) and (FSerializer.EngineType <> engine) then
    inpURL.Text := '';
  FSerializer := GSerializers[engine];
  inpURL.Text := FSerializer.URL(EngineConfig, qpHost);
  btnListModels.Enabled := FSerializer.URL(EngineConfig, qpModels) <> '';
  btnGetAPIKey.Enabled := FSerializer.URL(EngineConfig, qpAPIKeys) <> '';
end;

function TfrmEngineDemo.EngineConfig: TCBAIEngineSettings;
begin
  Result := Default(TCBAIEngineSettings);
  Result.Name := cbxEngineType.Text;
  Result.Model := inpModel.Text;
  Result.Authorization := inpAPIKey.Text;
  Result.Host := inpURL.Text;
  Result.MaxTokens := 4096;
end;

function TfrmEngineDemo.ExecuteHttp(const url, body: string;
  const headers: TNetHeaders): IHTTPResponse;
begin
  var client := THTTPClient.Create;
  if body = '' then
    Result := Client.Get(url, nil, headers)
  else begin
    var postBody := TStringStream.Create(body, TEncoding.UTF8);
    try
      Result := Client.Post(url, postBody, nil, headers);
    finally FreeAndNil(postBody); end;
  end;
end;

procedure TfrmEngineDemo.FormCreate(Sender: TObject);
begin
  for var serializer in GSerializers do
    cbxEngineType.Items.Add(CBAIEngineName[serializer.Key]);
  cbxEngineType.ItemIndex := 0;
  cbxEngineTypeChange(nil);
end;

function TfrmEngineDemo.MakeHeaders: TNetHeaders;
begin
  var headers := TCollections.CreateList<TNameValuePair>;
  headers.Add(TNameValuePair.Create('Content-type', 'application/json'));
  for var hdr in GNetworkHeaderProvider[FSerializer.EngineType] do
    headers.Add(TNameValuePair.Create(hdr.Value1, StringReplace(hdr.Value2, CAuthorizationKeyPlaceholder, inpAPIKey.Text, [])));
  Result := headers.ToArray;
end;

end.
