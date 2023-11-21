object PCAnalyserForm: TPCAnalyserForm
  Left = 0
  Top = 0
  ActiveControl = ElevateAdminRightsButton
  Caption = 'PC Analyser'
  ClientHeight = 622
  ClientWidth = 828
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object ProgramControlGroupBox: TGroupBox
    Left = 0
    Top = 0
    Width = 828
    Height = 128
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 814
    DesignSize = (
      828
      128)
    object ProgramContextGroupBox: TGroupBox
      Left = 279
      Top = 10
      Width = 257
      Height = 112
      Caption = ' Programmkontext '
      TabOrder = 0
      DesignSize = (
        257
        112)
      object CurrentUserStaticText: TStaticText
        Left = 10
        Top = 25
        Width = 96
        Height = 17
        Caption = 'Aktueller Benutzer:'
        TabOrder = 0
      end
      object CurrentUserStaticTextResult: TStaticText
        Left = 110
        Top = 25
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 1
      end
      object UserRightsStaticText: TStaticText
        Left = 10
        Top = 48
        Width = 82
        Height = 17
        Caption = 'Benutzerrechte:'
        TabOrder = 2
      end
      object UserRightsStaticTextResult: TStaticText
        Left = 110
        Top = 48
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 3
      end
      object ElevateAdminRightsButton: TButton
        Left = 10
        Top = 89
        Width = 239
        Height = 20
        Cursor = crHandPoint
        Anchors = [akTop, akRight]
        Caption = 'Administratorrechte anfordern'
        ElevationRequired = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        OnClick = ElevateAdminRightsButtonClick
      end
      object UserContextStaticText: TStaticText
        Left = 10
        Top = 71
        Width = 88
        Height = 17
        Caption = 'Benutzerkontext:'
        TabOrder = 5
      end
      object UserContextStaticTextResult: TStaticText
        Left = 110
        Top = 71
        Width = 140
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 6
      end
    end
    object ProgramInfoGroupBox: TGroupBox
      Left = 10
      Top = 10
      Width = 257
      Height = 89
      Caption = ' Programminfo '
      TabOrder = 1
      object NameStaticText: TStaticText
        Left = 10
        Top = 25
        Width = 90
        Height = 17
        Caption = 'Name && Version:'
        TabOrder = 0
      end
      object TargetCompilationStaticText: TStaticText
        Left = 10
        Top = 48
        Width = 88
        Height = 17
        Caption = 'Ziel-Kompilierung:'
        TabOrder = 1
      end
      object TargetOperatingSystemStaticText: TStaticText
        Left = 10
        Top = 71
        Width = 101
        Height = 17
        Caption = 'Ziel-Betriebssystem:'
        TabOrder = 2
      end
      object NameStaticTextResult: TStaticText
        Left = 126
        Top = 25
        Width = 130
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 3
      end
      object TargetCompilationStaticTextResult: TStaticText
        Left = 126
        Top = 48
        Width = 130
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 4
      end
      object TargetOperatingSystemStaticTextResult: TStaticText
        Left = 126
        Top = 71
        Width = 130
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 5
      end
    end
    object KernelModeDriverGroupBox: TGroupBox
      Left = 545
      Top = 10
      Width = 277
      Height = 112
      Anchors = [akLeft, akTop, akRight]
      Caption = ' Kernel-Modus-Treiber '
      TabOrder = 2
      ExplicitWidth = 263
      object DriverNameStaticText: TStaticText
        Left = 10
        Top = 25
        Width = 39
        Height = 17
        Caption = 'Status:'
        TabOrder = 0
      end
      object LoadDriverButton: TButton
        Left = 10
        Top = 65
        Width = 125
        Height = 20
        Caption = 'Treiber laden...'
        TabOrder = 4
        OnClick = LoadDriverButtonClick
      end
      object UnloadDriverButton: TButton
        Left = 140
        Top = 65
        Width = 125
        Height = 20
        Caption = 'Treiber entladen'
        TabOrder = 5
        OnClick = UnloadDriverButtonClick
      end
      object DriverDetailsStaticText: TStaticText
        Left = 10
        Top = 48
        Width = 40
        Height = 17
        Caption = 'Details:'
        TabOrder = 2
      end
      object DriverNameStaticTextResult: TStaticText
        Left = 50
        Top = 25
        Width = 200
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 1
      end
      object DriverDetailsStaticTextResult: TStaticText
        Left = 50
        Top = 48
        Width = 200
        Height = 17
        AutoSize = False
        Caption = 'noch nicht ermittelt'
        TabOrder = 3
      end
      object DisableTestModeButton: TButton
        Left = 140
        Top = 89
        Width = 125
        Height = 20
        Caption = 'Testmodus deaktivieren'
        TabOrder = 7
        OnClick = DisableTestModeButtonClick
      end
      object EnableTestModeButton: TButton
        Left = 10
        Top = 89
        Width = 125
        Height = 20
        Caption = 'Testmodus aktivieren'
        TabOrder = 6
        OnClick = EnableTestModeButtonClick
      end
    end
  end
  object SystemAccessGroupBox: TGroupBox
    Left = 0
    Top = 128
    Width = 828
    Height = 374
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 814
    ExplicitHeight = 341
    object Splitter: TSplitter
      Left = 252
      Top = 15
      Width = 574
      Height = 357
      Align = alClient
      ExplicitWidth = 3
      ExplicitHeight = 401
    end
    object CategoryTreeView: TTreeView
      Left = 2
      Top = 15
      Width = 250
      Height = 357
      Align = alLeft
      Indent = 19
      ReadOnly = True
      TabOrder = 0
      OnChange = CategoryTreeViewChange
      ExplicitHeight = 324
    end
    object ResultsListView: TListView
      Left = 252
      Top = 15
      Width = 574
      Height = 357
      Align = alClient
      Columns = <
        item
          Caption = 'Eigenschaft'
          Width = 250
        end
        item
          AutoSize = True
          Caption = 'Wert'
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 1
      ViewStyle = vsReport
      ExplicitWidth = 560
      ExplicitHeight = 324
    end
  end
  object ProgramLogGroupBox: TGroupBox
    Left = 0
    Top = 502
    Width = 828
    Height = 120
    Align = alBottom
    TabOrder = 2
    ExplicitTop = 469
    ExplicitWidth = 814
    object LogMemo: TMemo
      Left = 2
      Top = 15
      Width = 824
      Height = 103
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      ExplicitWidth = 810
    end
  end
  object KernelModeDriver: TTimer
    OnTimer = KernelModeDriverTimer
    Left = 673
    Top = 218
  end
  object KernelModeDriverOpenDialog: TOpenDialog
    Left = 665
    Top = 170
  end
end
