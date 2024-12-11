unit CB.AI.Client.Types;

interface

uses
  CB.AI.Interaction;

{$M+}
type
  TAIMessage = class
  public
    role   : string;
    content: string;
    constructor Create(const ARole, AContent: string); virtual;
  end;

  TAIRequest = class
  public
    model   : string;
    messages: TArray<TAIMessage>;
    destructor Destroy; override;
    procedure LoadMessages(const sysPrompt: string; useSystemRole: boolean;
      const history: TAIChat; const question: string);
  end;
{$M-}

implementation

{ TAIMessage }

constructor TAIMessage.Create(const ARole, AContent: string);
begin
  inherited Create;
  role := ARole;
  content := ACOntent;
end;

{ TAIRequest }

destructor TAIRequest.Destroy;
begin
  for var message in messages do
    message.Free;
  inherited;
end;

procedure TAIRequest.LoadMessages(const sysPrompt: string;
  useSystemRole: boolean; const history: TAIChat; const question: string);
begin
  SetLength(messages, 2*Length(history) + 1 + Ord(sysPrompt <> ''));
  var iMsg := 0;
  if (sysPrompt <> '') and useSystemRole then begin
    messages[iMsg] := TAIMessage.Create('system', sysPrompt);
    Inc(iMsg);
  end;
  for var iHistory := 0 to High(history) do begin
    messages[iMsg] := TAIMessage.Create('user', history[iHistory].Question);
    messages[iMsg+1] := TAIMessage.Create('assistant', history[iHistory].Answer);
    Inc(iMsg, 2);
  end;
  if (sysPrompt <> '') and (not useSystemRole) then begin
    messages[iMsg] := TAIMessage.Create('user', sysPrompt);
    Inc(iMsg);
  end;
  messages[iMsg] := TAIMessage.Create('user', question);
end;

end.
