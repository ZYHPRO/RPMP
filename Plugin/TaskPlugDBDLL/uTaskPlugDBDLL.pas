{
功能：业务接口实现单元
author : zhyhui
date: 2018-12-08
}

unit uTaskPlugDBDLL;

interface

uses
  Winapi.Windows,Graphics, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  TaskServerIntf,SynCommons,System.StrUtils,System.DateUtils,sfLog,GL_ServerFunction,Gl_ServerConst,
  Data.DB,FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Phys.MSSQLDef,
  FireDAC.Phys.ODBCBase, FireDAC.Phys.MSSQL, FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  Datasnap.DBClient, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageXML,
  FireDAC.Stan.StorageBin,Data.FireDACJSONReflect,Data.DBXPlatform,
  qjson,QString, QPlugins,qplugins_base;
const
  ConstAppTaskNo = '200';    //香蕉业务
  ConstAppTaskUserNo = '200101';   //北京客户
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
  //创建数据库连接池
  Var_ServerInfo :=TDataSnapServerInfo.Create;
  //这里是数据库连接字符串,数据库目前使用的 MSSQL ,你可以换成 mysql 等等,Firdac支持N多数据库，看你的应用
  Var_ServerInfo.ADOConnetStr := 'Name=Unnamed;DriverID=MSSQL;Server=.;Database=kbg;User_Name=sa;Password=sql';
  SetLength(arrDataBasePool,1);
  SetLength(VAR_ArrSQLConStr,1);
  Var_ServerInfo.ConnectionCount := 2;
  VAR_ArrSQLConStr[0] := Var_ServerInfo.ADOConnetStr; //第一个链接池初始化
  CreateDataBasePool(0,Var_ServerInfo.ConnectionCount);

end;
destructor TServiceRemoteSQL.Destroy;
begin
  //关闭数据库连接
  CloseDataBasePool;
  FreeAndNil(Var_ServerInfo);
  inherited;
end;
function TServiceRemoteSQL.CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
begin
  //可以在这里做安全监测,以后会在代理层里面统一做授权，拦截等
  Result := True;
end;
function TServiceRemoteSQL.Login(aRecvStr: AnsiString; var Error: string): RawJSON;
var
  Connection: TFDConnection;
  TempQuery :TFDQuery;
  aQjson,tmpQjson,resultqjson: TQJson;
  kwArry: array of TQJson;
  i: Integer;
  QSQL,vData: string;
begin
  try
    aQjson := TQJson.create;
    tmpQjson := TQJson.create;
    Connection := arrDataBasePool[0].GetConnectionDB;    //创建或匹配一个线程池
    TempQuery := TFDQuery.Create(nil);
    TempQuery.Connection := TFDConnection(Connection); //实例化
    QSQL := 'select * from T_PersonInfo';  //
    with TempQuery do
    begin
      SQL.Text := QSQL;
      FetchOptions.Mode := fmAll;
      Open;
      if recordcount > 0 then
      begin
        SetLength(kwArry,TempQuery.RecordCount);
        i := 0;
        while not TempQuery.eof do
        begin
          tmpqjson := TQJson.Create;
          tmpQjson.Clear;
          tmpQjson.Add('ID',TempQuery.FieldByName('ID').AsString,jdtString);
          tmpQjson.Add('PerName',TempQuery.FieldByName('PerName').AsString,jdtString);
          tmpQjson.Add('PerIdCard',TempQuery.FieldByName('PerIdCard').AsString,jdtString);
          kwArry[i] := tmpQjson;
          Inc(i);
          TempQuery.Next;
        end;
        //组织返回语句
        aQjson.Clear;
        aQjson.Add('message','ok',jdtString);
        vData := '';
        aQjson.Add('perjmcode','',jdtString);
        aQjson.Add('datacount', IntToStr(TempQuery.RecordCount),jdtString);
        resultqjson := aQjson.AddArray('datalist');
        for I := Low(kwArry) to High(kwArry) do
         resultqjson.Add(kwArry[i]);
        aQjson.Add('resultdata','0',jdtString);
        aQjson.Add('data',vData,jdtString);
        Result := aQjson.ToString;
      end
      else
      begin
        //组织返回语句
        aQjson.Clear;
        aQjson.Add('message','ok',jdtString);
        vData := '';
        aQjson.Add('perjmcode','',jdtString);
        aQjson.Add('datacount','0',jdtString);
        aQjson.AddArray('datalist');
        aQjson.Add('resultdata','0',jdtString);
        aQjson.Add('data',vData,jdtString);
        Result := aQjson.ToString;
      end;
    end;
  finally
    arrDataBasePool[0].FreeConnectionDB(Connection);  //解锁一个线程池
    TempQuery.Close;                            //释放数据集
    FreeAndNil(TempQuery);
    FreeAndNil(aQjson);
  end;
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
