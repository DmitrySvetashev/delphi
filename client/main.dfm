object Client_MainForm: TClient_MainForm
  Left = 0
  Top = 0
  Caption = 'Client'
  ClientHeight = 513
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 635
    Height = 494
    Align = alClient
    AutoSize = True
    Stretch = True
    Transparent = True
    ExplicitWidth = 1110
    ExplicitHeight = 340
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 494
    Width = 635
    Height = 19
    Panels = <
      item
        Width = 500
      end
      item
        Width = 100
      end>
  end
  object IdTCPClient: TIdTCPClient
    ConnectTimeout = 0
    Host = '127.0.0.1'
    IPVersion = Id_IPv4
    Port = 6000
    ReadTimeout = -1
    Left = 24
    Top = 16
  end
  object IdIPWatch: TIdIPWatch
    Active = True
    HistoryFilename = 'iphist.dat'
    Left = 88
    Top = 16
  end
  object SendTimer: TTimer
    Enabled = False
    OnTimer = SendTimerTimer
    Left = 144
    Top = 16
  end
end
