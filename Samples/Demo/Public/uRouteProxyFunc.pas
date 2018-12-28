{
功能：代理层接口单元
@author: zhyhui
@date:  2018-12-07
}
unit uRouteProxyFunc;

interface
uses
  Winapi.Windows, Winapi.Messages,System.SysUtils, System.Variants,System.Classes,SynCommons;
type
  IRouteProxy = interface
    ['{CB30EDE0-6FDF-4E0E-B520-88AE9374D1C1}']
    //业务校验数据正确与否
    function CheckWorkData(aRecvStr: AnsiString; var Error: string): Boolean; stdcall;
    //业务路由分流
    function RouteWorkData(aRecvStr: AnsiString; var Error: string): RawJSON; overload; stdcall;
    //业务路由分流
    function RouteWorkData(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON; overload; stdcall;
  end;
implementation

end.
