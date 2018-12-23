//本单元MSConnection的连接池
//by FLM
unit Intf_MsConnectionPool;

interface
uses
  Classes, SysUtils, SyncObjs,
  DateUtils,FireDAC.Comp.Client;
type
   //自定义连接线
    TPoolConnectionClass = class of TPoolConnection;
    TMSCustomConnectionPool = class;
    TExceptionEvent = procedure (Sender: TObject; E: Exception) of object;

  //锁定链接
  TPoolConnection = class(TCollectionItem)
  private
    FBusy: Boolean;
    FConnection: TFDConnection;
    FbConnect:Boolean;
  protected
    procedure Lock; virtual;
    procedure Unlock; virtual;
    function Connected: Boolean; virtual;
    function CreateConnection: TFDConnection; virtual; abstract;
  public
    property Busy: Boolean read FBusy;
    property Connection: TFDConnection read FConnection;
    property ConnectOK: Boolean read FbConnect; 
    constructor Create(aCollection: TCollection); override;
    destructor Destroy; override;
  end;

  //保存链接池索引
  TPoolConnections = class(TOwnedCollection)
  private
    function GetItem(aIndex: Integer): TPoolConnection;
    procedure SetItem(aIndex: Integer; const Value: TPoolConnection);
  public
    property Items[aIndex: LongInt]: TPoolConnection read GetItem write SetItem; default;
    function Add: TPoolConnection;
  {$IFNDEF VER140}
    function Owner: TPersistent;
  {$ENDIF}
  end;

    TMsCustomConnectionPool = class(TComponent)
  private
    FCS: TCriticalSection;
    FProviderName:String;
    FServerIP:String;
    FPort:Integer;
    FLoginPrompt:Boolean;
    FuserName:String;
    FPassword:String;
    FConnections: TPoolConnections;
    FMaxConnections: LongInt;
    FIniCount:LongInt;
    FOnLockConnection: TNotifyEvent;
    FOnLockFail: TExceptionEvent;
    FOnUnLockConnection: TNotifyEvent;
    FOnCreateConnection: TNotifyEvent;
    FOnFreeConnection: TNotifyEvent;
    function GetUnusedConnections: LongInt;
    function GetTotalConnections: LongInt;
  protected
    function GetPoolItemClass: TPoolConnectionClass; virtual; abstract;
    procedure DoLock; virtual;
    procedure DoLockFail(E: Exception); virtual;
    procedure DoUnlock; virtual;
    procedure DoCreateConnection; virtual;
    procedure DoFreeConnection; virtual;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;


    procedure AssignTo(Dest: TPersistent); override;

   //设置的最大的链接数
    property MaxConnections: LongInt read FMaxConnections write FMaxConnections default -1;
    
    //设置初始化链接池数
    property zIniCount: LongInt read FIniCount write FIniCount default 0;
   //从池中获取未锁定的连接
    function GetConnection: TFDConnection;
   //连接池释放
    procedure FreeConnection(aConnection: TFDConnection);
   //返回池中未使用的连接数
    property UnusedConnections: LongInt read GetUnusedConnections;

   //获取总共链接池
    property TotalConnections: LongInt read GetTotalConnections;
   //锁连接池
    property OnLockConnection: TNotifyEvent read FOnLockConnection write FOnLockConnection;
   //解锁连接池
    property OnUnlockConnection: TNotifyEvent read FOnUnlockConnection write FOnUnlockConnection;

  //创建新的连接池
    property OnCreateConnection: TNotifyEvent read FOnCreateConnection write FOnCreateConnection;
  //锁连接池失败
    property OnLockFail: TExceptionEvent read FOnLockFail write FOnLockFail;
  //释放连接池
    property OnFreeConnection: TNotifyEvent read FOnFreeConnection write FOnFreeConnection;
  end;




implementation

{$IFDEF TRIAL}
uses
  Windows;
{$ENDIF}


{ TPoolConnection }
{- protected ----------------------------------------------------------------- }
procedure TPoolConnection.Lock;
begin
  FBusy:= true;
  if not Connected then
  begin
    Connection.Open;
  end;
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoLock;
end;

procedure TPoolConnection.Unlock;
begin
  FBusy:= false;
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoUnLock;
end;

function TPoolConnection.Connected: Boolean;
begin
  Result:= Connection.Connected;
end;

{ - public ------------------------------------------------------------------- }
constructor TPoolConnection.Create(aCollection: TCollection);
begin
  inherited;
  FConnection:= CreateConnection;
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoCreateConnection;
end;

destructor TPoolConnection.Destroy;
begin
  if Busy then Unlock;
  FreeAndNil(FConnection);
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoFreeConnection;
  inherited;
end;

