unit uPubVariableSet;

interface
uses
  System.SysUtils, System.Variants, System.Classes;
const
  /// <summary>
  /// 软件开始运行通知
  /// </summary>
  NotifyServerStart  = 'ServerStart';
  /// <summary>
  /// 软件停止运行通知
  /// </summary>
  NotifyServerStop  = 'ServerStop';
var
  FChangeNotifyId: array[0..1] of Integer;          //通知
implementation

end.
