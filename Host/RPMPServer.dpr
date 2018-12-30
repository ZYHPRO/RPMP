program RPMPServer;

uses
  System.ShareMem,
  Vcl.Forms,
  Vcl.Controls,
  Windows,
  Web.WebReq,
  uServerMain in 'uServerMain.pas' {frmServerMain},
  uServerSet in 'uServerSet.pas' {frmServerSet},
  EDDES in '..\Public\EDDES.pas',
  GL_ServerConst in '..\Public\GL_ServerConst.pas',
  PubConst in '..\Public\PubConst.pas',
  sfLog in '..\Public\sfLog.pas',
  uRouteProxyFunc in '..\Public\uRouteProxyFunc.pas',
  GL_ServerFunction in '..\Public\GL_ServerFunction.pas',
  Impl_MsConnectionPool in '..\Public\Impl_MsConnectionPool.pas',
  Intf_MsConnectionPool in '..\Public\Intf_MsConnectionPool.pas',
  MsDataBasePool in '..\Public\MsDataBasePool.pas',
  uPubHttpServer in 'uPubHttpServer.pas';

{$R *.res}
var
  Hmutex:HWND;
begin
  Application.Initialize;
    ///不许进行打开多次
  Application.Title := 'RPMP服务器';
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmServerMain, frmServerMain);
  Application.Run;
end.

