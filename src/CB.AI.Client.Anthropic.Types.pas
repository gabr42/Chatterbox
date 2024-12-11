unit CB.AI.Client.Anthropic.Types;

interface

uses
  CB.AI.Client.Types;

{$M+}
type
  // https://docs.anthropic.com/en/api/messages

  TAnthropicMessage = class(TAIMessage)
  end;

  TAnthropicRequest = class(TAIRequest)
  public
    system    : string;
    max_tokens: integer;
    stream    : boolean;
    //temperature: float;
  end;

  TAnthropicContent = class
  public
    &type: string;
    text : string;
  end;

  TAnthropicUsage = class
  public
    input_tokens : integer;
    output_tokens: integer;
  end;

  TAnthropicResponse = class
  public
    &type      : string;
    role       : string;
    model      : string;
    content    : TArray<TAnthropicContent>;
    stop_reason: string;
    //stop_sequence ???
    usage      : TAnthropicUsage;
  end;
{$M-}

implementation

end.
