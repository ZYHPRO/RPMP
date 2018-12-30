{
功能：业务接口实现单元
author : zhyhui
date: 2018-12-08
}

unit uTaskPlugDLL;

interface

uses
  Winapi.Windows,Graphics, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  TaskServerIntf,SynCommons,System.StrUtils,System.DateUtils,sfLog,
  QString, QPlugins,qplugins_base;
const
  ConstAppTaskNo = '100';    //苹果业务
  ConstAppTaskUserNo = '100101';   //北京客户
type
  TServiceRemoteSQL = class(TQService, IRemoteSQL)
  private
    FAppTaskNo: string;          //业务模型编号
    FAppTaskUserNo: string;      //业务客户编号
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

  TRemoteSQLService = class(TQService)
  public
    function GetInstance: IQService; override; stdcall;
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
end;
destructor TServiceRemoteSQL.Destroy;
begin
  inherited;
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

function TRemoteSQLService.GetInstance: IQService;
begin
  Result := TServiceRemoteSQL.Create(NewId, ConstAppTaskNo+ConstAppTaskUserNo+'Service');
end;
initialization
// 注册服务
RegisterServices('Services/'+ConstAppTaskNo,
  [TRemoteSQLService.Create(IRemoteSQL, ConstAppTaskUserNo)]);
finalization
// 取消服务注册
UnregisterServices('Services/'+ConstAppTaskNo, [ConstAppTaskUserNo]);
end.
