unit ViewForm;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, TAGraph, TASeries, ExtCtrls, EditBtn;

type

  { TfViewMeas }

  TfViewMeas = class(TForm)
      ChartMeas: TChart;
      FilenameEdit1: TFileNameEdit;
    Panel1: TPanel;
    Button1: TButton;
    btnCopyToClipboard: TButton;
    procedure Button1Click(Sender: TObject);
    procedure btnCopyToClipboardClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fViewMeas: TfViewMeas;

implementation
uses ClipBrd, Zamhdr, ZAMCLASS;

{$R *.lfm}


var Buf: array [1..1024*1024] of TReal64;


function OrderToName(i: integer): string;
begin
if (i<1) or (i>42) then
    Exit('');

Result:=IntToStr(((i-1) div 3)+1);
case i mod 3 of
1: Result:=Result+'В';
2: Result:=Result+'П';
0: Result:=Result+'О';
end
end;


procedure TfViewMeas.Button1Click(Sender: TObject);
var f: TZamerFile;
    i,j: integer;
    Tabl : TTabl;
    freq: double;
    Series1: TLineSeries;
begin

ChartMeas.ClearSeries;

f:=TZamerFile.Create(FilenameEdit1.Text);
f.Lock;

// Так можно получить RPM
f.GetTechParam(70,freq);
freq:=freq/60;

// Перебираем все сигналы
for i:=1 to f.GetMaxTabl() do begin
    // Параметры сигнала
    f.GetTabl(i,Tabl);
    if Tabl.Exist=1 then begin
       f.GetStamps(i,Buf,Tabl.AllX*SizeOf(TReal64));


       Series1:= TLineSeries.Create(ChartMeas);
       Series1.BeginUpdate;
       Series1.Title:='#'+IntToStr(i) + '  ' + OrderToName(i);
       Series1.SeriesColor := Random($FFFFFF);

       if Tabl.Tip=ztSpectr then ChartMeas.BottomAxis.Title.Caption:='Hz'
          else ChartMeas.BottomAxis.Title.Caption:='sec';

       if Tabl.EdIzm=eiAcceleration then ChartMeas.LeftAxis.Title.Caption:='m/s2'
       else if Tabl.EdIzm=eiVelocity then ChartMeas.LeftAxis.Title.Caption:='mm/s'
       else if Tabl.EdIzm=eiDisplacement then ChartMeas.LeftAxis.Title.Caption:='um'
       else ChartMeas.LeftAxis.Title.Caption:='V';

       for j:=1 to Tabl.AllX do begin
           Series1.AddXY((j-1)*Tabl.dX,Buf[j]);
       end;

       Series1.EndUpdate;
       ChartMeas.AddSeries(Series1);

    end;
end;

f.UnLock;
f.Destroy;

btnCopyToClipboard.Enabled := (ChartMeas.SeriesCount > 0) and (Series1.Count>0);

end;




procedure TfViewMeas.btnCopyToClipboardClick(Sender: TObject);
var cnt, i, ser, Cur: Integer;
	s: string;
    Buf: PChar;
    Series1: TLineSeries;
begin
if (ChartMeas.SeriesCount = 0) then
	Exit;

Series1:=TLineSeries(ChartMeas.Series[0]);
if (Series1.Count = 0) then
	Exit;

cnt:=Series1.Count;

GetMem(Buf, cnt*(ChartMeas.SeriesCount+1)*32);
Cur:=0;

s:=ChartMeas.BottomAxis.Title.Caption;
for ser:=0 to ChartMeas.SeriesCount-1 do begin
	s:=s+#9+'#'+IntToStr(ser+1);
end;
s:=s+#$D+#$A;
StrPCopy(Buf+Cur,s); inc(Cur,Length(s));

for i:=0 to cnt-1 do begin
    s:=FloatToStr(TLineSeries(ChartMeas.Series[0]).XValue[i]);
    for ser:=0 to ChartMeas.SeriesCount-1 do begin
        s:=s+#9+FloatToStr(TLineSeries(ChartMeas.Series[ser]).YValue[i]);
    end;
	s:=s+#$D+#$A;
	StrPCopy(Buf+Cur,s); inc(Cur,Length(s));
end;

Buf[Cur]:=#0;
Clipboard.SetTextBuf(Buf);
FreeMem(Buf)

end;

end.

