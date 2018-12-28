//2011-06-21 20:57  高吞吐量的一个日志函数类
//内部采用双缓冲算法，写入信息的时候，是直接写入到
//内存中，然后线程根据一定的时间间隔，将内存中的数据
//写到磁盘文件中，里面开辟了两块缓冲内存队列,采用了
//生产者===》消费者模式，WriteLog 是写入日志数据，算是数据的生产者
//TFileStream对象，将内存中的数据写入磁盘是消费者角色。
//但由于采用了双缓冲方式，减少了生产与消费间的干扰.
//也勉强算是个双缓冲队列的实际应用.
//2016/02/15 21:57 修复文件名自动修改，线程冲突问题
//2018/03/28 14:22 修复不存在路径报错问题,同时解决设置新文件路径后数据不能精确写入新文件问题(冷库到底优化)
//2018/04/21 14:22 优化写入文件过程,扩展WriteLog，使其能够随时更改文件路径(冷库到底优化)
unit sfLog;

interface

uses
  Windows, Messages,Classes,SysUtils,SyncObjs;

type
  TsfLog=class;
  TOnLogExportFile=procedure(OutFileName:string) of object;
  TOnLogException=procedure(Sender:TsfLog;const E:Exception) of object;

  TsfLog=class(TThread)
  private
    FLF:Ansistring;//#13#10;
    FS:TFileStream;
    FHWnd:THandle;
    FCurFileName:Ansistring;
    FFileName:Ansistring;
    FBegCount:DWord;
    FBuffA,FBuffB,FBuffC:TMemoryStream;
    FCS:TRTLCriticalSection;
    FCS_FileName:TRTLCriticalSection;
    FLogBuff,FLogBuffNew:TMemoryStream;

    //FOnLogExportFile:TOnLogExportFile;
    FExportHWnd:THandle;
    FExportMsgID:Integer;
    FExportHanding:Boolean;
    FExprotFileName:Ansistring;
    FWriteInterval:DWORD;//日志写文件间隔时间(ms)
    FEndPosition:Integer;//当前文件最后的指针位置
    FTag:Integer;
    FAutoLogFileName:Boolean;
    FLogFilePrefix:string;
    FOnLogException:TOnLogException;
    procedure  CreateFs;
    procedure WriteToFile();
    function getLogFileName: Ansistring;
    procedure setLogFileName(const Value: Ansistring);
    //\\
    procedure  InnerExportFile(DestFileName:string);
    function getEndPosition: Integer;
    function getFileHandle: THandle;
    //暂时不考虑用(ReadLog 2013-03-27 16:22)
    function ReadLog(FilePos:Integer;Buf:Pointer;ReadCount:Integer):Integer;
    procedure SetAutoLogFileName(const Value: Boolean);
  protected
    procedure Execute();override;
    procedure WndProc(var MsgRec:TMessage);
  public
    //日志文件名,写入间隔(ms),缓冲尺寸(Byte)
    constructor Create(LogFileName:string;
      pvWriteInterval:DWORD=2000;
      pvBuffSize:DWORD=1024 * 1024;
      NewFile:Boolean=FALSE);virtual;
    destructor  Destroy();override;
      //返回值 0：成功，文件复制完成后，发送通知消息
    // 1:系统忙，当前有个文件复制操作尚未完成
    // 2:要导出的文件与当前写入的日志文件同名
    // 此函数非线程安全,如果是多线程中调用此函数，需要调用端加同步控制
    // 2012-08-18 12:17
    //2016/02/15 17:58 注释掉此函数(ExportFile)
    //function ExportFile(OutFileName:Ansistring;MsgHandle:THandle;MsgID:Integer):Integer;

    procedure WriteLog(const InBuff:Pointer;InSize:Integer);overload;
    procedure WriteLog(const Msg:Ansistring);overload;
    procedure WriteLog(const logFileName: TFileName; Msg:Ansistring);overload;
    //\\
    procedure WriteBin(const Msg:Ansistring);overload;
    procedure WriteBin(const InBuff:Pointer;InSize:Integer);overload;
    //\\
    procedure BegingWrite();
    procedure EndWrite();

    procedure WriteBinNoLock(const InBuff:Pointer;InSize:Integer);overload;
    procedure WriteLogNoLock(const InBuff:Pointer;InSize:Integer);

  public
    property AutoLogFileName:Boolean read FAutoLogFileName write SetAutoLogFileName;//每天自动更新文件名
    property FileName:Ansistring read getLogFileName write setLogFileName;
    property EndPosition:Integer read getEndPosition;
    property Tag:Integer read FTag write FTag;
    property FileHandle:THandle read getFileHandle;
    //AutoLogFileName = true 时LogFilePrex 有效
    //LogFileName = Path + LogFilePrefix + YYYYMMDD.Log
    property LogFilePrefix:string read FLogFilePrefix write FLogFilePrefix; //日志文件名前缀
    property OnLogException:TOnLogException read FOnLogException write FOnLogException;//2016/02/1517:58 添加
  end;


 (*
  TSrvLog=class(TInterfacedObject,ISrvLog)
  private
    FLog:TsfLog;
    function getLogFileName():PChar;
    procedure setLogFileName(AFileName:PChar);
    procedure WriteLog(const InBuff:Pointer;InSize:Integer);overload;
    procedure FlushBuff();
  public
    constructor Create(LogFileName:Ansistring);
    destructor  Destroy();override;
  end;
  *)

 // function getSrvLogObj(const LogFileName:PChar):ISrvLog;stdcall;
  procedure sfNowToBuf(const OutBuf:PAnsiChar;BufSize:Integer=23);stdcall;

