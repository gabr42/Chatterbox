unit CB.Utils;

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.ShellAPI, Winapi.Windows,
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  Posix.Stdlib,
{$ENDIF POSIX}
  System.SysUtils;

procedure OpenURL(sURL: string);

function FirstPartEndingWith(const s, delim: string): string;

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

function FirstPartEndingWith(const s, delim: string): string;
begin
  var p := Pos(UpperCase(delim), UpperCase(s));
  if p = 0 then
    Result := s
  else
    Result := Copy(s, 1, p + Length(delim) - 1);
end;

end.
