object frmSelectModel: TfrmSelectModel
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Select a model'
  ClientHeight = 431
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  DesignSize = (
    624
    431)
  TextHeight = 15
  object lbModels: TListBox
    Left = 8
    Top = 8
    Width = 608
    Height = 369
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 15
    TabOrder = 0
    OnDblClick = lbModelsDblClick
  end
  object btnOK: TButton
    Left = 226
    Top = 392
    Width = 75
    Height = 25
    Anchors = [akTop]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 322
    Top = 392
    Width = 75
    Height = 25
    Anchors = [akTop]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