var
   qsfLog:TsfLog;
implementation

procedure TsfLog.BegingWrite;
begin
  EnterCriticalSection(FCS);
end;

constructor TsfLog.Create(LogFileName:string;pvWriteInterval:DWORD;pvBuffSize:DWORD;NewFile:Boolean);
begin
  FAutoLogFileName := FALSE;
  inherited Create(TRUE);
  //\\
  FWriteInterval :=  pvWriteInterval;//写入间隔

  InitializeCriticalSection(FCS);  //初始化
  InitializeCriticalSection(FCS_FileName);//日志文件名

  Self.FBuffA := TMemoryStream.Create();
  Self.FBuffA.Size := pvBuffSize;//1024 * 1024; //初始值可以根据需要自行调整
  ZeroMemory(FBuffA.Memory,FBuffA.Size);

  Self.FBuffB := TMemoryStream.Create();
  Self.FBuffB.Size := pvBuffSize;//1024 * 1024; //初始值可以根据需要自行调整
  Self.FLogBuff := Self.FBuffA;
  ZeroMemory(FBuffA.Memory,FBuffA.Size);

  Self.FBuffC := TMemoryStream.Create();
  Self.FBuffC.Size := pvBuffSize;//1024 * 1024; //初始值可以根据需要自行调整
  Self.FLogBuffNew := Self.FBuffC;
  ZeroMemory(FBuffC.Memory,FBuffC.Size);
  //\\
  FS := nil;
  FCurFileName := LogFileName;
  FFileName    := LogFileName;

  FLF  := #13#10;

  //FEvent := TEvent.Create(nil,TRUE,FALSE,'');
  FExportHanding := FALSE;

  FHWnd := classes.AllocateHWnd(WndProc);
  Windows.SetTimer(FHwnd,1001,3000,nil);

  //启动执行
  Self.Resume();
  //\\
end;
procedure  TsfLog.CreateFs;
var
  vPathStr: string;
