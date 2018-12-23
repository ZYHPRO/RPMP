unit Gl_ServerConst;
interface
Const
    SystemSetFileName  = 'SystemConfig.ini';
   //连接信息
type
  //数据库结构
  TDatabaseParam = record
    ServerName: string;
    UserNmae: string;
    PassName: string;
    DatebaseName: string;
  end;
  TOnConnectEvent  = procedure (CIDStr,IPStr,LoginTimeStr,PortStr : string) of object;
  TConnectInfo=class(TObject)
  public
   ConnetString:string;
  end;
  //服务器信息
  TDataSnapServerInfo=class(TObject)
  public
   OnAddConnectEvent: TOnConnectEvent; //上线事件
   OnDeleteConnectEvent: TOnConnectEvent; //下线事件
   TcpServerIP: string;        //服务器地址(Tcp)
   TcpPort:Integer;            //服务端端口(Tcp)
   HttpServerIP: string;       //服务器地址(Http)
   HttpPort: Integer;          //服务端端口(Http)
   bActive:Boolean;            //自启动
   ConnectionCount:Integer;    //数据库链接池数
   ConnectCount:Integer;       //服务端最大链接数
   iFactoryMode:Integer;       //服务端服务模式
   DriverName:string;          //数据库驱动
   ADOConnetStr:String;        //数据库链接字符串
   DatabaseParam: TDatabaseParam; //数据库连接参数
   bLoginOnly:Boolean;         //同一用户不可重复登陆
   bsetOK:Boolean;             //配置无错
   ConnLoginUser: string;      //连接服务器名用户名
   ConnLoginPassword: string;  //连接服务器名密码
end;
var
  VAR_ProgramPath:String;
  FLogFilePath: string;
  VAR_SQLDBCount:Integer;
  Var_ConnectInfo:TConnectInfo;
  Var_ServerInfo:TDataSnapServerInfo;
implementation

end.

