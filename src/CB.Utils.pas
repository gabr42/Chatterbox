unit CB.Utils;

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.ShellAPI, Winapi.Windows;
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  Posix.Stdlib;
{$ENDIF POSIX}

procedure OpenURL(sURL: string);

implementation

procedure OpenURL(sURL: string);
begin
{$IFDEF MSWINDOWS}
  ShellExecute(0, 'OPEN', PChar(sURL), '', '', SW_SHOWNORMAL);
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  _system(PAnsiChar('open ' + AnsiString(sURL)));
{$ENDIF POSIX}
end;

end.