{ TPoolConnections }
{ - private ------------------------------------------------------------------ }
function TPoolConnections.GetItem(aIndex: Integer): TPoolConnection;
begin
  Result:= inherited GetItem(aIndex) as TPoolConnection;
end;

procedure TPoolConnections.SetItem(aIndex: Integer;
  const Value: TPoolConnection);
begin
  inherited SetItem(aIndex, Value);
end;

{ - public ------------------------------------------------------------------- }
function TPoolConnections.Add: TPoolConnection;
begin
  Result:= inherited Add as TPoolConnection;
end;

{$IFNDEF VER140}
function TPoolConnections.Owner: TPersistent;
begin
  Result:= GetOwner;
end;
{$ENDIF}

{ TCustomConnectionPool }
{ - private ------------------------------------------------------------------ }
function TMsCustomConnectionPool.GetUnusedConnections: LongInt;
var
  I: LongInt;
begin
  FCS.Enter;
  Result:= 0;
  try
    for I:= 0 to FConnections.Count - 1 do
      if not FConnections[I].Busy then
        Inc(Result);
  finally
    FCS.Leave;
  end;
end;

function TMsCustomConnectionPool.GetTotalConnections: LongInt;
begin
  Result:= FConnections.Count;
end;

{ - public ------------------------------------------------------------------- }
constructor TMsCustomConnectionPool.Create(aOwner: TComponent);
begin
  inherited;
  FCS:= TCriticalSection.Create;
  //FCS.SetLockName('FCS');
  FConnections:= TPoolConnections.Create(Self, GetPoolItemClass);
  FMaxConnections:= -1;
end;

destructor TMsCustomConnectionPool.Destroy;
begin
  FCS.Enter;
  try
      FConnections.Free;
  finally
    FCS.Leave;
  end;
  FreeAndNil(FCS);
  inherited;
end;

procedure TMsCustomConnectionPool.AssignTo(Dest: TPersistent);
begin
  if Dest is TMsCustomConnectionPool then
    TMsCustomConnectionPool(Dest).MaxConnections:= MaxConnections 
  else
    inherited AssignTo(Dest);
end;


function TMsCustomConnectionPool.GetConnection:TFDConnection;
var
  I: LongInt;
begin
  Result:= nil;
  FCS.Enter;  //??
  try
    try
    //预先产生多少个线程池
//      if FConnections.Count<FIniCount then
//      begin
//        for i := 0 to FIniCount-1 do
//        begin
//          FConnections.Add;
//        end;
//      end;
      I:= 0;
      while I < FConnections.Count do   //获取连接总数
      begin
        if not FConnections[I].Busy then   //如果是空闲的链接
        begin
          Result:= FConnections[I].Connection;  //获取此链接
          try
            FConnections[I].Lock;           //锁定此链接
            Break;
          except
            FConnections.Delete(I);   //异常的话,删除此接连
            Continue;
          end;
        end;
        Inc(I);   //自增加1 
      end;

      if Result = nil then  //如果上面没匹配到
        if ((FConnections.Count < MaxConnections) or (MaxConnections = -1))
{$IFDEF TRIAL}
          and ((FindWindow('TAppBuilder', nil) <> 0) or (FConnections.Count  < MaxConnections))
{$ENDIF}
        then
        begin
          with FConnections.Add do      //创建一个新的链接
          begin
            Result:= Connection;
            Lock;
          end;
        end
        else   //连接池超出限制,抛出异常
          raise Exception.Create('超过服务器最大连接池数.');
    except
      On E: Exception do
        DoLockFail(E);
    end;
  finally
    FCS.Leave;   //??
  end;
end;

procedure TMsCustomConnectionPool.FreeConnection(aConnection: TFDConnection);
var
  I: LongInt;
begin
  FCS.Enter;
  try
    for I:= 0 to FConnections.Count - 1 do
      if FConnections[I].Connection = aConnection then
      begin
        FConnections[I].Unlock;
        Break;
      end;
  finally
    FCS.Leave;
  end;
end;


procedure TMsCustomConnectionPool.DoLock;
begin
  if Assigned(FOnLockConnection) then
    FOnLockConnection(Self);
end;

procedure TMsCustomConnectionPool.DoUnlock;
begin
  if Assigned(FOnUnLockConnection) then
    FOnUnLockConnection(Self);
end;

procedure TMsCustomConnectionPool.DoCreateConnection;
begin
  if Assigned(FOnCreateConnection) then
    FOnCreateConnection(Self);
end;

procedure TMsCustomConnectionPool.DoLockFail(E: Exception);
begin
  if Assigned(FOnLockFail) then
    FOnLockFail(Self, E);
end;

procedure TMsCustomConnectionPool.DoFreeConnection;
begin
  if Assigned(FOnFreeConnection) then
    FOnFreeConnection(Self);
end;
end.
