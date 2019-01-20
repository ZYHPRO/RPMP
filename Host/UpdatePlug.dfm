object frmUpdatePlug: TfrmUpdatePlug
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #26356#26032#25554#20214
  ClientHeight = 533
  ClientWidth = 546
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 546
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnSelect: TSpeedButton
      Left = 462
      Top = 8
      Width = 79
      Height = 25
      Caption = #36873#25321#25554#20214'...'
      OnClick = btnSelectClick
    end
    object Label1: TLabel
      Left = 8
      Top = 15
      Width = 60
      Height = 13
      Caption = #25554#20214#36335#24452#65306
    end
    object Label2: TLabel
      Left = 9
      Top = 42
      Width = 84
      Height = 13
      Caption = #25554#20214#36335#30001#36335#24452#65306
    end
    object btnUpdate: TButton
      Left = 462
      Top = 35
      Width = 79
      Height = 25
      Caption = #26356#26032
      TabOrder = 0
      OnClick = btnUpdateClick
    end
    object edtPluginsFile: TEdit
      Left = 68
      Top = 12
      Width = 390
      Height = 21
      TabOrder = 1
    end
    object edtRouter: TEdit
      Left = 91
      Top = 39
      Width = 367
      Height = 21
      TabOrder = 2
    end
  end
  object mmLogs: TMemo
    Left = 0
    Top = 65
    Width = 546
    Height = 468
    Align = alClient
    ReadOnly = True
    TabOrder = 1
  end
  object dlgOpen: TOpenDialog
    DefaultExt = '.dll'
    Filter = 'DLL|*.dll|BPL|*.bpl'
    Left = 400
    Top = 128
  end
end
