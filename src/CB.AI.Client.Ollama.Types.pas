unit CB.AI.Client.Ollama.Types;

interface

uses
  CB.AI.Client.Types;

{$M+}
type
  // https://github.com/ollama/ollama/blob/main/docs/api.md

  TOllamaMessage = class(TAIMessage)
  end;

  TOllamaJsonSchema = class
  public
    name  : string;
    schema: string;
  end;

  TOllamaResponseFormat = class
  public
    &type      : string;
    json_schema: string; // TOllamaJsonSchema
  end;

  TOllamaRequest = class(TAIRequest)
  public
    stream: boolean;
    //temperature
    max_tokens: integer;
    response_format: TOllamaResponseFormat;
    destructor Destroy; override;
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

  TOllamaModel = class
  public
    name: string;
    model: string;
    size: int64;
  end;

  TOllamaModels = class
  public
    models: TArray<TOllamaModel>;
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

{ TOllamaModels }

destructor TOllamaModels.Destroy;
begin
  for var model in models do
    model.Free;
  inherited;
end;

destructor TOllamaRequest.Destroy;
begin
  FreeAndNil(response_format);
  inherited;
end;

end.
