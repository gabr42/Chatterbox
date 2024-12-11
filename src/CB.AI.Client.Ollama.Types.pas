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
    //max_tokens
  end;

  TOllamaResponse = class
  public
    model  : string;
    message: TOllamaMessage;
  end;
{$M-}

implementation

end.
