{
功能：代理层接口实现单元
作者: zhyhui
Date: 2018-12-07
}
unit uRouteProxyInstance;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,qjson, QString, QPlugins, Vcl.Imaging.jpeg,qplugins_base,
  uRouteProxyFunc,SynCommons,TaskServerIntf;
type

  TPubRouteProxy = class(TQService, IRouteProxy)
  private
    RecvJson,aQjson: TQJson;
  protected
    //业务校验数据正确与否
    function CheckWorkData(aRecvStr: AnsiString; var Error: string): Boolean; stdcall;
    //业务路由分流
    function RouteWorkData(aRecvStr: AnsiString; var Error: string): RawJSON; overload;  stdcall;
    //业务路由分流
    function RouteWorkData(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON; overload; stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW); overload; override;
    destructor Destroy; override;
  end;


implementation

constructor TPubRouteProxy.Create(const AId: TGuid; AName: QStringW);
begin
  inherited Create(AId, AName);
  RecvJson := TQJson.Create;
  aQjson := TQJson.Create;
end;

destructor TPubRouteProxy.Destroy;
begin
  FreeAndNil(RecvJson);
  FreeAndNil(aQjson);
  inherited;
end;

function TPubRouteProxy.CheckWorkData(aRecvStr: AnsiString; var Error: string): Boolean;
begin
  result := False;
end;
function  TPubRouteProxy.RouteWorkData(aRecvStr: AnsiString; var Error: string): RawJSON;
begin
  result := '';
