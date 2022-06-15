unit UProcFunc;

interface

uses System.SysUtils, System.Classes, Data.Win.ADODB, System.JSON,
  IdGlobal, IdHashSHA, IdHMAC, IdHMACSHA1, IdSSLOpenSSL;

  procedure p_IspisLog(poruka : String);
  function f_FileSize(fileName : WideString) : Double;
  function f_Baza(baza : String; conn : TADOConnection) : Boolean;
  procedure p_Transfer;
  procedure p_SaljiROStatus;
  function f_StatusText(status : Integer) : String;
  function f_CalculateHMACSHA256(value, salt: String; var phash : String): Boolean;
  function f_PosaljiStatus(hotelid, id, status, hash : String; var greska : String) : Boolean;
  procedure p_SpremiGresku(poruka : String);


implementation

uses UFrm;

procedure p_ispislog(poruka : String);
var
       F2 : textfile;
  lporuka : string;
 velicina : Double;
begin
  velicina := f_FileSize(v_adresa + v_logovi + 'commlog.txt');
  if velicina>1 then
  begin
    Assignfile(F2,v_adresa + v_logovi + 'commlog.txt');
    Rename(F2,v_adresa + v_logovi + 'commlog' + formatdatetime('YYYYMMDDHHm', now) + '.txt');
  end;
  lporuka := lporuka + FormatDateTime('dd.mm.yyyy hh:nn:ss ', now) + poruka;
  Assignfile(F2,v_adresa + v_logovi + 'commlog.txt');
  if not (FileExists(v_adresa + v_logovi + 'commlog.txt')) then
    Rewrite(F2)
  else
    Reset(F2);
  Append(F2);
  WriteLn(F2,lporuka);
  Flush(F2);
  CloseFile(F2);
end;

function f_FileSize(fileName : WideString) : Double;
var
  sr : TSearchRec;
begin
  if FindFirst(fileName, faAnyFile, sr ) = 0 then
     result := Int64(sr.FindData.nFileSizeHigh) shl Int64(32) + Int64(sr.FindData.nFileSizeLow) / (1024*1024)
  else
     result := -1;

  FindClose(sr) ;
end;

function f_Baza(baza : String; conn : TADOConnection) : Boolean;
var l_conn1, l_conn2 : String;
begin
  Result := True;
  try
    if not(conn.Connected) then
    begin
      l_conn1 := 'Provider=MSDAORA.1;Password=ora1806;User ID=itihip;Data Source=' + baza;
      l_conn2 := 'Provider=MSDAORA.1;Password=itihip;User ID=itihip;Data Source=' + baza;

      p_ispislog('POKUŠAVAM SE SPOJITI NA BAZU');
      conn.ConnectionString := l_conn1;
      try
        conn.Open;
        Result := True;
      except
        conn.Close;
        conn.ConnectionString := l_conn2;
        try
          conn.Open;
          Result := True;
        except
          on E : Exception do
          begin
            p_ispislog('ERROR - f_Baza - ' + E.Message);
            p_SpremiGresku('f_Baza - ' + E.Message);
            Result := False;
          end;
        end;
      end;
    end;
  finally
    if Result then
      p_ispislog('BAZA SPOJENA');
  end;
end;

procedure p_Transfer;
begin
  p_ispislog('*******************************************************************');
  with Frm do
  begin
    if not f_Baza('oracle', conn) then exit;
    p_SaljiROStatus;
  end;
  p_ispislog('***************************KRAJ************************************');
end;

procedure p_SaljiROStatus;
var l_oib : String;
    l_par : Integer;
    l_poslao : Boolean;
    l_status : String;
    l_hash : String;
    l_poruka : String;
begin
  with Frm do
  begin
    try
      qryROStatus.Open;


      while not qryROStatus.Eof do
      begin
        l_poslao := False;
        l_poruka := '';

