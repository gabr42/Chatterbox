program Chatterbox;

uses
  FastMM4,
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  CBMain in 'CBMain.pas' {frmCBMain},
  CB.AI.Interaction in 'CB.AI.Interaction.pas',
  CB.AI.Client.OpenAI in 'CB.AI.Client.OpenAI.pas',
  CB.AI.Client.OpenAI.Types in 'CB.AI.Client.OpenAI.Types.pas',
  CB.Encryption in 'CB.Encryption.pas',
  CB.UI.Chat in 'CB.UI.Chat.pas' {frChat: TFrame},
  CB.Network in 'CB.Network.pas',
  CB.UI.Settings in 'CB.UI.Settings.pas' {frmSettings},
  CB.Settings in 'CB.Settings.pas',
  CB.AI.Client.Ollama in 'CB.AI.Client.Ollama.pas',
  CB.AI.Client.Ollama.Types in 'CB.AI.Client.Ollama.Types.pas',
  CB.AI.Client.Types in 'CB.AI.Client.Types.pas',
  CB.AI.Client.Anthropic in 'CB.AI.Client.Anthropic.pas',
  CB.AI.Client.Anthropic.Types in 'CB.AI.Client.Anthropic.Types.pas',
  CB.AI.Registry in 'CB.AI.Registry.pas',
  CB.AI.Client.Gemini in 'CB.AI.Client.Gemini.pas',
  CB.AI.Client.Gemini.Types in 'CB.AI.Client.Gemini.Types.pas';

{$R *.res}

begin
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TfrmCBMain, frmCBMain);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;
end.
