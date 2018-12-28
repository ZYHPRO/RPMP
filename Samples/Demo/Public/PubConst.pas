unit PubConst;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes,ShellAPI,DateUtils,Graphics,jpeg,EncdDecd;
Type
  TPubMtdCmd = class
  public
  {----------------------------------------------------------------
  Unix时间转换成delphi时间
  @param  UnixDateTime   Unix格式时间
  @return          返回delphi格式时间
  -----------------------------------------------------------------}
  class function UnixDateTimeToDelphiDateTime(UnixDateTime: Integer): TDateTime;
  {----------------------------------------------------------------
  delphi时间转换成Unix时间
  @param  DTime   delphi格式时间
  @return          返回Unix格式时间
  -----------------------------------------------------------------}
  class  function DelphiDateTimeToUnixDateTime(DTime: TDateTime): Integer;
  {*-----------------------------------------------------------------------
  彻底删除日志目录
  @param DirecName
  @return 无
  -------------------------------------------------------------------------}
  class procedure RemoveLogDirectory(DirecName : string);
  {*-----------------------------------------------------------------------
  查找并删除过期的日志目录
  @param LogPath 需要查到到过期日志的上级目录
  @param Days  天数
  @return 无
  -------------------------------------------------------------------------}
  class procedure DeleteLogDirc(LogPath : string;Days: Integer);
  {*-----------------------------------------------------------------------
  获取GUID
  @param 无
  @return 返回GUID
  -------------------------------------------------------------------------}
  class function GetGUID: string;
  {------------------------------------------------------------------------
   功能: 计算软件持续运行时间
  @param  startTime : 软件启动时间
  @return 返回值  软件持续运行时间
  -------------------------------------------------------------------------}
  class function GetRunTimeINfo(startTime: TDateTime): String;
  {------------------------------------------------------------------------
   功能: 计算两个时间的差值(分钟) 比 MinutesBetween 准确
  @param  ANow : 当前时间
  @param  AThen : 其他时间
  @return 返回值  两个时间之间的差值(分钟数)
  -------------------------------------------------------------------------}
  class function MyMinutesBetween(const ANow, AThen: TDateTime): integer;
  {------------------------------------------------------------------------
   功能: 将base64字符串转化为Jpeg图片
  @param  ImgStr : base64字符串
  @return 返回值  Jpeg图片
  -------------------------------------------------------------------------}
  class function Base64StringToJpeg(ImgStr:string):TJPEGImage;
  constructor Create;
  destructor Destroy; override;
  end;
implementation
constructor TPubMtdCmd.Create;
begin
end;
destructor TPubMtdCmd.Destroy;
begin
 Inherited;
end;
class function TPubMtdCmd.GetRunTimeINfo(startTime: TDateTime): String;
var
  lvMSec, lvRemain:Int64;
  lvDay, lvHour, lvMin, lvSec:Integer;
begin
  lvMSec := MilliSecondsBetween(Now(), startTime);
  lvDay := Trunc(lvMSec / MSecsPerDay);
  lvRemain := lvMSec mod MSecsPerDay;
  lvHour := Trunc(lvRemain / (MSecsPerSec * 60 * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60 * 60);
  lvMin := Trunc(lvRemain / (MSecsPerSec * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60);
  lvSec := Trunc(lvRemain / (MSecsPerSec));
  if lvDay > 0 then
    Result := Result + IntToStr(lvDay) + ' d ';
  if lvHour > 0 then
    Result := Result + IntToStr(lvHour) + ' h ';
  if lvMin > 0 then
    Result := Result + IntToStr(lvMin) + ' m ';
  if lvSec > 0 then
    Result := Result + IntToStr(lvSec) + ' s ';
end;
class function TPubMtdCmd.GetGUID: string;        //add lgm
var
  LTep: TGUID;
  sGUID :string;
begin
  CreateGUID(LTep);
  sGUID := GUIDToString(LTep);
  sGUID := StringReplace(sGUID,'-','',[rfReplaceAll]);
  sGUID := Copy(sGUID,2,Length(sGUID)-2);
  Result :=  sGUID;
end;
class function TPubMtdCmd.DelphiDateTimeToUnixDateTime(DTime: TDateTime): Integer;
begin
  Result := SecondsBetween(DTime,EncodeDateTime(1970,1,1,0,0,0,0));
end;
class function TPubMtdCmd.UnixDateTimeToDelphiDateTime(UnixDateTime: Integer): TDateTime;
begin
  Result := EncodeDate(1970,1,1)+(UnixDateTime/86400);
end;
class procedure  TPubMtdCmd.DeleteLogDirc(LogPath: string;Days: Integer);
var
  Sr1 : TsearchRec;
  PathStr : string;
begin
  PathStr := LogPath;
  if FindFirst(PathStr+'*.*',faAnyFile,SR1)=0 then
  begin
    if (Sr1.Name <>'.') and (SR1.Name <> '..') then
    begin
      if SR1.Attr = faDirectory then
      begin
        if Sr1.Name <(FormatDateTime('YYYYMMDD',IncDay(Now,-Days))) then
          RemoveLogDirectory(PathStr+Sr1.Name);
      end;
    end;
    while FindNext(SR1)=0 do
    begin
      if (Sr1.Name <>'.') and (SR1.Name <> '..') then
      begin
        if SR1.Attr = faDirectory then
        begin
          if Sr1.Name <(FormatDateTime('YYYYMMDD',IncDay(Now,-Days))) then
            RemoveLogDirectory(PathStr+Sr1.Name);
        end;
      end;
    end;
    FindClose(SR1);
  end;
end;
class procedure  TPubMtdCmd.RemoveLogDirectory(DirecName: string);
var
  F: TSHFILEOPSTRUCT;
begin
  try
    FillChar(F, SizeOf(F), 0);
    with F do
    begin
      Wnd := 0;
      wFunc := FO_DELETE;
      pFrom := PChar(DirecName+#0);
      pTo := PChar(DirecName+#0);
      ///可还原无确认错误提示
      fFlags := FOF_NOCONFIRMATION+FOF_NOERRORUI;
    end;
    SHFileOperation(F);
  except
  end;
end;
class function  TPubMtdCmd.MyMinutesBetween(const ANow, AThen: TDateTime): integer;
begin
  Result := round(MinuteSpan(ANow, AThen));
end;
class function  TPubMtdCmd.Base64StringToJpeg(ImgStr:string):TJPEGImage;
var ss:TStringStream;
    ms:TMemoryStream;
    jpg:TJPEGImage;
begin
  try
    ss := TStringStream.Create(imgStr);
    ms := TMemoryStream.Create;
    DecodeStream(ss,ms);//将base64字符流还原为内存流
    ms.Position:=0;
    jpg := TJPEGImage.Create;
    jpg.LoadFromStream(ms);
    ss.Free;
    ms.Free;
    result :=jpg;
  except
  end;
end;
end.
