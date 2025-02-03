unit CB.AI.Client.Ollama.Types;

interface

uses
  CB.AI.Client.Types;

{$M+}
type
  // https://github.com/ollama/ollama/blob/main/docs/api.md

  TOllamaMessage = class(TAIMessage)
  end;

  TOllamaRequest = class(TAIRequest)
  public
    stream: boolean;
    //temperature
    max_tokens: integer;
  end;

  TOllamaResponse = class
  public
    model               : string;
    message             : TOllamaMessage;
    done_reason         : string;
    done                : boolean;
    total_duration      : int64;   // time spent generating the response
    load_duration       : int64;   // time spent in nanoseconds loading the model
    prompt_eval_count   : integer; // number of tokens in the prompt
    prompt_eval_duration: int64;   // time spent in nanoseconds evaluating the prompt
    eval_count          : integer; // number of tokens in the response
    eval_duration       : int64;   // time in nanoseconds spent generating the response
    destructor Destroy; override;
  end;
{$M-}

implementation

uses
  System.SysUtils;

{ TOllamaResponse }

destructor TOllamaResponse.Destroy;
begin
  FreeAndNil(message);
  inherited;
end;

end.
