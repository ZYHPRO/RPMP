library TaskPlugDBDLL;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  System.ShareMem,
  System.SysUtils,
  System.Classes,
  sfLog in '..\..\Public\sfLog.pas',
  TaskServerIntf in '..\..\Public\TaskServerIntf.pas',
  GL_ServerConst in '..\..\Public\GL_ServerConst.pas',
  GL_ServerFunction in '..\..\Public\GL_ServerFunction.pas',
  Impl_MsConnectionPool in '..\..\Public\Impl_MsConnectionPool.pas',
  Intf_MsConnectionPool in '..\..\Public\Intf_MsConnectionPool.pas',
  MsDataBasePool in '..\..\Public\MsDataBasePool.pas',
  uTaskPlugDBDLL in 'uTaskPlugDBDLL.pas';

{$R *.res}

begin
end.
