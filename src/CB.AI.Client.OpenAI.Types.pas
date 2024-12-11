unit CB.AI.Client.OpenAI.Types;

interface

uses
  CB.AI.Client.Types;

{$M+}
type
  // https://platform.openai.com/docs/api-reference/chat

  TOpenAIMessage = class(TAIMessage)
  end;

  TOpenAIRequest = class(TAIRequest)
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
