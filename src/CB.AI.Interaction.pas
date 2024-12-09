unit CB.AI.Interaction;

interface

uses
  CB.Settings,
  Spring.Collections;

type
  TAIInteraction = record
    Question: string;
    Answer  : string;
  end;

  TAIChat = TArray<TAIInteraction>;

  IAISerializer = interface ['{9F731BD7-3A25-4747-93EA-0751C94FEB97}']
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var errorMsg: string): string;
    function URL: string;
  end;

var
  GSerializers: IDictionary<TCBAIEngineType, IAISerializer>;

implementation

initialization
  GSerializers := TCollections.CreateDictionary<TCBAIEngineType, IAISerializer>;
end.
