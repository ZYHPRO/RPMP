unit uPubHttpServer;

interface
uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils,System.Classes,System.ImageList,System.IniFiles,
  Soap.EncdDecd,FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,FireDAC.Comp.Client,
  Data.DB,EDDES,GL_ServerFunction,GL_ServerConst,SynCommons,
  SynLog,SynCrtSock,SynZip,PubConst,uRouteProxyFunc,
  QPlugins, QPlugins_loader_lib,QPlugins_Vcl_Messages;
  {$I SynDprUses.inc} // use FastMM4 on older Delphi, or set FPC threads

type
  TPubRestServer = class
  protected
    FListenPort: string;
    FPath: TFileName;
    FServer: THttpApiServer;
    FIRProxy: IRouteProxy;         //路由代理插件
    FPostRequestCount: Integer;
    FGetRequestCount: Integer;
    function Process(Ctxt: THttpServerRequest): cardinal;
  public
    constructor Create(const Path: TFileName;ListenPort: string);
    destructor Destroy; override;
    property GetRequestCount: Integer  read FGetRequestCount;
    property PostRequestCount: Integer  read FPostRequestCount;
  end;

implementation
{ TTestServer }
constructor TPubRestServer.Create(const Path: TFileName;ListenPort: string);
begin
  FListenPort := ListenPort;
  fServer := THttpApiServer.Create(false);
  fServer.AddUrl('',FListenPort,false,'+',true);
  fServer.RegisterCompress(CompressGZip);
  fServer.OnRequest := Process;
  FServer.Clone(7);
  fPath := IncludeTrailingPathDelimiter(Path);
  FIRProxy := PluginsManager.ByPath('Services/PubRouteProxys/PubRouteProxy') as IRouteProxy;
  FPostRequestCount := 0;
  FGetRequestCount := 0;
end;

destructor TPubRestServer.Destroy;
begin
  fServer.RemoveUrl('',StringTOUTF8(FListenPort), False, '+');
  fServer.Free;
  inherited;
end;

{$WARN SYMBOL_PLATFORM OFF}

function TPubRestServer.Process(Ctxt: THttpServerRequest): cardinal;
var
  W: TTextWriter;
  FileName: TFileName;
  FN, SRName, href: RawUTF8;
  i: integer;
  SR: TSearchRec;
  OutError: string;
  ResultJson: RawJSON;
  procedure hrefCompute;
  begin
    SRName := StringToUTF8(SR.Name);
    href := FN+StringReplaceChars(SRName,'\','/');
  end;
begin
  {$REGION 'GET Method'}
  if Ctxt.Method = 'GET' then
  begin
    Inc(FGetRequestCount);
    if not IdemPChar(pointer(Ctxt.URL),'/ROOT')  then begin
      result := 404;
      exit;
    end;
    FN := StringReplaceChars(UrlDecode(copy(Ctxt.URL,7,maxInt)),'/','\');
    if PosEx('..',FN)>0 then begin
      result := 404; // circumvent obvious potential security leak
      exit;
    end;
    while (FN<>'') and (FN[1]='\') do
      delete(FN,1,1);
    while (FN<>'') and (FN[length(FN)]='\') do
      delete(FN,length(FN),1);
    FileName := fPath+UTF8ToString(FN);
    if DirectoryExists(FileName) then begin
      // reply directory listing as html
      W := TTextWriter.CreateOwnedStream;
      try
        W.Add('<html><body style="font-family: Arial">'+
          '<h3>%</h3><p><table>',[FN]);
        FN := StringReplaceChars(FN,'\','/');
        if FN<>'' then
          FN := FN+'/';
        if FindFirst(FileName+'\*.*',faDirectory,SR)=0 then begin
          repeat
            if (SR.Attr and faDirectory<>0) and (SR.Name<>'.') then begin
              hrefCompute;
              if SRName='..' then begin
                i := length(FN);
                while (i>0) and (FN[i]='/') do dec(i);
                while (i>0) and (FN[i]<>'/') do dec(i);
                href := copy(FN,1,i);
              end;
              W.Add('<tr><td><b><a href="/root/%">[%]</a></b></td></tr>',[href,SRName]);
            end;
          until FindNext(SR)<>0;
          FindClose(SR);
        end;
        if FindFirst(FileName+'\*.*',faAnyFile-faDirectory-faHidden,SR)=0 then begin
          repeat
            hrefCompute;
            if SR.Attr and faDirectory=0 then
              W.Add('<tr><td><b><a href="/root/%">%</a></b></td><td>%</td><td>%</td></td></tr>',
                [href,SRName,KB(SR.Size),DateTimeToStr(
                  {$ifdef ISDELPHIXE2}SR.TimeStamp{$else}FileDateToDateTime(SR.Time){$endif})]);
          until FindNext(SR)<>0;
          FindClose(SR);
        end;
        W.AddShort('</table></p><p><i>Powered by mORMot''s <strong>');
        W.AddClassName(Ctxt.Server.ClassType);
        W.AddShort('</strong></i> - '+
          'see <a href=http://synopse.info>http://synopse.info</a></p></body></html>');
        Ctxt.OutContent := W.Text;
        Ctxt.OutContentType := HTML_CONTENT_TYPE;
        result := 200;
      finally
        W.Free;
      end;
    end
    else
    begin
      // http.sys will send the specified file from kernel mode
      Ctxt.OutContent := StringToUTF8(FileName);
      Ctxt.OutContentType := HTTP_RESP_STATICFILE;
      result := 200; // THttpApiServer.Execute will return 404 if not found
    end;
  end;
  {$ENDREGION}
  {$REGION 'POST Method'}
  if Ctxt.Method = 'POST' then
  begin
    Inc(FPostRequestCount);
    try
      W := TTextWriter.CreateOwnedStream;
      ResultJson := FIRProxy.RouteWorkData(Ctxt.URL,Utf8ToAnsi(Ctxt.InContent),OutError);
      if Trim(OutError) <> '' then
      begin
        W.Add('%',[ResultJson]);
      end
      else
      begin
        W.Add('%',[ResultJson]);
      end;
      Ctxt.OutContent := W.Text;
      Ctxt.OutContentType := HTML_CONTENT_TYPE;
      result := 200;
    finally
      W.Free;
    end;
  end;
  {$ENDREGION}
end;

end.