begin
  vPathStr := ExtractFileDir(FCurFileName);
  if not DirectoryExists(vPathStr) then
    ForceDirectories(vPathStr);
  if FileExists(FCurFileName) then
  begin
    FS := TFileStream.Create(FCurFileName,fmOpenWrite or fmShareDenyNone);
    FS.Position := FS.Size;
  end
  else begin
    FS := TFileStream.Create(FCurFileName,fmCreate);
    FS.Free();
    FS := TFileStream.Create(FCurFileName,fmOpenWrite or fmShareDenyNone);
    FS.Position := FS.Size;
  end;

end;
destructor TsfLog.Destroy;
begin
  Windows.KillTimer(FHwnd,1001);
  Terminate();
  Sleep(100);
  WriteToFile();
  FBuffA.Free();
  FBuffB.Free();
  FBuffC.Free();
  FS.Free();
  DeleteCriticalSection(FCS);
  DeleteCriticalSection(FCS_FileName);
  inherited;
end;

procedure TsfLog.EndWrite;
begin
  LeaveCriticalSection(FCS);
end;

procedure TsfLog.Execute();
var
  IsOK:Boolean;
begin
  FBegCount := GetTickCount();
  while(not Terminated) do
  begin
    Sleep(50);
    //2000ms 可以根据自己的需要调整，数据写入磁盘的间隔
    if (GetTickCount() - FBegCount) >= FWriteInterval then  //漠认 2000ms
    begin
      try
        WriteToFile();
      except
        on E:Exception do
        begin
          if Assigned(OnLogException) then
            OnLogException(Self,E);
        end;
      end;
      FBegCount := GetTickCount();
    end;
  end;
end;

(*
procedure TsfLog.Execute();
var
  IsOK:Boolean;
begin
  FBegCount := GetTickCount();
  while(not Terminated) do
  begin
    //2000ms 可以根据自己的需要调整，数据写入磁盘的间隔
    if (GetTickCount() - FBegCount) >= FWriteInterval then  //漠认 2000ms
    begin
      WriteToFile();
      FBegCount := GetTickCount();
    end
    else begin
      if Assigned(FOnLogExportFile) then //导出当前的日志文件
      begin
        IsOK := TRUE;
        try
          try
            FOnLogExportFile(FExprotFileName);
          except
            IsOK := FALSE;
          end;
        finally
          FExportHanding := FALSE;
          FOnLogExportFile := nil;
          PostMessage(FExportHWnd,FExportMsgID,Integer(IsOK),0);
        end;
      end
      else
        Sleep(50);
    end;
  end;
end;
*)



(*
function TsfLog.ExportFile(OutFileName: Ansistring; MsgHandle: THandle;
  MsgID: Integer): Integer;
begin
  Result := 0;
  if FExportHanding then
  begin
    Result := 1; //系统忙
    Exit;
  end;
  //\\
  if UpperCase(OutFileName) = UpperCase(FileName) then
  begin
    Result := 2; //与正在写入的日志文件同名
    Exit;
  end;
  //\\
  FExprotFileName := Copy(OutFileName,1,Length(OutFileName));
  FExportHWnd  := MsgHandle;
  FExportMsgID := MsgID;
  FOnLogExportFile := InnerExportFile; //线程中调用

end;
*)

function TsfLog.getEndPosition: Integer;
begin
  Windows.InterlockedExchange(Result,FEndPosition);
end;

function TsfLog.getFileHandle: THandle;
begin
  Result := FS.Handle;
end;

function TsfLog.getLogFileName: Ansistring;
begin
  EnterCriticalSection(FCS_FileName);
  try
    Result := Copy(FCurFileName,1,Length(FCurFileName));
  finally
    LeaveCriticalSection(FCS_FileName);
  end;
end;

procedure TsfLog.InnerExportFile(DestFileName: string);
var
  LogfileName:AnsiString;
