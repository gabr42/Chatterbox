unit CB.AI.Client.Gemini.Types;

interface

{$M+}
type
  // https://ai.google.dev/gemini-api/docs/text-generation?lang=rest

  TGeminiPart = class
  public
    text: string;
    constructor Create(const AText: string);
  end;

  TGeminiMessage = class
  public
    role : string;
    parts: TArray<TGeminiPart>;
    constructor Create(const ARole, AText: string);
    destructor Destroy; override;
  end;

  TGeminiParts = class
  public
    parts: TArray<TGeminiPart>;
    destructor Destroy; override;
  end;

  TGeminiRequest = class
  public
    system_instruction: TGeminiParts;
    contents: TArray<TGeminiMessage>;
    destructor Destroy; override;
  end;

  TGeminiResponseContent = class
  public
    role : string;
    parts: TArray<TGeminiPart>;
    destructor Destroy; override;
  end;

  TGeminiUsage = class
  public
    promptTokenCount    : integer;
    candidatesTokenCount: integer;
    totalTokenCount     : integer;
  end;

  TGeminiCandidate = class
  public
    content      : TGeminiResponseContent;
    finishReason : string;
    destructor Destroy; override;
  end;

  TGeminiResponse = class
  public
    candidates   : TArray<TGeminiCandidate>;
    usageMetadata: TGeminiUsage;
    modelVersion : string;
    destructor Destroy; override;
  end;
{$M-}

implementation

uses
  System.SysUtils;

{ TGeminiPart }

constructor TGeminiPart.Create(const AText: string);
begin
  inherited Create;
  text := AText;
end;

{ TGeminiMessage }

constructor TGeminiMessage.Create(const ARole, AText: string);
begin
  inherited Create;
  role := ARole;
  SetLength(parts, 1);
  parts[0] := TGeminiPart.Create(AText);
end;

destructor TGeminiMessage.Destroy;
begin
  for var part in parts do
    part.Free;
  inherited;
end;

{ TGeminiParts }

destructor TGeminiParts.Destroy;
begin
  for var part in parts do
    part.Free;
  inherited;
end;

{ TGeminiRequest }

destructor TGeminiRequest.Destroy;
begin
  FreeAndNil(system_instruction);
  for var content in contents do
    content.Free;
  inherited;
end;

{ TGeminiResponseContent }

destructor TGeminiResponseContent.Destroy;
begin
  for var part in parts do
    part.Free;
  inherited;
end;

{ TGeminiCandidate }

destructor TGeminiCandidate.Destroy;
begin
  FreeAndNil(content);
  inherited;
end;

{ TGeminiResponse }

destructor TGeminiResponse.Destroy;
begin
  for var cand in candidates do
    cand.Free;
  FreeAndNil(usageMetadata);
  inherited;
end;

end.
