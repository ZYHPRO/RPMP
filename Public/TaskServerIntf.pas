{
功能：从业资格业务接口单元
author : zhyhui
date: 2018-12-08
}
unit TaskServerIntf;

interface
  uses SynCommons,mORMot;
type
  IRemoteSQL = interface(IInvokable)
   ['{051C8EC8-921D-4248-88E8-489E3B869F50}']
    //接收数据总处理
    function RecvDataGeneralControl(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
    //校验数据正确与否
    function CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
    //登录验证
    function Login(aRecvStr: AnsiString; var Error: string): RawJSON;
  end;
implementation

end.
