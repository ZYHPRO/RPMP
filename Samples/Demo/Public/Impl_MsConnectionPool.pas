//本单元MSConnection的连接池的实现
unit Impl_MsConnectionPool;


interface

uses
  Classes, Intf_MsConnectionPool,FireDAC.Comp.Client;
type

  TMSPoolConnection = class(TPoolConnection)
  protected
    procedure Lock; override;
    procedure Unlock; override;
    function CreateConnection: TFDConnection; override;
  end;

  //////////////////////////////////////////////////////////////////////////////
  TMsConnectionPool = class(TMsCustomConnectionPool)
  private
    FConnectionTimeout: Integer;
    FConnectionString: WideString;
   // FIsolationLevel: TIsolationLevel;
  protected
    function GetPoolItemClass: TPoolConnectionClass; override;
  public
    constructor Create(aOwner: TComponent;iCount:Integer);overload;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
  published
    //链接字符串
    property ConnectString: WideString read FConnectionString write FConnectionString;
    //请求连接多少秒没连上超时
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout default 15;
  // 为一个指定的事务隔离级别
   // property IsolationLevel: TIsolationLevel read FIsolationLevel write FIsolationLevel;
   // property Mode: TConnectMode read FMode write FMode default cmUnknown;
    property MaxConnections;
    property zIniCount;
    property OnLockConnection;
    property OnUnlockConnection;
    property OnCreateConnection;
    property OnLockFail;
    property OnFreeConnection;    
  end;

implementation

uses
  SysUtils;


{- protected ------------------------------------------------------------------}
function TMSPoolConnection.CreateConnection: TFDConnection;
begin
  Result:= TFDConnection.Create(nil);
  with Result as TFDConnection do
  begin
    LoginPrompt:= false;
    ConnectionString:= TMSConnectionPool(TPoolConnections(Collection).Owner).ConnectString;
    //ConnectionTimeout:= TMSConnectionPool(TPoolConnections(Collection).Owner).ConnectionTimeout;
    //IsolationLevel:= TMSConnectionPool(TPoolConnections(Collection).Owner).IsolationLevel;
  end;
end;

procedure TMSPoolConnection.Lock;
begin
  inherited;
  (Connection as TFDConnection).StartTransaction;
end;

procedure TMSPoolConnection.Unlock;
begin
  inherited;
//释放连接池,还有事务没提交的话,说明有问T.直接把此链接销毁
  if (Connection as TFDConnection).InTransaction then
  try
    (Connection as TFDConnection).Commit;
  except
    (Connection as TFDConnection).Rollback;
  end;
end;

{ TADOConnectionPool }

{- protected ------------------------------------------------------------------}
function TMsConnectionPool.GetPoolItemClass: TPoolConnectionClass;
begin
  Result:= TMsPoolConnection;
end;

{- public ---------------------------------------------------------------------}
constructor TMsConnectionPool.Create(aOwner: TComponent;iCount:Integer);
begin
  inherited Create(aOwner);
  FConnectionString:= '';
  FConnectionTimeout:= 15;
  zIniCount := iCount;
end;

procedure TMsConnectionPool.Assign(Source: TPersistent);
begin
  if Source is TFDConnection then
  begin
    ConnectString:= TFDConnection(Source).ConnectionString;
   //ConnectionTimeout:= TUniConnection(Source).ConnectionTimeout;
    //IsolationLevel:= TUniConnection(Source).IsolationLevel;
  end
  else
    inherited;
end;

procedure TMsConnectionPool.AssignTo(Dest: TPersistent);
begin
  if Dest is TMsConnectionPool then
  begin
    TMsCustomConnectionPool(Dest).MaxConnections:= MaxConnections;
    TMsCustomConnectionPool(Dest).zIniCount:= zIniCount;
    TMSConnectionPool(Dest).ConnectString:= ConnectString;
    TMSConnectionPool(Dest).ConnectionTimeout:= ConnectionTimeout;
    //TMSConnectionPool(Dest)
   // TMSConnectionPool(Dest).IsolationLevel:= IsolationLevel;
  end
  else
  if Dest is TFDConnection then
  begin
      TFDConnection(Dest).ConnectionString := ConnectString;
//    TADOConnection(Dest).ConnectionTimeout:= ConnectionTimeout;
//    TADOConnection(Dest).ConnectOptions:= ConnectOptions;
//    TADOConnection(Dest).CursorLocation:= CursorLocation;
//    TADOConnection(Dest).DefaultDatabase:= DefaultDatabase;
//    TADOConnection(Dest).IsolationLevel:= IsolationLevel;
//    TADOConnection(Dest).Mode:= Mode;
  end;
    inherited;
end;

end.
