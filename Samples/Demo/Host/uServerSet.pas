unit uServerSet;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,System.IniFiles,EDDES,
  GL_ServerFunction,GL_ServerConst;

type
  TfrmServerSet = class(TForm)
    Panel1: TPanel;
    grpTransmission: TGroupBox;
    edtTcpPort: TLabeledEdit;
    edtEncryptionKey: TLabeledEdit;
    edtMaxConnectionNumber: TLabeledEdit;
    edtHttpPort: TLabeledEdit;
    grpMisc: TGroupBox;
    chkRunOnStartup: TCheckBox;
    chkGlobalLogEnabled: TCheckBox;
    ChkActive: TCheckBox;
    Panel2: TPanel;
    Button1: TButton;
    Button2: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmServerSet: TfrmServerSet;

implementation

{$R *.dfm}

procedure TfrmServerSet.Button1Click(Sender: TObject);
var
  ConfigIni: TIniFile;
begin
  try
    ConfigIni := TIniFile.Create(ExtractFilePath(Application.ExeName)+SystemSetFileName); //读取Ini
    try
      ConfigIni.WriteString('ServerSet','TcpPort',Trim(edtTcpPort.Text));
      ConfigIni.WriteString('ServerSet','HttpPort',Trim(edtHttpPort.Text));
      ConfigIni.WriteString('ServerSet','ConnectCount',Trim(edtMaxConnectionNumber.Text));
      if chkGlobalLogEnabled.Checked then
      begin
        ConfigIni.WriteString('ServerSet','SqlLog','1');
      end
      else
      begin
        ConfigIni.WriteString('ServerSet','SqlLog','0');
      end;
      if chkRunOnStartup.Checked then
      begin
        ConfigIni.WriteString('ServerSet','Startup','1');
      end
      else
      begin
        ConfigIni.WriteString('ServerSet','Startup','0');
      end;
      if ChkActive.Checked then
      begin
        ConfigIni.WriteString('ServerSet','SetActive','1');
      end
      else
      begin
        ConfigIni.WriteString('ServerSet','SetActive','0');
      end;
      Application.MessageBox('保存成功','提示',MB_OK+MB_ICONINFORMATION);
    except
      on e: Exception do
      begin
        Application.MessageBox(PChar('保存失败,错误信息:'+e.Message),'提示',MB_OK+MB_ICONINFORMATION);
      end;
    end;
  finally
    FreeAndNil(ConfigIni);
  end;
end;

procedure TfrmServerSet.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmServerSet.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ModalResult := mrOk;
end;

procedure TfrmServerSet.FormCreate(Sender: TObject);
var
  ConfigIni: TIniFile;
  vStr: string;
begin
  try
    ConfigIni := TIniFile.Create(ExtractFilePath(Application.ExeName)+SystemSetFileName); //读取Ini
    try
      edtTcpPort.Text := ConfigIni.ReadString('ServerSet','TcpPort','211');
      edtHttpPort.Text := ConfigIni.readstring('ServerSet','HttpPort','8080');
      edtMaxConnectionNumber.Text := ConfigIni.readstring('ServerSet','ConnectCount','50');
      vStr := ConfigIni.ReadString('ServerSet','SqlLog','0');
      if vStr ='1' then
      begin
         chkGlobalLogEnabled.Checked := True;
      end
      else
      begin
         chkGlobalLogEnabled.Checked := False;
      end;
      vStr := ConfigIni.ReadString('ServerSet','Startup','0');
      if vStr ='1' then
      begin
        chkRunOnStartup.Checked := True;
      end
      else
      begin
        chkRunOnStartup.Checked := False;
      end;
      vStr := ConfigIni.ReadString('ServerSet','SetActive','0');
      if vStr ='1' then
      begin
        ChkActive.Checked := True;
      end
      else
      begin
        ChkActive.Checked := False;
      end;
    except
    end;
  finally
    FreeAndNil(ConfigIni);
  end;
end;

end.
