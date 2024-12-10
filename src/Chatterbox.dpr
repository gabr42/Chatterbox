program Chatterbox;

uses
  System.StartUpCopy,
  FMX.Forms,
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
  CB.AI.Client.Ollama.Types in 'CB.AI.Client.Ollama.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmCBMain, frmCBMain);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;
end.
