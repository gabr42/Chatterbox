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
    model  : string;
    message: TOllamaMessage;
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
