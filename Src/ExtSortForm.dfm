object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1042#1085#1077#1096#1085#1103#1103' '#1089#1086#1088#1090#1080#1088#1086#1074#1082#1072
  ClientHeight = 145
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object SrcLabel: TLabel
    Left = 8
    Top = 3
    Width = 87
    Height = 13
    Caption = #1060#1072#1081#1083' - '#1080#1089#1090#1086#1095#1085#1080#1082':'
  end
  object DestLabel: TLabel
    Left = 8
    Top = 49
    Width = 88
    Height = 13
    Caption = #1060#1072#1081#1083' - '#1087#1088#1080#1077#1084#1085#1080#1082':'
  end
  object SrcButtonedEdit: TButtonedEdit
    Left = 8
    Top = 22
    Width = 414
    Height = 21
    Images = ImageList
    ParentShowHint = False
    ReadOnly = True
    RightButton.Hint = #1042#1099#1073#1088#1072#1090#1100' '#1090#1077#1082#1089#1090#1086#1074#1099#1081' '#1092#1072#1081#1083
    RightButton.ImageIndex = 0
    RightButton.Visible = True
    ShowHint = True
    TabOrder = 0
    OnRightButtonClick = SrcButtonedEditRightButtonClick
  end
  object SortButton: TButton
    Left = 336
    Top = 95
    Width = 86
    Height = 25
    Caption = #1057#1086#1088#1090#1080#1088#1086#1074#1072#1090#1100
    TabOrder = 1
    OnClick = SortButtonClick
  end
  object DscButtonedEdit: TButtonedEdit
    Left = 8
    Top = 68
    Width = 414
    Height = 21
    Images = ImageList
    ParentShowHint = False
    ReadOnly = True
    RightButton.Hint = #1048#1084#1103' '#1086#1090#1089#1086#1088#1090#1080#1088#1086#1074#1072#1085#1085#1086#1075#1086' '#1092#1072#1081#1083#1072' '
    RightButton.ImageIndex = 1
    RightButton.Visible = True
    ShowHint = True
    TabOrder = 2
    OnRightButtonClick = DscButtonedEditRightButtonClick
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 126
    Width = 430
    Height = 19
    Panels = <
      item
        Width = 350
      end
      item
        Width = 60
      end>
  end
  object ImageList: TImageList
    Left = 328
    Top = 24
    Bitmap = {
      494C0101020008007C0010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      00000000000000000000000000000000000000000000FAFAFA06BABABA6DB8B8
      B878B8B8B878B8B8B878B8B8B878B8B8B878B8B8B878B8B8B878DDDDDD2B0000
      000000000000000000000000000000000000D8AB8E8FCD946FB5BC7342EEB768
      35FFB56835FFB46734FFB26634FFB06533FFAE6433FFAC6332FFAA6232FFA961
      32FFA86031FFA76031FEAA683CF1BC8560C40000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210EEEEEEF6FBFB
      FBFFFEFEFEFFFCFCFCFFF7F7F7FFEFEFEFFFE3E3E3FFC7C7C7FFC3C3C3F1DEDE
      DE2A00000000000000000000000000000000C27D4FDEEBC6ADFFEAC5ADFFFEFB
      F8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFB
      F8FFFEFBF8FFC89A7CFFC79879FFAD6B3FED0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210EEEEEEF6FBFB
      FBFFFDFDFDFFFCFCFCFFF8F8F8FFEFEFEFFFE4E4E4FFCBCBCBFFD0D0D0FFC0C0
      C0F4E0E0E026000000000000000000000000BA6B37FEEDCAB3FFE0A27AFFFEFA
      F7FF62C088FF62C088FF62C088FF62C088FF62C088FF62C088FF62C088FF62C0
      88FFFDF9F6FFCA8D65FFC99B7CFFA76031FE0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210EEEEEEF6FBFB
      FBFFFDFDFDFFFDFDFDFFFAFAFAFFF1F1F1FFE8E8E8FFD9D9D9FFCFCFCFFFF1F1
      F1FFBFBFBFF1E3E3E3220000000000000000BB6C38FFEECCB6FFE1A27AFFFEFA
      F7FFBFDCC2FFBFDCC2FFBFDCC2FFBFDCC2FFBFDCC2FFBFDCC2FFBFDCC2FFBFDC
      C2FFFDF9F6FFCD9068FFCC9E81FFA86132FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210EDEDEDF6FAFA
      FAFFFCFCFCFF858585FFC9AA93FFE2B895FFDEB192FFDBAD8DFFD1A989FFC4C4
      C2FFC6C6C6FFBEBEBEE1F7F7F70900000000BB6B38FFEFCEB8FFE1A279FFFEFA
      F7FF62C088FF62C088FF62C088FF62C088FF62C088FF62C088FF62C088FF62C0
      88FFFDF9F6FFCF936AFFCEA384FFAA6132FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210ECECECF6F9F9
      F9FFDEDEDEFF2F2F2FFFC8844FFFE09961FFE19359FFE49559FFE4955AFFDDD6
      CEFFD4D4D4FFD6D6D6F6F2F2F21000000000BA6A36FFEFD0BBFFE2A27AFFFEFB
      F8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFBF8FFFEFB
      F8FFFEFBF8FFD3966DFFD2A78AFFAB6232FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210EAEAEAF6F7F7
      F7FFD8D8D8FF363636FFCA8753FFE7975DFFE89E68FFEA9B61FFEC9F65FFEBE2
      DCFFE7E7E7FFE3E3E3F6F2F2F21000000000BB6A36FFF0D2BEFFE2A37AFFE2A3
      7AFFE1A37AFFE2A37BFFE1A37BFFE0A178FFDE9F77FFDD9F76FFDC9D74FFD99B
      72FFD89971FFD69970FFD5AB8EFFAD6333FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210E8E8E8F6F4F4
      F4FFD6D6D6FF333333FFC38253FFE99A5FFFEA9D64FFEB9E66FFEC9E65FFF2E9
      E2FFF1F1F1FFEAEAEAF6F2F2F21000000000BB6A36FFF2D5C2FFE3A37AFFE3A3
      7AFFE2A37BFFE2A37BFFE2A47BFFE1A279FFE0A178FFDEA077FFDE9E75FFDC9D
      74FFDA9B73FFD99B73FFDAB095FFAF6433FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210E6E6E6F6F1F1
      F1FFD0D0D0FF2F2F2FFFBF7E4EFFE59559FFE6965BFFE69960FFE89960FFF6EA
      E0FFFAFAFAFFEFEFEFF6F2F2F21000000000BB6A36FFF2D8C5FFE3A47BFFE3A3
      7AFFE3A47AFFE2A47BFFE2A37BFFE1A37BFFE1A279FFDFA077FFDE9F76FFDD9E
      74FFDB9C72FFDC9D74FFDDB59AFFB16534FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210E4E4E4F6EDED
      EDFFCACACAFF262626FFB97A48FFE29154FFE39255FFE49357FFE5955AFFF7E7
      DCFFFDFDFDFFF1F1F1F6F2F2F21000000000BB6B36FFF4D9C7FFE6A67DFFC88C
      64FFC98D65FFC98E67FFCB926CFFCB926DFFCA9069FFC88C65FFC88C64FFC88C
      64FFC88C64FFDA9C74FFE1BA9FFFB36634FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210E3E3E3F6E9E9
      E9FFC1C1C1FF1B1B1BFFB37443FFDE8C4EFFDF8D4FFFE08F51FFE19052FFF3E0
      D1FFFDFDFDFFF1F1F1F6F2F2F21000000000BB6B36FEF4DCC9FFE7A77DFFF9EC
      E1FFF9ECE1FFF9EDE3FFFCF4EEFFFDFAF7FFFDF7F3FFFAEDE5FFF7E7DBFFF7E5
      D9FFF6E5D8FFDEA077FFE4BEA4FFB46734FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210E0E0E0F6E5E5
      E5FFB8B8B8FF0D0D0DFFAE6F3EFFDA8848FFDB894AFFDC8A4BFFDD8B4DFFEDD6
      C5FFFBFBFBFFF0F0F0F6F2F2F21000000000BD6D39FAF5DDCCFFE7A87EFFFAF0
      E8FFFAF0E8FFC98D66FFFAF0E9FFFDF8F3FFFEFAF8FFFCF4EFFFF9E9DFFFF7E7
      DBFFF7E5D9FFE0A278FFE7C2A9FFB66835FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210DEDEDEF6E1E1
      E1FFCACACAFF5E5E5EFFB19580FFC2997AFFC09A79FFC19A7AFFB58C70FFF0E9
      E4FFF6F6F6FFEDEDEDF6F2F2F21000000000BF7341F0F6DFD0FFE8A87EFFFCF6
      F1FFFCF6F1FFC88C64FFFAF1E9FFFBF4EEFFFDFAF7FFFDF9F6FFFAF0E8FFF8E8
      DDFFF7E6DBFFE1A37AFFEFD5C3FFB76935FE0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210DEDEDEF6DDDD
      DDFFE0E0E0FFE3E3E3FFE6E6E6FFE9E9E9FFECECECFFEEEEEEFFEFEFEFFFF0F0
      F0FFF1F1F1FFEAEAEAF6F2F2F21000000000C68154D8F6DFD1FFE9AA80FFFEFA
      F6FFFDFAF6FFC88C64FFFBF3EEFFFBF1EAFFFCF6F2FFFEFBF8FFFCF6F1FFF9EC
      E2FFF8E7DBFFEED0BAFFECD0BDFFBC7343F80000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F2F2F210DEDEDEF6DDDD
      DDFFDDDDDDFFDEDEDEFFE1E1E1FFE4E4E4FFE6E6E6FFE8E8E8FFE9E9E9FFEAEA
      EAFFEBEBEBFFE6E6E6F6F2F2F21000000000D6A5849BF6E0D1FFF7E0D1FFFEFB
      F8FFFEFBF7FFFDF9F6FFFCF5F0FFFAF0EAFFFBF2EDFFFDF9F6FFFDFAF7FFFBF1
      EBFFF8E9DFFEECD0BEFBCD9169ECE2C4B0630000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000FAFAFA06CCCCCC9DD0D0
      D0B7D0D0D0B7D0D0D0B7D0D0D0B7D1D1D1B7D1D1D1B7D1D1D1B7D2D2D2B7D2D2
      D2B7D2D2D2B7CDCDCD9DFAFAFA0600000000E1BDA571D9AB8D90C9885ECCC074
      43EEBD6D39FABB6B36FEBB6B36FFBB6A36FFBB6A36FFBC6C39FFBD6E3BFFBB6D
      3AFFBF7444EFC88D65CBE6CDBC54FFFFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00801F000000000000800F000000000000
      8007000000000000800300000000000080010000000000008001000000000000
      8001000000000000800100000000000080010000000000008001000000000000
      8001000000000000800100000000000080010000000000008001000000000000
      8001000000000000800100000000000000000000000000000000000000000000
      000000000000}
  end
  object SaveTextFileDialog: TSaveTextFileDialog
    DefaultExt = '.txt'
    Filter = #1058#1077#1082#1089#1090#1086#1074#1099#1077' '#1092#1072#1081#1083#1099'|*.txt|'#1042#1089#1077' '#1092#1072#1081#1083#1099'|*.*'
    Left = 152
    Top = 28
  end
  object OpenTextFileDialog: TOpenTextFileDialog
    Filter = #1058#1077#1082#1089#1090#1086#1074#1099#1077' '#1092#1072#1081#1083#1099'|*.txt|'#1042#1089#1077' '#1092#1072#1081#1083#1099'|*.*'
    Left = 240
    Top = 24
  end
  object Timer: TTimer
    Enabled = False
    OnTimer = TimerTimer
    Left = 256
    Top = 80
  end
end
