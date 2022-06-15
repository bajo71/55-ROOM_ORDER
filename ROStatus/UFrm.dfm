object Frm: TFrm
  Left = 0
  Top = 0
  Caption = 'RoomOrder - izmjena statusa v1.00'
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  WindowState = wsMinimized
  OnCreate = FormCreate
  OnDblClick = FormDblClick
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 0
    Top = 0
    Width = 635
    Height = 16
    Align = alTop
    Alignment = taCenter
    Caption = 'RoomOrder - izmjena statusa v1.00'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ExplicitWidth = 204
  end
  object btnTransfer: TButton
    Left = 0
    Top = 274
    Width = 635
    Height = 25
    Align = alBottom
    Caption = 'TRANSFER'
    TabOrder = 0
    Visible = False
    OnClick = btnTransferClick
  end
  object conn: TADOConnection
    ConnectionString = 
      'Provider=MSDAORA.1;Password=ora1806;User ID=itihip;Data Source=o' +
      'racle12;Persist Security Info=True'
    LoginPrompt = False
    Provider = 'MSDAORA.1'
    Left = 48
    Top = 40
  end
  object tmrObrada: TTimer
    Interval = 10000
    OnTimer = tmrObradaTimer
    Left = 224
    Top = 40
  end
  object HTTP: TIdHTTP
    IOHandler = SSLIOHandlerSocketOpenSSL
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoInProcessAuth, hoForceEncodeParams]
    Left = 344
    Top = 40
  end
  object SSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL
    MaxLineAction = maException
    Port = 0
    DefaultPort = 0
    SSLOptions.Method = sslvTLSv1_2
    SSLOptions.SSLVersions = [sslvTLSv1_2]
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 384
    Top = 80
  end
  object qryROStatus: TADOQuery
    Connection = conn
    CursorType = ctStatic
    LockType = ltReadOnly
    Parameters = <>
    SQL.Strings = (
      'select s.HOTELID, g.ID, g.STATUS, g.STATUS_SINK'
      'from itihip.ROOMORDER_G g'
      
        'inner join itihip.ROOMORDER_SETUP s on g.POD=s.POD and g.ORG=s.O' +
        'RG'
      'where g.STATUS<>g.STATUS_SINK')
    Left = 104
    Top = 36
    object qryROStatusHOTELID: TIntegerField
      FieldName = 'HOTELID'
    end
    object qryROStatusID: TIntegerField
      FieldName = 'ID'
    end
    object qryROStatusSTATUS: TIntegerField
      FieldName = 'STATUS'
    end
    object qryROStatusSTATUS_SINK: TIntegerField
      FieldName = 'STATUS_SINK'
    end
  end
  object qryTmp: TADOQuery
    Connection = conn
    CursorType = ctStatic
    LockType = ltReadOnly
    Parameters = <>
    Left = 168
    Top = 84
  end
end
