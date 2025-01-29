unit CB.AI.Client.DeepSeek.Types;

interface

uses
  CB.AI.Client.Types;

{$M+}
type
  // https://api-docs.deepseek.com/api/create-chat-completion

  TDeepSeekMessage = class(TAIMessage)
  public
    reasoning_content: string;
  end;

  TDeepSeekRequest = class(TAIRequest)
  public
    max_tokens : integer;
    stream     : boolean;
    temperature: real;
  end;

  TDeepSeekChoice = class
  public
    index        : integer;
    message      : TDeepSeekMessage;
    finish_feason: string;
    destructor Destroy; override;
  end;

  TDeepSeekUsage = class
  public
    prompt_tokens    : integer;
    completion_tokens: integer;
    total_tokens     : integer;
  end;

  TDeepSeekResponse = class
  public
    id     : string;
    model  : string;
    choices: TArray<TDeepSeekChoice>;
    usage  : TDeepSeekUsage;
    destructor Destroy; override;
  end;

implementation

{ TDeepSeekChoice }

destructor TDeepSeekChoice.Destroy;
begin
  message.Free;
  inherited;
end;

{ TDeepSeekResponse }

destructor TDeepSeekResponse.Destroy;
begin
  for var choice in choices do
    choice.Free;
  usage.Free;
  inherited;
end;

end.