end;
function  TPubRouteProxy.RouteWorkData(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
var
  ACtrl: IRemoteSQL;
  AppTaskNo,AppTaskUserNo,vStr,vData: string;
begin
  try
    result := '{}';
    RecvJson.Clear;
    {$REGION '测试解析数据'}
    if not RecvJson.TryParse(aRecvStr) then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := 'json串解析失败,不是合法json格式数据';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    {$ENDREGION}
    //解析数据
    RecvJson.Parse(aRecvStr);
    {$REGION '异常检测'}
    if RecvJson.IndexOf('usercode') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := '未查找到用户编码节点,不是合法json格式数据';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    if RecvJson.IndexOf('perjmcode') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := '未查找到签名编码节点,不是合法json格式数据';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    if RecvJson.IndexOf('tasktype') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := '未查找到业务码节点,不是合法json格式数据';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    if RecvJson.IndexOf('taskuser') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := '未查找到用户码节点,不是合法json格式数据';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    {$ENDREGION}
    {
    新增加: 通过url路由方式进行路由分流,可以通过一层层的解析判断URL地址进入不同的业务插件模块
    目前提供了两种路由方式：
      1、 可以单独使用url路由方式，
      2、 可以单独使用业务json串路由方式，
      3、 还可以两者结合一块使用
    目前的代码就是两种方式结合使用,具体怎么使用，根据自己的需求选择即可
    /* mORmot 作者真是变态啊，像这样的函数 PosEx，全是汇编实现,怪不得性能这么强大 */
    }
    //url示例: http://127.0.0.1:8080/RpmpData/logininfo/1.0
    if PosEx('/RpmpData',aUrlPath) > 0 then
    begin
      {$REGION '这里是通过业务josn串，进行路由分流'}
      AppTaskNo := RecvJson.ItemByName('tasktype').AsString;
      case StrToInt(AppTaskNo) of
        100:
        Begin
          {$REGION '苹果业务'}
          AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
          case StrToInt(AppTaskUserNo)of
            100101:
            Begin
              {$REGION '北京客户'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := '业务处理异常,未查找到业务插件模块';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
            100102:
            Begin
              {$REGION '上海客户'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := '业务处理异常,未查找到业务插件模块';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
          else
          begin
            aQjson.Clear;
            aQjson.Add('message','error',jdtString);
            vData := '该业户码不存在';
            vStr := '1'+vData;
            aQjson.Add('perjmcode','',jdtString);
            aQjson.Add('resultdata','1',jdtString);
            aQjson.Add('data',vData,jdtString) ;
            Error := aQjson.ToString;
            result := aQjson.ToString;
          end;
          end
          {$ENDREGION}
        end;
        200:
        Begin
          {$REGION '香蕉业务'}
          AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
          case StrToInt(AppTaskUserNo)of
            200101:
            Begin
              {$REGION '北京'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := '业务处理异常,未查找到业务插件模块';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
            200102:
            Begin
              {$REGION '上海'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := '业务处理异常,未查找到业务插件模块';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
          else
          begin
            aQjson.Clear;
            aQjson.Add('message','error',jdtString);
            vData := '该业户码不存在';
            vStr := '1'+vData;
            aQjson.Add('perjmcode','',jdtString);
            aQjson.Add('resultdata','1',jdtString);
            aQjson.Add('data',vData,jdtString) ;
            Error := aQjson.ToString;
            result := aQjson.ToString;
          end;
          end
          {$ENDREGION}
        end;
      else
      begin
        aQjson.Clear;
        aQjson.Add('message','error',jdtString);
        vData := '该业务码不存在';
        vStr := '1'+vData;
        aQjson.Add('perjmcode','',jdtString);
        aQjson.Add('resultdata','1',jdtString);
        aQjson.Add('data',vData,jdtString) ;
        Error := aQjson.ToString;
        result := aQjson.ToString;
      end;
      end;
      {$ENDREGION}
    end;
    //url示例: http://127.0.0.1:8080/RpmpQuery/QueryData/logininfo/1.0
    if PosEx('/RpmpQuery',aUrlPath) > 0 then
    begin
      if PosEx('/QueryData',aUrlPath) > 0 then
      begin
        {$REGION '这里是通过业务josn串，进行路由分流'}
        AppTaskNo := RecvJson.ItemByName('tasktype').AsString;
        case StrToInt(AppTaskNo) of
          100:
          Begin
            {$REGION '苹果业务'}
            AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
            case StrToInt(AppTaskUserNo)of
              100101:
              Begin
                {$REGION '北京客户'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := '业务处理异常,未查找到业务插件模块';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
              100102:
              Begin
                {$REGION '上海客户'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := '业务处理异常,未查找到业务插件模块';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
            else
            begin
              aQjson.Clear;
              aQjson.Add('message','error',jdtString);
              vData := '该业户码不存在';
              vStr := '1'+vData;
              aQjson.Add('perjmcode','',jdtString);
              aQjson.Add('resultdata','1',jdtString);
              aQjson.Add('data',vData,jdtString) ;
              Error := aQjson.ToString;
              result := aQjson.ToString;
            end;
            end
            {$ENDREGION}
          end;
          200:
          Begin
            {$REGION '香蕉业务'}
            AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
            case StrToInt(AppTaskUserNo)of
              200101:
              Begin
                {$REGION '北京'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := '业务处理异常,未查找到业务插件模块';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
              200102:
              Begin
                {$REGION '上海'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := '业务处理异常,未查找到业务插件模块';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
            else
            begin
              aQjson.Clear;
              aQjson.Add('message','error',jdtString);
              vData := '该业户码不存在';
              vStr := '1'+vData;
              aQjson.Add('perjmcode','',jdtString);
              aQjson.Add('resultdata','1',jdtString);
              aQjson.Add('data',vData,jdtString) ;
              Error := aQjson.ToString;
              result := aQjson.ToString;
            end;
            end
            {$ENDREGION}
          end;
        else
        begin
          aQjson.Clear;
          aQjson.Add('message','error',jdtString);
          vData := '该业务码不存在';
          vStr := '1'+vData;
          aQjson.Add('perjmcode','',jdtString);
          aQjson.Add('resultdata','1',jdtString);
          aQjson.Add('data',vData,jdtString) ;
          Error := aQjson.ToString;
          result := aQjson.ToString;
        end;
        end;
        {$ENDREGION}
      end
    end;
  except
    on e: Exception do
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := '未知错误,错误信息: '+e.Message;
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
    end;
  end;
end;

initialization
// 注册 /Services/PubRouteProxys/PubRouteProxy 服务
RegisterServices('Services/PubRouteProxys',
  [TPubRouteProxy.Create(NewId, 'PubRouteProxy')]);
finalization
// 取消服务注册
UnregisterServices('Services/PubRouteProxys', ['PubRouteProxy']);
end.
