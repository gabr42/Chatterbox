unit CB.AI.Client.OpenAI.Types;

interface

{$M+}
type
  TOpenAIMessage = class
  public
    role   : string;
    content: string;
  end;

  TOpenAIRequest = class
  public
    model   : string;
    messages: TArray<TOpenAIMessage>;
    destructor Destroy; override;
  end;

  TOpenAIChoice = class
  public
    index        : integer;
    message      : TOpenAIMessage;
    finish_feason: string;
    destructor Destroy; override;
  end;

  TOpenAIUsage = class
  public
    prompt_tokens    : integer;
    completion_tokens: integer;
    total_tokens     : integer;
  end;

  TOpenAIResponse = class
  public
    id     : string;
    model  : string;
    choices: TArray<TOpenAIChoice>;
    usage  : TOpenAIUsage;
    destructor Destroy; override;
  end;
{$M-}


implementation

{ TOpenAIRequest }

destructor TOpenAIRequest.Destroy;
begin
  for var msg in Messages do
    msg.Free;
  inherited;
end;

{ TOpenAIChoice }

destructor TOpenAIChoice.Destroy;
begin
  message.Free;
  inherited;
end;

{ TOpenAIResponse }

destructor TOpenAIResponse.Destroy;
begin
  for var choice in choices do
    choice.Free;
  usage.Free;
  inherited;
end;

end.
