object frmServerSet: TfrmServerSet
  Left = 0
  Top = 0
  Caption = #26381#21153#22120#36816#34892#21442#25968#35774#32622
  ClientHeight = 444
  ClientWidth = 473
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 473
    Height = 409
    Align = alClient
    BevelOuter = bvNone
    Color = clWindow
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      473
      409)
    object grpTransmission: TGroupBox
      Left = 0
      Top = 1
      Width = 278
      Height = 402
      Anchors = [akLeft, akTop, akBottom]
      Caption = #26381#21153#35774#32622
      TabOrder = 0
      object edtTcpPort: TLabeledEdit
        Left = 117
        Top = 19
        Width = 123
        Height = 21
        EditLabel.Width = 75
        EditLabel.Height = 13
        EditLabel.Caption = #30417#21548#31471#21475'(TCP)'
        LabelPosition = lpLeft
        MaxLength = 5
        NumbersOnly = True
        TabOrder = 0
        Text = '211'
      end
      object edtEncryptionKey: TLabeledEdit
        Left = 117
        Top = 77
        Width = 123
        Height = 21
        EditLabel.Width = 48
        EditLabel.Height = 13
        EditLabel.Caption = #21152#23494#23494#38053
        Enabled = False
        LabelPosition = lpLeft
        MaxLength = 5
        NumbersOnly = True
        PasswordChar = '*'
        TabOrder = 1
        Text = 'flm'
      end
      object edtMaxConnectionNumber: TLabeledEdit
        Left = 117
        Top = 108
        Width = 123
        Height = 21
        EditLabel.Width = 60
        EditLabel.Height = 13
        EditLabel.Caption = #26368#22823#36830#25509#25968
        LabelPosition = lpLeft
        MaxLength = 5
        NumbersOnly = True
        TabOrder = 2
        Text = '10'
      end
      object edtHttpPort: TLabeledEdit
        Left = 117
        Top = 48
        Width = 123
        Height = 21
        EditLabel.Width = 81
        EditLabel.Height = 13
        EditLabel.Caption = #30417#21548#31471#21475'(HTTP)'
        LabelPosition = lpLeft
        MaxLength = 5
        NumbersOnly = True
        TabOrder = 3
        Text = '8080'
      end
    end
    object grpMisc: TGroupBox
      Left = 300
      Top = 5
      Width = 163
      Height = 398
      Anchors = [akLeft, akTop, akRight, akBottom]
      Caption = #20854#20182#35774#32622
      TabOrder = 1
      object chkRunOnStartup: TCheckBox
        Left = 15
        Top = 42
        Width = 138
        Height = 17
        Caption = #24320#26426#21551#21160
        TabOrder = 0
      end
      object chkGlobalLogEnabled: TCheckBox
        Left = 15
        Top = 19
        Width = 138
        Height = 17
        Caption = 'SQL'#26085#24535
        TabOrder = 1
      end
      object ChkActive: TCheckBox
        Left = 15
        Top = 65
        Width = 138
        Height = 17
        Caption = #33258#21551#21160
        TabOrder = 2
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 409
    Width = 473
    Height = 35
    Align = alBottom
    BevelOuter = bvNone
    Color = clWindow
    ParentBackground = False
    TabOrder = 1
    object Button1: TButton
      Left = 284
      Top = 6
      Width = 89
      Height = 25
      Caption = #20445#23384
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 379
      Top = 5
      Width = 89
      Height = 25
      Caption = #20851#38381
      TabOrder = 1
      OnClick = Button2Click
    end
  end
end
