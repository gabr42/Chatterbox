unit CB.AI.Interaction;

interface

uses
  CB.Settings.Types,
  Spring.Collections;

type
  TAIInteraction = record
    Question : string;
    Answer   : string;
    Reasoning: string;
  end;

  TAIResponse = record
    Response      : string;
    Reasoning     : string;
    Model         : string;
    Done          : boolean;
    DoneReason    : string;
    Duration_ms   : integer;
    PromptTokens  : integer;
    ResponseTokens: integer;
  end;

  TAIChat = TArray<TAIInteraction>;

  TAIQueryPurpose = (qpHost, qpChat, qpAPIKeys, qpModels);

  IAISerializer = interface ['{9F731BD7-3A25-4747-93EA-0751C94FEB97}']
    function EngineType: TCBAIEngineType;
    function URL(const engineConfig: TCBAIEngineSettings; purpose: TAIQueryPurpose): string;
    function QuestionToJSON(const engineConfig: TCBAIEngineSettings;
      const history: TAIChat; sendSystemPrompty: boolean; const question: string): string; overload;
    function JSONToAnswer(const engineConfig: TCBAIEngineSettings;
      const json: string; var errorMsg: string): TAIResponse;
    function JSONToModels(const json: string; var errorMsg: string): TArray<string>;
  end;

implementation

end.
