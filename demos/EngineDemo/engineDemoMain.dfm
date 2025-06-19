object frmEngineDemo: TfrmEngineDemo
  Left = 0
  Top = 0
  Caption = 'Engine demo'
  ClientHeight = 679
  ClientWidth = 646
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  DesignSize = (
    646
    679)
  TextHeight = 15
  object lblEngineType: TLabel
    Left = 8
    Top = 16
    Width = 36
    Height = 15
    Caption = 'Engine'
  end
  object lblAPIKey: TLabel
    Left = 8
    Top = 103
    Width = 40
    Height = 15
    Caption = 'API Key'
  end
  object lblMode: TLabel
    Left = 8
    Top = 73
    Width = 34
    Height = 15
    Caption = 'Model'
  end
  object Label1: TLabel
    Left = 8
    Top = 45
    Width = 21
    Height = 15
    Caption = 'URL'
  end
  object lblQuery: TLabel
    Left = 8
    Top = 132
    Width = 32
    Height = 15
    Caption = 'Query'
  end
  object lblResponse: TLabel
    Left = 8
    Top = 403
    Width = 50
    Height = 15
    Caption = 'Response'
  end
  object cbxEngineType: TComboBox
    Left = 68
    Top = 13
    Width = 141
    Height = 23
    Style = csDropDownList
    DropDownCount = 32
    TabOrder = 0
    OnChange = cbxEngineTypeChange
  end
  object inpAPIKey: TEdit
    Left = 68
    Top = 100
    Width = 537
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    PasswordChar = '*'
    TabOrder = 3
  end
  object inpModel: TEdit
    Left = 68
    Top = 71
    Width = 377
    Height = 23
    TabOrder = 1
  end
  object btnListModels: TButton
    Left = 451
    Top = 69
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 2
    OnClick = btnListModelsClick
  end
  object inpURL: TEdit
    Left = 68
    Top = 42
    Width = 377
    Height = 23
    TabOrder = 4
  end
  object btnGetAPIKey: TButton
    Left = 611
    Top = 99
    Width = 25
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 5
    OnClick = btnGetAPIKeyClick
  end
  object inpQuery: TMemo
    Left = 68
    Top = 129
    Width = 568
    Height = 216
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 6
  end
  object btnRunQuery: TButton
    Left = 68
    Top = 360
    Width = 568
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Ask'
    TabOrder = 7
    OnClick = btnRunQueryClick
  end
  object outResponse: TMemo
    Left = 68
    Top = 400
    Width = 568
    Height = 269
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 8
  end
end
