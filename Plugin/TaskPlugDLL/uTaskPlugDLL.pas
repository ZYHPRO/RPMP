{
功能：业务接口实现单元
author : zhyhui
date: 2018-12-08
}

unit uTaskPlugDLL;

interface

uses
  Winapi.Windows,Graphics, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  TaskServerIntf,SynCommons,System.StrUtils,System.DateUtils,sfLog,uPubVariableSet,
  QString, QPlugins,qplugins_base;
const
  ConstAppTaskNo = '100';    //苹果业务
  ConstAppTaskUserNo = '100101';   //北京客户
type
  TServiceRemoteSQL = class(TQService,IRemoteSQL,IQNotify)
  private
    FAppTaskNo: string;          //业务模型编号
    FAppTaskUserNo: string;      //业务客户编号
    FAMgr: IQNotifyManager;
    FNotifyId: array[0..1] of Integer;
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW); overload; override;
    destructor Destroy; override;
    //获取插件key
    function GetPlugKey: string;
    //接收数据总处理
    function RecvDataGeneralControl(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
    //校验数据正确与否
    function CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
    //登录验证
    function Login(aRecvStr: AnsiString; var Error: string): RawJSON;
    property AppTaskNo: string  read FAppTaskNo;
    property AppTaskUserNo: string read FAppTaskUserNo;
  end;

implementation
function TServiceRemoteSQL.GetPlugKey: string;
begin
  Result := FAppTaskNo+'-'+FAppTaskUserNo;
end;
constructor  TServiceRemoteSQL.create(const AId: TGuid; AName: QStringW);
begin
  inherited Create(AId, AName);
  FAppTaskNo := ConstAppTaskNo;
  FAppTaskUserNo := ConstAppTaskUserNo;
  //通知注册初始化
  FAMgr := PluginsManager as IQNotifyManager;
  FNotifyId[0] := FAMgr.IdByName(PWideChar(NotifyServerStart));
  FAMgr.Subscribe(FNotifyId[0], Self);
  FNotifyId[1] := FAMgr.IdByName(PWideChar(NotifyServerStop));
  FAMgr.Subscribe(FNotifyId[1], Self);
  FAMgr.Subscribe(NID_PLUGIN_UNLOADING, Self);
end;
destructor TServiceRemoteSQL.Destroy;
begin
  inherited;
end;
procedure TServiceRemoteSQL.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
var
  vStr: string;
begin
  //自定义通知,服务启动
  if AId = FNotifyId[0] then
  begin
    vStr := '服务器启动...';
  end;
  //自定义通知,服务关闭
  if AId = FNotifyId[1] then
  begin
    vStr := '服务器停止...';
  end;
  //预定义通知,服务准备卸载
  if AId = NID_PLUGIN_UNLOADING then
  begin
    FAMgr.unSubscribe(FNotifyId[0], Self);
    FAMgr.unSubscribe(FNotifyId[1], Self);
    FAMgr.Unsubscribe(NID_PLUGIN_UNLOADING, Self);
  end;
end;
function TServiceRemoteSQL.CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
begin
  //可以在这里做安全监测,以后会在代理层里面统一做授权，拦截等
  Result := True;
end;
function TServiceRemoteSQL.Login(aRecvStr: AnsiString; var Error: string): RawJSON;
begin
  Result := '{"data":"登录成功"}';
end;
function TServiceRemoteSQL.RecvDataGeneralControl(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
begin
  Result := '';
  {$REGION '登录'}
  if PosEx('logininfo/1.0',aUrlPath) > 0 then
  begin
    if not CheckRecvData(aRecvStr,Error) then
    begin
      Exit;
    end
    else
    begin
      Result := Login(aRecvStr,Error);
    end;
  end;
  {$ENDREGION}
end;


initialization
// 注册服务
RegisterServices('Services/'+ConstAppTaskNo,
  [TServiceRemoteSQL.Create(NewId, ConstAppTaskUserNo)]);
finalization
// 取消服务注册
UnregisterServices('Services/'+ConstAppTaskNo, [ConstAppTaskUserNo]);
end.
