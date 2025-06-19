program EngineDemo;

uses
  Vcl.Forms,
  engineDemoMain in 'engineDemoMain.pas' {frmEngineDemo},
  CB.AI.Client.Anthropic in '..\..\src\CB.AI.Client.Anthropic.pas',
  CB.AI.Client.DeepSeek in '..\..\src\CB.AI.Client.DeepSeek.pas',
  CB.AI.Client.Gemini in '..\..\src\CB.AI.Client.Gemini.pas',
  CB.AI.Client.Ollama in '..\..\src\CB.AI.Client.Ollama.pas',
  CB.AI.Client.OpenAI in '..\..\src\CB.AI.Client.OpenAI.pas',
  CB.AI.Registry in '..\..\src\CB.AI.Registry.pas',
  CB.Settings.Types in '..\..\src\CB.Settings.Types.pas',
  CB.AI.Interaction in '..\..\src\CB.AI.Interaction.pas',
  CB.Network.Types in '..\..\src\CB.Network.Types.pas',
  engineDemo.SelectModelDlg in 'engineDemo.SelectModelDlg.pas' {frmSelectModel};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmEngineDemo, frmEngineDemo);
  Application.Run;
end.