//za status 1 ne šaljem obavijest nego samo ažuriram status
        if qryROStatus.FieldByName('STATUS').AsInteger>1 then
        begin
          l_status := f_StatusText(qryROStatus.FieldByName('STATUS').AsInteger);

          if l_status<>'' then
          begin
            if f_CalculateHMACSHA256(qryROStatus.FieldByName('HOTELID').AsString +
              qryROStatus.FieldByName('ID').AsString + l_status, 'Mal0$oliD4NeBol1', l_hash) then
            begin
              l_poslao := f_PosaljiStatus(qryROStatus.FieldByName('HOTELID').AsString, qryROStatus.FieldByName('ID').AsString,
                l_status, l_hash, l_poruka);
            end
            else
              l_poruka := l_hash;

          end
          else
            l_poruka := 'NEPOZNATI STATUS ' + qryROStatus.FieldByName('STATUS').AsString;
        end
        else
          l_poslao := True;

        if l_poslao then
        begin
          qryTmp.Close;
          qryTmp.SQL.Clear;
          qryTmp.SQL.Add('update itihip.ROOMORDER_G');
          qryTmp.SQL.Add('set STATUS_SINK=STATUS');
          qryTmp.SQL.Add('where ID=:id');
          qryTmp.Parameters.ParamByName('id').Value := qryROStatus.FieldByName('ID').Value;
          qryTmp.ExecSQL;
          p_ispislog('ID ' + qryROStatus.FieldByName('ID').AsString +
            ' PROMJENJEN STATUS ' + qryROStatus.FieldByName('STATUS_SINK').AsString +
            ' -> ' + qryROStatus.FieldByName('STATUS').AsString);
        end
        else
        begin
          p_ispislog('ID ' + qryROStatus.FieldByName('ID').AsString +
            ' GREŠKA ' + l_poruka);
        end;


        qryROStatus.Next;
      end;
    finally
      qryROStatus.Close;
      qryTmp.Close;
    end;
  end;
end;

function f_StatusText(status : Integer) : String;
begin
  case status of
  0,
  1 : Result := 'received';
  2 : Result := 'notified';
  3 : Result := 'confirmed';
  4 : Result := 'finished';
  9 : Result := 'cancelled';
  else
      Result := '';
  end;

end;

function f_CalculateHMACSHA256(value, salt: String; var phash : String): Boolean;
var
  hmac: TIdHMACSHA256;
  hash: TIdBytes;
begin
  Result := False;

  try
    LoadOpenSSLLibrary;

    if not TIdHashSHA256.IsAvailable then
      raise Exception.Create('SHA256 hashing is not available!');

    hmac := TIdHMACSHA256.Create;
    try
      hmac.Key  := IndyTextEncoding_UTF8.GetBytes(salt);
      hash := hmac.HashValue(IndyTextEncoding_UTF8.GetBytes(value));
      phash := ToHex(hash);
      Result := True;
    finally
      hmac.Free;
    end;
  except
    on E : Exception do
    begin
      phash := E.Message;
    end;
  end;
end;

function f_PosaljiStatus(hotelid, id, status, hash : String; var greska : String) : Boolean;
var jo : TJSONObject;
    jp : TJSONPair;
    lRequest: TStringStream;
    lResponse: String;
begin
  with Frm do
  begin
    greska := '';
    Result := False;

      try
        lResponse := HTTP.get('https://test.my-stay.eu/API/ChangeRDStatus?' +
          'setupId=' + hotelid + '&orderid=' + id + '&status=' + status +
          '&sec=' + hash);
        jo := TJSONObject.ParseJSONValue(lResponse) as TJSONObject;
        jp := jo.Get('Success');
        Result := (jp.JsonValue is TJSONTrue);
        if not Result then
        begin
          jp := jo.Get('ErrorMessage');
          greska := jp.JsonValue.Value;
        end;
      except
        on E: Exception do
        begin
          HTTP.Disconnect;
          greska := E.Message;
        end;
      end;
    jo.Free;
  end;
end;



procedure p_SpremiGresku(poruka : String);
var
       F2 : TextFile;
  lporuka : string;
begin
  try
    Assignfile(F2, 'c:\itiutil\ErrorInfo\' + formatdatetime('YYYYMMDDHHmmsszzz', now) + '.txt');
    lporuka := 'ROStatus|' + FormatDateTime('dd.mm.yyyy hh:nn:ss', now) + '|' + poruka;
    rewrite(F2);
    append(F2);
    writeln(F2,lporuka);
    flush(F2);
    closefile(F2);
  except
  end;
end;



end.
