unit CB.AI.Client.Ollama.Types;

interface

{$M+}
type
  TOllamaMessage = class
  public
    role   : string;
    content: string;
  end;

  TOllamaRequest = class
  public
    model : string;
    messages: TArray<TOllamaMessage>;
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
