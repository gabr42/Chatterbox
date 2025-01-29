unit CB.AI.Interaction;

interface

uses
  CB.Settings,
  Spring.Collections;

type
  TAIInteraction = record
    Question : string;
    Answer   : string;
    Reasoning: string;
  end;

  TAIChat = TArray<TAIInteraction>;

  IAISerializer = interface ['{9F731BD7-3A25-4747-93EA-0751C94FEB97}']
    function URL(const engineConfig: TCBAIEngineSettings): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings; const history: TAIChat; sendSystemPrompty: boolean; const question: string): string;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings; const json: string; var reasoning, errorMsg: string): string;
  end;

implementation

end.
