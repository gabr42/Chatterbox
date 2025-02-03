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
    cache_creation_input_tokens: integer; // The number of input tokens used to create the cache entry.
    cache_read_input_tokens    : integer; // The number of input tokens read from the cache.
    input_tokens               : integer; // The number of input tokens which were used.
    output_tokens              : integer; // The number of output tokens which were used.
  end;

  TAnthropicResponse = class
  public
    &type        : string;
    role         : string;
    model        : string;
    content      : TArray<TAnthropicContent>;
    stop_reason  : string;
    stop_sequence: string;
    usage        : TAnthropicUsage;
    destructor Destroy; override;
  end;
{$M-}

implementation

uses
  System.SysUtils;

{ TAnthropicResponse }

destructor TAnthropicResponse.Destroy;
begin
  for var c in content do
    c.Free;
  FreeAndNil(usage);
  inherited;
end;

end.