begin
  LogfileName := Self.FileName;
  try
    FS.Free();
    //Windows.CopyFile(PWideChar(LogFileName),PWideChar(DestFileName),FALSE);
  finally
    if FileExists(LogfileName) then
    begin
      FS := TFileStream.Create(LogFileName,fmOpenWrite or fmShareDenyNone);
      FS.Position := FS.Size;
    end
    else
      FS := TFileStream.Create(LogFileName,fmCreate or fmShareDenyNone);
  end;
end;

function TsfLog.ReadLog(FilePos: Integer; Buf: Pointer;
  ReadCount: Integer): Integer;
var
  EndPos:Integer;
begin
  if FilePos >= EndPosition then
  begin
    Result := 0;
    Exit;
  end;
  //
  while(TRUE) do
  begin
    if Windows.LockFile(FS.Handle,0,0,FS.Size,0) then
    begin
      try
        FS.Position := FilePos;
        Result := FS.Read(Buf^,ReadCount);
      finally
        Windows.UnlockFile(FS.Handle,0,0,FS.Size,0);
      end;
      Break;
    end;
    Sleep(10);
  end;
end;

procedure TsfLog.SetAutoLogFileName(const Value: Boolean);
begin
  FAutoLogFileName := Value;
end;

procedure TsfLog.setLogFileName(const Value: Ansistring);
begin
  EnterCriticalSection(FCS_FileName);
  try
    FFileName := Copy(Value,1,Length(Value));
  finally
    LeaveCriticalSection(FCS_FileName);
  end;
end;

procedure TsfLog.WriteBin(const Msg: Ansistring);
begin
  WriteBin(Pointer(Msg),Length(Msg));
end;

procedure TsfLog.WndProc(var MsgRec: TMessage);
var
  AFileName:string;
begin
  if MsgRec.Msg = WM_TIMER then
  begin
    if (not Terminated) and AutoLogFileName then
    begin
      try
        AFileName := ExtractFilePath(FileName) + LogFilePrefix +  FormatDateTime('YYYYMMDD',Now) + '.TXT';
        AFileName := StringReplace(AFileName,'\\','\',[rfReplaceAll,rfIgnoreCase]);
        FileName := AFileName;
      finally
      end;
    end;
  end
  else
   inherited;
end;

procedure TsfLog.WriteBin(const InBuff: Pointer; InSize: Integer);
begin
  EnterCriticalSection(FCS);
  try
    if Uppercase(FCurFileName) <> UpperCase(FFileName) then
      FLogBuffNew.Write(InBuff^,InSize)
    else
      FLogBuff.Write(InBuff^,InSize);
  finally
    LeaveCriticalSection(FCS);
  end;
end;


procedure TsfLog.WriteBinNoLock(const InBuff: Pointer; InSize: Integer);
begin
  FLogBuff.Write(InBuff^,InSize);
end;

procedure TsfLog.WriteLog(const Msg: Ansistring);
begin
  WriteLog(Pointer(Msg),Length(Msg));
end;
procedure TsfLog.WriteLog(const logFileName: TFileName; Msg:Ansistring);
begin
  if FFileName <> logFileName then
    FFileName := logFileName;
  WriteLog(Pointer(Msg),Length(Msg));
end;
procedure TsfLog.WriteLogNoLock(const InBuff: Pointer; InSize: Integer);
var
  TimeBuf:array[0..23] of AnsiChar;
begin
  sfNowToBuf(TimeBuf);
  TimeBuf[23] := #32;
  FLogBuff.Write(TimeBuf,24);
  FLogBuff.Write(InBuff^,InSize);
  FLogBuff.Write(FLF[1],2);
end;

procedure TsfLog.WriteLog(const InBuff: Pointer; InSize: Integer);
var
  TimeBuf:array[0..23] of AnsiChar;
begin
  sfNowToBuf(TimeBuf);
  TimeBuf[23] := #32;
  EnterCriticalSection(FCS);
  try
    if Uppercase(FCurFileName) <> UpperCase(FFileName) then
    begin
      FLogBuffNew.Write(TimeBuf,24);
      FLogBuffNew.Write(InBuff^,InSize);
      FLogBuffNew.Write(FLF[1],2);
    end
    else
    begin
      FLogBuff.Write(TimeBuf,24);
      FLogBuff.Write(InBuff^,InSize);
      FLogBuff.Write(FLF[1],2);
    end;
  finally
    LeaveCriticalSection(FCS);
  end;
end;

procedure TsfLog.WriteToFile;

  procedure WriteBuffToFile(Buf:Pointer;Len:Integer);
  var
    LockSize:Integer;
    dwPos:Integer;
  begin
    dwPos    := FS.Position;
    Windows.InterlockedExchange(FEndPosition,dwPos);
    LockSize := dwPos + Len;
    while(TRUE) do
    begin
      if LockFile(FS.Handle,dwPos,0,LockSize,0) then
      begin
        try
          FS.Write(Buf^,Len);
        finally
          UnLockFile(FS.Handle,dwPos,0,LockSize,0);
        end;
        Break;
      end;
      Sleep(10);
    end;
  end;

var
  MS:TMemoryStream;
  IsLogFileNameChanged:Boolean;
  vPathStr: string;
begin
  EnterCriticalSection(FCS);
  //交换缓冲区
  try
    MS := nil;
    if FLogBuff.Position > 0 then
    begin
      MS := FLogBuff;
      if FLogBuff = FBuffA then FLogBuff := FBuffB
      else
        FLogBuff := FBuffA;
      FLogBuff.Position := 0;
    end;
  finally
     LeaveCriticalSection(FCS);
  end;
  //存在文件路径,则把数据写入文件
  if Trim(FCurFileName) <> '' then
  begin
    //创建文件内存句柄
    if not Assigned(FS) then
     CreateFs;
    //存在数据,则把数据写入文件
    if Assigned(MS) then
    begin
      //写入文件
      try
        if MS.Position > 0 then
        begin
          FS.Write(MS.Memory^,MS.Position);
        end;
      finally
        MS.Position := 0;
      end;
    end;
  end;
  //检测文件名称是否变化
  EnterCriticalSection(FCS_FileName);
  try
    IsLogFileNameChanged := (Uppercase(FCurFileName) <> UpperCase(FFileName));
    //日志文件名称修改了
    if IsLogFileNameChanged then
    begin
      FCurFileName :=  FFileName;
      FS.Free();
      CreateFs;
      //写入文件
      try
        if FLogBuffNew.Position > 0 then
        begin
          FS.Write(FLogBuffNew.Memory^,FLogBuffNew.Position);
        end;
      finally
        FLogBuffNew.Position := 0;
      end;
    end;
  finally
    LeaveCriticalSection(FCS_FileName);
  end;
end;


(*
{ TSrvLog }

constructor TSrvLog.Create(LogFileName:string);
begin
  FLog := TsfLog.Create(LogFileName);
end;

destructor TSrvLog.Destroy;
begin
  FLog.Free();
  inherited;
end;

procedure TSrvLog.FlushBuff;
begin
  FLog.WriteToFile();
end;

function TSrvLog.getLogFileName: PChar;
begin
  Result := PChar(FLog.FileName);
end;

procedure TSrvLog.setLogFileName(AFileName: PChar);
begin
  FLog.FileName := AFileName;
end;

procedure TSrvLog.WriteLog(const InBuff: Pointer; InSize: Integer);
begin
  FLog.WriteLog(InBuff,InSize);
end;
*)


//YYYY-MM-DD hh:mm:ss zzz
//OutBuff输出缓冲区，必须保证有足够的长度(至少23个字节空间)
//函数内部不做检测
//2012-02-12 17:15 修改
//2012-11-04 17:59 修改
procedure sfNowToBuf(const OutBuf:PAnsiChar;BufSize:Integer);

const
   strDay:AnsiString =
    '010203040506070809101112131415161718192021222324252627282930' +
    '313233343536373839404142434445464748495051525354555657585960' +
    '6162636465666768697071727374757677787980'  +
    '81828384858687888990919293949596979899';
   str10:AnsiString = '0123456789';
var
  Year,Month,Day,HH,MM,SS,ZZZ:WORD;
  P:PAnsiChar;
  I,J:Integer;
  SystemTime: TSystemTime;
  lvBuf:array[0..22] of AnsiChar;
begin
  if BufSize <= 0 then
    Exit;

  P := @lvBuf[0];// OutBuff;
  for I := 0 to BufSize - 1 do P[I] := '0';

  GetLocalTime(SystemTime);
   Year  := SystemTime.wYear;
   Month := SystemTime.wMonth;
   Day   := SystemTime.wDay;
   HH    := SystemTime.wHour;
   MM    := SystemTime.wMinute;
   SS    := SystemTime.wSecond;
   ZZZ   := SystemTime.wMilliseconds;

   (*  2012-11-04 17:59
     ZZZ := 0;
     HH  := 0;
     MM  := 0;
     SS := 0;
   *)

    //Year
    I := Year div 1000;
    J := Year mod 1000;
    P^ := str10[I + 1];Inc(P);
    I := J div 100;
    P^ := str10[I + 1];Inc(P);
    I := J mod 100;
    if I > 0 then
    begin
      P^ := strDay[(I - 1) * 2 + 1];Inc(P);
      P^ := strDay[(I - 1) * 2 + 2];Inc(P);
      P^ := '-';Inc(P);
    end
    else begin
       P^ := '0';Inc(P);
       P^ := '0';Inc(P);
      P^ := '-';Inc(P);
   end;

     //Month

    P^ := strDay[(Month - 1) * 2 + 1];Inc(P);
    P^ := strDay[(Month - 1) * 2 + 2];Inc(P);
    P^ := '-';Inc(P);


   //Day
     P^ := strDay[(Day - 1) * 2 + 1];Inc(P);
     P^ := strDay[(Day - 1) * 2 + 2];Inc(P);
     P^ := #32;Inc(P);

  //HH
     if HH > 0 then
     begin
       P^ := strDay[(HH - 1) * 2 + 1];Inc(P);
       P^ := strDay[(HH - 1) * 2 + 2];Inc(P);
     end
     else begin
       P^ := #48;Inc(P);
       P^ := #48;Inc(P);
     end;
     P^ := ':';Inc(P);

    //MM
     if MM > 0 then
     begin
       P^ := strDay[(MM - 1) * 2 + 1];Inc(P);
       P^ := strDay[(MM - 1) * 2 + 2];Inc(P);
     end
     else begin
       P^ := #48;Inc(P);
       P^ := #48;Inc(P);
     end;
     P^ := ':';Inc(P);

    //SS
     if SS > 0 then
     begin
      P^ := strDay[(SS - 1) * 2 + 1];Inc(P);
      P^ := strDay[(SS - 1) * 2 + 2];Inc(P);
     end
     else begin
       P^ := #48;Inc(P);
       P^ := #48;Inc(P);
     end;
     P^ := #32;Inc(P);

     //ZZZ
    Year  := ZZZ div 100;
    Month := ZZZ mod 100;
    P^ := str10[Year + 1];Inc(P);
    if Month > 0 then
    begin
       P^ := strDay[(Month - 1) * 2 + 1];Inc(P);
      P^ := strDay[(Month - 1) * 2 + 2];
    end
    else begin
      P^ := '0';Inc(P);
      P^ := '0';
    end;

  if BufSize >23 then BufSize := 23;
  P := OutBuf;
  for I := 0 to BufSize - 1 do P[I] :=  lvBuf[I]
end;

initialization
  qsfLog := TsfLog.Create('');
finalization
  qsfLog.Free;
end.
end.
