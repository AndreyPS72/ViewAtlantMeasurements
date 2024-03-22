(*
                                                  Вибро-Центр (г. Пермь)
                                                  and@vibrocenter.ru

    Описание класса, реализующего управление файлом замера версии 3.01 для Atlant
    Начато                              02.10.97
    Последние изменения и дополнения    02.08.23

    History :

    02.08.23    GetFreeName() теперь можно передавать aPrefix: String, а не один символ

    07.11.22    Рефакторинг

    05.10.16    Выкинул поддержку WIN16

    18.05.15    Убрал var в aLen в функциях SetGlobalTag, SetLocalTag

    11.03.15    Небольшие исправления в типах переменных

    15.09.14    Ошибка при загрузке длинных спектров с фазой
                Убрал лишние выделения памяти
                Убрал доступ к массиву через HugeOffset для WIN32
                Убрал uses JvJCLUtils,JvJVCLUtils // RX Library - требуется только для WIN16

  26.09.08   Исправил LongAnd, LongDec, LongDec1 под типы longword

  25.01.05   В GetTabl неправильно считывались таблицы, если их в замере было меньше

  23.04.04   Исправил GetFreeName. Теперь замеров на дату может быть больше 1000.
             Тогда расширение будет *.1000 ,*.1001 и т.д.

  14.05.03   Добавил SetStampsInt - Записать int отсчеты
             Только для сигналов

  16.10.02   Вставил $R- Убрать проверку индекса

  13.03.01   Выбросил StrConst - все ошибки теперь на английском языке

  20.10.00   Вставил GetStampsInt - чтение целых слов-отсчетов
             Только для временного сигнала нового формата !
             Удобно для обработки отметчика.

  28.10.99   Вставил IsReadOnly - файл только для чтения
             Отдельно открытие только на чтение [default] и на запись-чтение:
             методы DoOpen и DoOpenWrite. На использование модуля не влияет.

  25.08.99   Вставил установку битовых полей в CheckZamer в Any если они =0

  14.10.98   Исправил String[12] в GetFreeName (с'економили :)

  08.10.98   Добавил DecodeZamerDate, DecodeZamerTime, так как криво работают
           DecodeDate, DecodeTime с нашими TDate, TTime в Delphi3.

  25.05.98    В связи с переделкой структуры замера, добавлена поддержка
           старых файлов замеров.
              DEFINE AllowOldFormat для поддержки старых файлов замеров.

  --------------------------------------------------------------------------

  22.12.97    Добавил LongAnd, LongDec, LongDec1, исправил TZamerFile.CheckZamer

  28.11.97    Исправил ошибку в GetStamps/SetStamps при чтении
           длинных замеров (>10000 отсчетов). Пришлось добавить
           uses VCLUtils (из RXLib) для HugeOffset, так как
           не понял как оно работает :)

  11.11.97    Добавил чтение/запись GetStamps/SetStamps/GetStampsLen для
           хранения фазы в спектре и гармоник.
              Теперь отсчеты    :
                 Спектр с фазой ((Option and opFaza)<>0) :
                    передаются в SetStamps : double    Ampl1,Faza1,Ampl2,Faza2, ...
                    хранятся в файле       : Integer Ampl1,Faza1,Ampl2,Faza2, ...
                       где AmplInt = Round(AmplReal/Scale)
                           FazaInt = Round(FazaReal*10) в градусах (приводится к диапазону -3000..3000)
                 Гармоники      :
                    и передаются в SetStamps и хранятся в файле :
                       double Freq1,Ampl1,Faza1,Power1,Freq2,Ampl2,Faza2,Power2, ...
                 Остальные      :
                    передаются в SetStamps : double    Ampl1,Ampl2, ...
                    хранятся в файле       : Integer Ampl1,Ampl2, ...
                       где AmplInt = Round(AmplReal/Scale)

              Исправил ошибку в SetTechParam (Димка Б. нашел ! (Б. - это фамилия :) ).

  21.10.97    Изменил чтение/запись GetStamps/SetStamps/GetStampsLen на
           работу с массивом double вместо Integer.
              Исключил ссылку на модуль Util - добавил AllTrim().

  02.10.97    Начало
*)

unit ZAMCLASS;

{$MODE Delphi}{$CODEPAGE UTF8}{$H+}


{$IFNDEF Work}
{$OPTIMIZATION OFF, NOREGVAR, NOUNCERTAIN, NOSTACKFRAME, NOPEEPHOLE, NOLOOPUNROLL, NOTAILREC, NOORDERFIELDS, NOFASTMATH, NOREMOVEEMPTYPROCS, NOCSE, NODFA} //debug Для отладки
{$ENDIF}




{ Включить поддержку старых файлов замеров }
//{$DEFINE AllowOldFormat}

{$A-} { На всякий случай убрать выравнивание }
{$R-} { Убрать проверку индекса }

interface
uses LCLIntf, LCLType, Zamhdr
{$IFDEF AllowOldFormat}
     , OldZHdr { Включить поддержку старых файлов замеров }
{$ENDIF}
     , SysUtils
     ;

Type EFailOpenFile = class(Exception);

Type TOrder = integer; { Номер строки TTabl в таблице }

     { Класс, реализующий управление файлом замера.
       Так как объект большой, не стоит создавать много
       экземпляров и надолго. }
Type TZamerFile = class
       constructor Create(const aFileName : String); { Создает объект из файла }

       { Создает объект и новый файл с aKolTabl местами под TTabl
         Порядок создания и записи замера :
             1. CreateNew(GetFreeName,_)
             2. GetZamerProperty-SetZamerProperty
             3. GetCommonParam-SetCommonParam
           [ 4. Запись таблиц
             5. Запись отсчетов/тэгов/технологических параметров ]
             6. Destroy
       }
       constructor CreateNew(const aFileName : String;aKolTabl : byte);
       destructor  Destroy;override;

     protected
       fFileName     : String;     { Имя файла }
       FileSelf      : integer;        { Ссылка на файл }
       OpenedCount   : integer;        { Счетчик открытий }
       OpenedWrite   : boolean;        { True - Открыт на запись }
       Locked        : integer;        { Счетчик блокирований открытия/закрытия }
       fReadOnly     : boolean; 

       ZamVersion    : integer;        { Версия замера 300,301 }
       ZamerSign     : TZamerSign;

       HeaderLoaded      ,                 { True - Соответствующая секция считана }
       PropertyLoaded    ,
       TechParamsLoaded  ,
       CommonParamsLoaded,
       GlobalTagsTableLoaded : boolean;

       ZamerHeader     : TZamerHeader;   { Заголовок замера - общие параметры }
       ZamerProperty   : TZamerProperty; { Диагностические признаки замера }
       TechParams      : TTechParam;     { Таблица технологических параметров }
       CommonParams    : TCommonParam;   { Остальные общие параметры для замера }
       GlobalTagsTable : TTagTable;      { Таблица тэгов }

       TekTabl       : TTabl;          { Текущая прочитанная таблица }
       TekTablOrder  : TOrder;         { Номер текущей таблицы. -1 - нет }

       procedure DoOpen;virtual;
       procedure DoOpenWrite;virtual;
       procedure DoClose;virtual;
       function  IsOpened : boolean;virtual;

     protected
       procedure WriteZamerSign;virtual;
       procedure WriteZamerHeader;virtual;
       procedure WriteZamerProperty;virtual;
       procedure WriteTechParam;virtual;
       procedure WriteCommonParam;virtual;
       procedure WriteTagTable;virtual;

     public
       procedure GetZamerSign(var aZamerSign : TZamerSign);virtual;
       procedure GetZamerHeader(var aZamerHeader : TZamerHeader);virtual;
       procedure SetZamerHeader(var aZamerHeader : TZamerHeader);virtual;
       procedure GetZamerProperty(var aZamerProperty : TZamerProperty);virtual;
       procedure SetZamerProperty(var aZamerProperty : TZamerProperty);virtual;
       procedure GetCommonParam(var aCommonParam : TCommonParam);virtual;
       procedure SetCommonParam(var aCommonParam : TCommonParam);virtual;

       function  GetTechParam(aNum : Ti16;var aVal : double) : boolean;virtual;
       procedure SetTechParam(aNum : Ti16;aVal : double);virtual;

       procedure GetGlobalTag(aTag : TTagNum;var aBuf; var aLen : longint);virtual;
       procedure SetGlobalTag(aTag : TTagNum;var aBuf; aLen : longint);virtual;
       function  GetGlobalTagLen(aTag : TTagNum) : longint;virtual;

       procedure GetLocalTag(aOrder : TOrder;aTag : TTagNum;var aBuf;var aLen : longint);virtual;
       procedure SetLocalTag(aOrder : TOrder;aTag : TTagNum;var aBuf; aLen : longint);virtual;
       function  GetLocalTagLen(aOrder : TOrder;aTag : TTagNum) : longint;virtual;

       procedure GetTabl(aOrder : TOrder;var aTabl : TTabl);virtual;
       procedure SetTabl(aOrder : TOrder;var aTabl : TTabl);virtual;
        { Число доступных для записи.чтения таблиц }
       function  GetMaxTabl : TOrder;virtual;
        { True - замер только для чтения }
       function  IsReadOnly : boolean;virtual;
     public
         { Lock/UnLock применяется для частых записей/чтений в файл -
           чтобы все время не открывать/закрывать файл.
           Пока IsLocked=True файл открыт, поэтому не оставлять
           его в таком состоянии долго. Lock/UnLock имеют приоритет
           выше, чем DoOpen/DoClose. }
       procedure Lock;virtual;
       procedure UnLock;virtual;
       function  IsLocked : boolean;virtual;

     public
          { Получить/записать отсчеты. aBuf - array of TReal64 любой длины aLen (в байтах) }
       function  GetStamps(aOrder : TOrder;var aBuf;aLen : longint):longint;virtual;
       function  SetStamps(aOrder : TOrder;var aBuf;aLen : longint):longint;virtual;
       function  GetStampsLen(aOrder : TOrder):longint;virtual;
       { Создает aBuf, читает слова-отсчеты
         Только для временного сигнала нового формата ! }
       function  GetStampsInt(aOrder : TOrder;var aBuf: THandle):longint;virtual;
       { Записать int отсчеты. Только для сигналов. aBuf - array of smallint любой длины aLen (в байтах) }
       function  SetStampsInt(aOrder : TOrder;var aBuf;aLen : longint):longint;virtual;

     public
        { True - если замер удовлетворяет условиям, заданным в CheckedProperty
          для определенной программы }
      function  CheckZamer(var CheckedProperty : TZamerProperty) : boolean;virtual;
      function  GetZamerVersion : integer;virtual; { Версия замера 300,301 }
end;


 { Возвращает доступное имя файла с расширением, по пути aPath и начинающийся с aPrefix }
function GetFreeName(aPath : String; aPrefix: String; aDate : TDateTime) : String;


{ Операции проверки над Longword }
function  LongAnd(l1,l2: Tu32):boolean;
function  LongDec(l1,l2: Tu32):boolean;
function  LongDec1(l1,l2: Tu32):boolean;


{ Работа с датами замеров }
procedure DecodeZamerDate(DT : TDateTime;var aDate : ZamHdr.TZamDate);
procedure DecodeZamerTime(DT : TDateTime;var aTime : ZamHdr.TZamTime);


implementation
uses LazFileUtils;


procedure DecodeZamerDate(DT : TDateTime;var aDate : ZamHdr.TZamDate);
var y,m,d:word;
begin
try
   DecodeDate(DT,y,m,d);
   aDate[1]:=y;
   aDate[2]:=m;
   aDate[3]:=d;
except
   aDate[1]:=1;
   aDate[2]:=1;
   aDate[3]:=1997;
end;
end;

procedure DecodeZamerTime(DT : TDateTime;var aTime : ZamHdr.TZamTime);
var h,m,s,ss:word;
begin
try
   DecodeTime(DT,h,m,s,ss);
   aTime[1]:=h;
   aTime[2]:=m;
   aTime[3]:=s;
except
   aTime[1]:=0;
   aTime[2]:=0;
   aTime[3]:=0;
end;
end;


constructor TZamerFile.Create(const aFileName : String);
begin
if FileSearch(aFileName,'')='' then
   raise EFailOpenFile.Create('No file');
fFileName:=aFileName;
FileSelf:=-1;
OpenedCount:=0;
Locked:=0;
OpenedWrite:= False;
TekTablOrder:=-1;
ZamVersion    := 0;
ZamerSign     := CurrentZamerSign;
FillChar(ZamerHeader,SizeOf(TZamerHeader),0);
FillChar(ZamerProperty,SizeOf(TZamerProperty),0);
FillChar(TechParams,SizeOf(TTechParam),0);
FillChar(CommonParams,SizeOf(TCommonParam),0);
FillChar(GlobalTagsTable,SizeOf(TTagTable),0);
HeaderLoaded     := False;
PropertyLoaded   := False;
TechParamsLoaded  := False;
CommonParamsLoaded:= False;
GlobalTagsTableLoaded  := False;
DoOpen;
try
   fReadOnly :=((SysUtils.FileGetAttr(aFileName) and SysUtils.faReadOnly)<>0);
   FileRead(FileSelf,ZamerSign,SizeOf(TZamerSign));
   if (ZamerSign=CurrentZamerSign) then ZamVersion:=ZamerVersion;
{$IFDEF AllowOldFormat}
   if (ZamerSign=OldCurrentZamerSign) then ZamVersion:=OldZamerVersion;
{$ENDIF}
   if ZamVersion=0 then
      raise EFailOpenFile.Create('Wrong file version');
finally
   DoClose;
end;
end;


constructor TZamerFile.CreateNew(const aFileName : String;aKolTabl : byte);
var i:integer;
    DT : TDateTime;
begin
fFileName:=aFileName;
FileSelf:=Integer(FileCreate(fFileName));
if FileSelf<=0 then
   raise EFailOpenFile.Create('Can''t create a file');
FileClose(FileSelf);
FileSelf:=-1;
fReadOnly := False;
OpenedCount:=0;
OpenedWrite:= False;
Locked:=0;
TekTablOrder:=-1;
FillChar(ZamerHeader,SizeOf(TZamerHeader),0);
FillChar(ZamerProperty,SizeOf(TZamerProperty),0);
FillChar(TechParams,SizeOf(TTechParam),0);
FillChar(CommonParams,SizeOf(TCommonParam),0);
FillChar(GlobalTagsTable,SizeOf(TTagTable),0);
FillChar(TekTabl,SizeOf(TTabl),0);
TekTabl.Exist := iFalse;
HeaderLoaded      := True;
PropertyLoaded    := True;
TechParamsLoaded  := True;
CommonParamsLoaded:= True;
GlobalTagsTableLoaded   := True;

ZamVersion    := ZamerVersion;
ZamerSign     := CurrentZamerSign;
StrPCopy(ZamerHeader.Path,aFileName);

DT:=Now;
DecodeZamerDate(DT,ZamerHeader.Date);
DecodeZamerTime(DT,ZamerHeader.Time);

CommonParams.KolTabl := aKolTabl;

Lock;
WriteZamerSign;
WriteZamerHeader;
WriteZamerProperty;
WriteTechParam;
WriteCommonParam;
WriteTagTable;
FileSeek(FileSelf,0,2);
for i:=1 to aKolTabl do
    FileWrite(FileSelf,TekTabl,SizeOf(TTabl));
UnLock;
end;



destructor  TZamerFile.Destroy;
begin
while IsLocked do UnLock;
while IsOpened do DoClose;
inherited Destroy;
end;



procedure TZamerFile.Lock;
begin
if Locked=0 then DoOpen;
inc(Locked);
end;


procedure TZamerFile.UnLock;
begin
dec(Locked);
if Locked=0 then DoClose;
end;


function  TZamerFile.IsLocked : boolean;
begin
Result:=(Locked>0);
end;


procedure TZamerFile.DoOpen;
begin
if OpenedCount=0 then begin
   FileSelf:=Integer(FileOpen(fFileName,fmOpenRead or fmShareDenyNone));
   OpenedWrite:=False;
   if FileSelf<=0 then Exit;
end;
inc(OpenedCount);
end;


procedure TZamerFile.DoOpenWrite;
begin
if IsReadOnly then
   raise EFailOpenFile.Create('Can''t open for write "read only" file');
if (not OpenedWrite) and
   (OpenedCount>0) then begin
   FileClose(FileSelf);
   FileSelf:=Integer(FileOpen(fFileName,fmOpenReadWrite or fmShareDenyWrite));
   if FileSelf<=0 then Exit;
end;
if OpenedCount=0 then begin
   FileSelf:=Integer(FileOpen(fFileName,fmOpenReadWrite or fmShareDenyWrite));
   if FileSelf<=0 then Exit;
end;
OpenedWrite:=True;
inc(OpenedCount);
end;


procedure TZamerFile.DoClose;
begin
dec(OpenedCount);
if OpenedCount=0 then begin
   FileClose(FileSelf);
   FileSelf:=-1;
end;
end;


function  TZamerFile.IsOpened : boolean;
begin
Result:=(OpenedCount>0);
end;



procedure TZamerFile.WriteZamerSign;
begin
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
DoOpenWrite;
FileSeek(FileSelf,0,0);
FileWrite(FileSelf,ZamerSign,SizeOf(TZamerSign));
DoClose;
end;


procedure TZamerFile.WriteZamerHeader;
var l:longint;
begin
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
DoOpenWrite;
l:=FileSeek(FileSelf,SizeOf(TZamerSign),0);
if l<> SizeOf(TZamerSign) then begin
   WriteZamerSign;
end;
FileWrite(FileSelf,ZamerHeader,SizeOf(TZamerHeader));
DoClose;
end;


procedure TZamerFile.WriteZamerProperty;
var l:longint;
begin
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
DoOpenWrite;
l:=FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader),0);
if l<> SizeOf(TZamerSign)+SizeOf(TZamerHeader) then begin
   WriteZamerSign;
   WriteZamerHeader;
end;
FileWrite(FileSelf,ZamerProperty,SizeOf(TZamerProperty));
DoClose;
end;


procedure TZamerFile.WriteTechParam;
var l:longint;
begin
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
DoOpenWrite;
l:=FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty),0);
if l<> SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty) then begin
   WriteZamerSign;
   WriteZamerHeader;
   WriteZamerProperty;
end;
FileWrite(FileSelf,TechParams,SizeOf(TTechParam));
DoClose;
end;


procedure TZamerFile.WriteCommonParam;
var l:longint;
begin
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
DoOpenWrite;
l:=FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty)+SizeOf(TTechParam),0);
if l<> SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty)+SizeOf(TTechParam) then begin
   WriteZamerSign;
   WriteZamerHeader;
   WriteZamerProperty;
   WriteTechParam;
end;
FileWrite(FileSelf,CommonParams,SizeOf(TCommonParam));
DoClose;
end;


procedure TZamerFile.WriteTagTable;
var l:longint;
begin
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
DoOpenWrite;
l:=FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty)+SizeOf(TTechParam)+SizeOf(TCommonParam),0);
if l<> SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty)+SizeOf(TTechParam)+SizeOf(TCommonParam) then begin
   WriteZamerSign;
   WriteZamerHeader;
   WriteZamerProperty;
   WriteTechParam;
   WriteCommonParam;
end;
FileWrite(FileSelf,GlobalTagsTable,SizeOf(TTagTable));
DoClose;
end;






procedure TZamerFile.GetZamerSign(var aZamerSign : TZamerSign);
begin
aZamerSign := ZamerSign;
end;

procedure TZamerFile.GetZamerHeader(var aZamerHeader : TZamerHeader);
var Fl:boolean;
{$IFDEF AllowOldFormat}
    OldZamerHeader:TOldZamerHeader;
{$ENDIF}
begin
if not HeaderLoaded then begin
   DoOpen;
   Fl:=True;
{$IFDEF AllowOldFormat}
   if ZamVersion=OldZamerVersion then begin
      Fl:=False;
      FileSeek(FileSelf,SizeOf(TZamerSign),0);
      FileRead(FileSelf,OldZamerHeader,SizeOf(TOldZamerHeader));
      StrPCopy(ZamerHeader.Path,OldZamerHeader.Path);
      DecodeZamerDate(OldZamerHeader.DateTime,ZamerHeader.Date);
      DecodeZamerTime(OldZamerHeader.DateTime,ZamerHeader.Time);
   end;
{$ENDIF}
   if Fl then begin
      FileSeek(FileSelf,SizeOf(TZamerSign),0);
      FileRead(FileSelf,ZamerHeader,SizeOf(TZamerHeader));
   end;
   HeaderLoaded:=True;
   DoClose;
end;
aZamerHeader := ZamerHeader;
end;

procedure TZamerFile.SetZamerHeader(var aZamerHeader : TZamerHeader);
begin
ZamerHeader := aZamerHeader;
HeaderLoaded := True;
WriteZamerHeader;
end;

procedure TZamerFile.GetZamerProperty(var aZamerProperty : TZamerProperty);
var Fl:boolean;
{$IFDEF AllowOldFormat}
    OldZamerProperty:TOldZamerProperty;
{$ENDIF}
begin
if not PropertyLoaded then begin
   DoOpen;
   Fl:=True;
{$IFDEF AllowOldFormat}
   if ZamVersion=OldZamerVersion then begin
      Fl:=False;
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TOldZamerHeader),0);
      FileRead(FileSelf,OldZamerProperty,SizeOf(TOldZamerProperty));
      ZamerProperty.ZamerType     :=            OldZamerProperty.ZamerType;
      ZamerProperty.DiagPsp       :=            OldZamerProperty.DiagPsp;
      ZamerProperty.Persent       :=            OldZamerProperty.Persent;
      ZamerProperty.Synhro        :=            OldZamerProperty.Synhro;
      ZamerProperty.ZamerEdIzm    :=            OldZamerProperty.ZamerEdIzm;
      ZamerProperty.SpectrFreq    :=            OldZamerProperty.SpectrFreq;
      ZamerProperty.SpectrStep    :=            OldZamerProperty.SpectrStep;
      ZamerProperty.AllX          :=            OldZamerProperty.AllX;
      ZamerProperty.Stamp         :=            OldZamerProperty.Stamp;
      ZamerProperty.BalansMass    :=            OldZamerProperty.BalansMass;
      ZamerProperty.BalansPlosk   :=            OldZamerProperty.BalansPlosk;
   end;
{$ENDIF}
   if Fl then begin
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader),0);
      FileRead(FileSelf,ZamerProperty,SizeOf(TZamerProperty));
   end;
   PropertyLoaded:=True;
   DoClose;
end;
aZamerProperty := ZamerProperty;
end;

procedure TZamerFile.SetZamerProperty(var aZamerProperty : TZamerProperty);
begin
ZamerProperty := aZamerProperty;
PropertyLoaded := True;
WriteZamerProperty;
end;

function  TZamerFile.GetTechParam(aNum : Ti16;var aVal :double) : boolean;
var i:integer;
    Fl:boolean;
{$IFDEF AllowOldFormat}
    OldTechParam:TOldTechParam;
{$ENDIF}
begin
Result:=False;
aVal := 0.0;
if not TechParamsLoaded then begin
   DoOpen;
   Fl:=True;
{$IFDEF AllowOldFormat}
   if ZamVersion=OldZamerVersion then begin
      Fl:=False;
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TOldZamerHeader)+SizeOf(TOldZamerProperty),0);
      FileRead(FileSelf,OldTechParam,SizeOf(TOldTechParam));
      for i:=1 to TechParamKol do begin
          TechParams[i].Num    := OldTechParam[i].Num;
          TechParams[i].ParamR := OldTechParam[i].ParamR;
      end;
   end;
{$ENDIF}
   if Fl then begin
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty),0);
      FileRead(FileSelf,TechParams,SizeOf(TTechParam));
   end;
   TechParamsLoaded:=True;
   DoClose;
end;
for i:=1 to TechParamKol do
    if TechParams[i].Num=aNum then begin
       aVal := TechParams[i].ParamR;
       Result:=True;
       Exit;
    end;
end;

procedure TZamerFile.SetTechParam(aNum : Ti16; aVal : double);
var i,j:integer;
    r:double;
begin
GetTechParam(-1,r);
j:=0;
for i:=1 to TechParamKol do
    if TechParams[i].Num=aNum then begin
       j:=i;
       break;
    end else
    if (TechParams[i].Num=0) and (j=0) then j:=i;
if j>0 then begin
   TechParams[j].Num:=aNum;
   TechParams[j].ParamR := aVal;
end;
TechParamsLoaded:=True;
WriteTechParam;
end;

procedure TZamerFile.GetCommonParam(var aCommonParam : TCommonParam);
var Fl:boolean;
{$IFDEF AllowOldFormat}
    OldCommonParam:TOldCommonParam;
{$ENDIF}
begin
if not CommonParamsLoaded then begin
   DoOpen;
   Fl:=True;
{$IFDEF AllowOldFormat}
   if ZamVersion=OldZamerVersion then begin
      Fl:=False;
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TOldZamerHeader)+SizeOf(TOldZamerProperty)+SizeOf(TOldTechParam),0);
      FileRead(FileSelf,OldCommonParam,SizeOf(TOldCommonParam));
      CommonParams.Ocenka                    := OldCommonParam.Ocenka;
      CommonParams.KolTabl                   := OldCommonParam.KolTabl;
      StrPCopy(CommonParams.Comment,OldCommonParam.Comment);
      CommonParams.NiktaKolFaz               := OldCommonParam.NiktaKolFaz;
      CommonParams.NiktaHarZamer             := OldCommonParam.NiktaHarZamer;
      StrPCopy(CommonParams.ProtokolName,OldCommonParam.ProtokolName);
      StrPCopy(CommonParams.PodshMark,OldCommonParam.PodshMark);
      CommonParams.OtmetchTabl               := OldCommonParam.OtmetchTabl;
   end;
{$ENDIF}
   if Fl then begin
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty)+SizeOf(TTechParam),0);
      FileRead(FileSelf,CommonParams,SizeOf(TCommonParam));
   end;
   CommonParamsLoaded:=True;
   DoClose;
end;
aCommonParam := CommonParams;
end;

procedure TZamerFile.SetCommonParam(var aCommonParam : TCommonParam);
begin
CommonParams := aCommonParam;
CommonParamsLoaded:=True;
WriteCommonParam;
end;


procedure TZamerFile.GetGlobalTag(aTag : TTagNum;var aBuf;var aLen : longint);
var i:integer;
    l:Tu32;
    Fl:boolean;
begin

aLen:=-1;
if not GlobalTagsTableLoaded then begin
   DoOpen;
   Fl:=True;
{$IFDEF AllowOldFormat}
   if ZamVersion=OldZamerVersion then begin
      Fl:=False;
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TOldZamerHeader)+
         SizeOf(TOldZamerProperty)+SizeOf(TOldTechParam)+SizeOf(TOldCommonParam),0);
      FileRead(FileSelf,GlobalTagsTable,SizeOf(TTagTable));
   end;
{$ENDIF}
   if Fl then begin
      FileSeek(FileSelf,SizeOf(TZamerSign)+SizeOf(TZamerHeader)+SizeOf(TZamerProperty)+
                  SizeOf(TTechParam)+SizeOf(TCommonParam),0);
      FileRead(FileSelf,GlobalTagsTable,SizeOf(TTagTable));
   end;
   GlobalTagsTableLoaded:=True;
   DoClose;
end;

for i:=1 to GlobalTagTableKol do
    if GlobalTagsTable[i].NumT=aTag then begin
       if GlobalTagsTable[i].LenT<=0 then Exit;
       DoOpen;
       l:=FileSeek(FileSelf,GlobalTagsTable[i].OffT,0);
       if l=GlobalTagsTable[i].OffT then
          aLen:=FileRead(FileSelf,aBuf,GlobalTagsTable[i].LenT);
       DoClose;
       Exit;
    end;
end;

procedure TZamerFile.SetGlobalTag(aTag : TTagNum;var aBuf; aLen : longint);
var i,j:integer;
    l: longint;
begin
if aLen<=0 then Exit;

GetGlobalTag(-1,i,l); // Проверить и подгрузить GlobalTagsTable
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
j:=0;
for i:=1 to GlobalTagTableKol do
    if GlobalTagsTable[i].NumT=aTag then begin
       j:=i;
       break;
    end else
    if (GlobalTagsTable[i].NumT=0) and (j=0) then j:=i;
if j>0 then begin
   l:=0;
   if GlobalTagsTable[j].NumT>0 then
      if GlobalTagsTable[j].LenT>=Tu32(aLen) then l:=GlobalTagsTable[j].OffT;
   DoOpenWrite;
   if l=0 then l:=FileSeek(FileSelf,0,2);
   l:=FileSeek(FileSelf,l,0);
   GlobalTagsTable[j].OffT:=l;
   GlobalTagsTable[j].LenT:=FileWrite(FileSelf,aBuf,aLen);
   GlobalTagsTable[j].NumT:=aTag;
   WriteTagTable;
   DoClose;
end;
end;

function  TZamerFile.GetGlobalTagLen(aTag : TTagNum) : longint;
var i:integer;
    l:longint;
begin
Result:=-1;
GetGlobalTag(-1,i,l); // Проверить и подгрузить GlobalTagsTable
for i:=1 to GlobalTagTableKol do
    if GlobalTagsTable[i].NumT=aTag then begin
       Result:=GlobalTagsTable[i].LenT;
       Exit;
    end;
end;

procedure TZamerFile.GetLocalTag(aOrder : TOrder;aTag : TTagNum;var aBuf;var aLen : longint);
var i:integer;
    l:Tu32;
begin
aLen:=-1;
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
for i:=1 to LocalTagTableKol do
    if TekTabl.LocalTagTable[i].NumT=aTag then begin
       if TekTabl.LocalTagTable[i].LenT<=0 then Exit;
       DoOpen;
       l:=FileSeek(FileSelf,TekTabl.LocalTagTable[i].OffT,0);
       if l=TekTabl.LocalTagTable[i].OffT then
          aLen:=FileRead(FileSelf,aBuf,TekTabl.LocalTagTable[i].LenT);
       DoClose;
       Exit;
    end;
end;

procedure TZamerFile.SetLocalTag(aOrder : TOrder;aTag : TTagNum;var aBuf; aLen : longint);
var i,j:integer;
    l:longint;
begin
if aLen<=0 then Exit;
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
j:=0;
for i:=1 to LocalTagTableKol do
    if TekTabl.LocalTagTable[i].NumT=aTag then begin
       j:=i;
       break;
    end else
    if (TekTabl.LocalTagTable[i].NumT=0) and (j=0) then j:=i;
if j>0 then begin
   l:=0;
   if TekTabl.LocalTagTable[j].NumT>0 then
      if TekTabl.LocalTagTable[j].LenT>=Tu32(aLen) then l:=TekTabl.LocalTagTable[j].OffT;
   DoOpenWrite;
   if l=0 then l:=FileSeek(FileSelf,0,2);
   l:=FileSeek(FileSelf,l,0);
   TekTabl.LocalTagTable[j].OffT:=l;
   TekTabl.LocalTagTable[j].LenT:=FileWrite(FileSelf,aBuf,aLen);
   TekTabl.LocalTagTable[j].NumT:=aTag;
   SetTabl(aOrder,TekTabl);
   DoClose;
end;
end;

function  TZamerFile.GetLocalTagLen(aOrder : TOrder;aTag : TTagNum) : longint;
var i:integer;
begin
Result:=-1;
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
for i:=1 to LocalTagTableKol do
    if TekTabl.LocalTagTable[i].NumT=aTag then begin
       Result:=TekTabl.LocalTagTable[i].LenT;
       Exit;
    end;
end;

procedure TZamerFile.GetTabl(aOrder : TOrder;var aTabl : TTabl);
var Fl:boolean;
{$IFDEF AllowOldFormat}
    OldTabl:TOldTabl;
{$ENDIF}
begin

if (aOrder<=0) or (aOrder>GetMaxTabl) then begin
   aTabl.Exist:=0;
   TekTablOrder:=-1;
   Exit;
end;

if aOrder=TekTablOrder then
   aTabl:=TekTabl
else begin
     DoOpen;
     Fl:=True;
{$IFDEF AllowOldFormat}
     if ZamVersion=OldZamerVersion then begin
        Fl:=False;
        FileSeek(FileSelf,SizeOf(TOldZamerRecord)+
                          SizeOf(TOldTabl)*(aOrder-1),
                          0);
        FileRead(FileSelf,OldTabl,SizeOf(TOldTabl));

        if OldTabl.Exist then TekTabl.Exist := iTrue
                         else TekTabl.Exist := iFalse;
        try
           DecodeZamerDate(OldTabl.Time,TekTabl.Date);
           DecodeZamerTime(OldTabl.Time,TekTabl.Time);
        except
        end;
        TekTabl.SKZ               :=     OldTabl.SKZ;
        TekTabl.Ampl              :=     OldTabl.Ampl;
        TekTabl.Faza              :=     OldTabl.Faza;
        TekTabl.X0                :=     OldTabl.X0;
        TekTabl.XN                :=     OldTabl.XN;
        TekTabl.dX                :=     OldTabl.dX;
        TekTabl.Option            :=     OldTabl.Option;
        TekTabl.Tip               :=     OldTabl.Tip;
        TekTabl.EdIzm             :=     OldTabl.EdIzm;
        TekTabl.AllX              :=     OldTabl.AllX;
        TekTabl.Scale             :=     OldTabl.Scale;
        TekTabl.StampType         :=     OldTabl.StampType;
        TekTabl.OffT              :=     OldTabl.OffT;
        TekTabl.LenT              :=     OldTabl.LenT;
        TekTabl.LocalTagTable     :=     OldTabl.LocalTagTable;
        TekTabl.OtmetchCikl       :=     OldTabl.OtmetchCikl;
        TekTabl.Angle             :=     OldTabl.Angle;
     end;
{$ENDIF}
     if Fl then begin
        FileSeek(FileSelf,SizeOf(TZamerRecord)+
                          SizeOf(TTabl)*(aOrder-1),
                          0);
        FileRead(FileSelf,TekTabl,SizeOf(TTabl));
     end;
     DoClose;
     TekTablOrder:=aOrder;
     aTabl:=TekTabl;
end;
end;

procedure TZamerFile.SetTabl(aOrder : TOrder;var aTabl : TTabl);
begin
if (aOrder<=0) or (aOrder>GetMaxTabl) then Exit;
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
aTabl.Exist:=iTrue;
aTabl.StampType:=stLin;
TekTablOrder:=aOrder;
TekTabl:=aTabl;
DoOpenWrite;
FileSeek(FileSelf,SizeOf(TZamerRecord)+
                     SizeOf(TTabl)*(aOrder-1),
                     0);
FileWrite(FileSelf,TekTabl,SizeOf(TTabl));
DoClose;
end;

function  TZamerFile.GetMaxTabl : TOrder;
begin
GetCommonParam(CommonParams);
Result:=CommonParams.KolTabl;
end;


// Временный буфер на 8000 Ti16 отсчётов
var pp:TI16Array;

function  TZamerFile.GetStamps(aOrder : TOrder;var aBuf;aLen : longint):longint;
var l,i,k,aKol:longint;
    Fl:boolean;

{$IFDEF AllowOldFormat}
Type POldRealArray =^TOldRealArray;
     TOldRealArray = array [1..MaxShortStamps] of Real48;

var aBuf1 : POldRealArray;
{$ENDIF}

procedure SetBufVal(var aBuf;l:longint;r:TReal64);
begin
TReal64Array(aBuf)[l]:=r;
//hmemcpy(HugeOffset(@aBuf,(l-1)*SizeOf(TReal64)),@r,SizeOf(TReal64));
end;

begin
Result:=-1;
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
if TekTabl.LenT>0 then begin
   DoOpen;
   if TekTabl.Tip=ztGarmon then begin
      { Гармоники      : Real48 Freq1,Ampl1,Faza1,Power1,Freq2,Ampl2,Faza2,Power2, ... }
      Fl:=True;
{$IFDEF AllowOldFormat}
      if ZamVersion=OldZamerVersion then begin
         Fl:=False;
         if Tu32(aLen)>TekTabl.LenT then aLen:=TekTabl.LenT;
         l:=FileSeek(FileSelf,TekTabl.OffT,0);
         GetMem(pointer(aBuf1),SizeOf(TOldRealArray));
         if TekTabl.StampType=stLin then begin
            l:=FileRead(FileSelf,aBuf1^,TekTabl.LenT);
         end;
         for i:=1 to (l div SizeOf(Real48)) do
             TRealArray(aBuf)[i]:=aBuf1^[i];
         FreeMem(pointer(aBuf1),SizeOf(TOldRealArray));
         Result:=(l div SizeOf(Real48))*SizeOf(TReal64);
      end;
{$ENDIF}
      if Fl then begin
         if Tu32(aLen)>TekTabl.LenT then aLen:=TekTabl.LenT;
         FileSeek(FileSelf,TekTabl.OffT,0);
         if TekTabl.StampType=stLin then begin
            l:=FileRead(FileSelf,aBuf,aLen);
            Result:=l;
         end;
      end;
   end else begin
      if (TekTabl.Tip=ztSpectr) and ((TekTabl.Option and opFaza)<>0) then begin
         { Спектр с фазой : Integer Ampl1,Faza1*10,Ampl2,Faza2*10, ... }
         if Tu32(aLen)>(TekTabl.LenT*SizeOf(TReal64) div 2) then
            aLen:=(TekTabl.LenT*SizeOf(TReal64) div 2);
         aKol:=(aLen div SizeOf(TReal64)) div 2;
         FileSeek(FileSelf,TekTabl.OffT,0);
         if TekTabl.StampType=stLin then begin
            i:=0;
            { Читаем файл кусочиками и преобразовываем в TReal64 }
            while i<=aKol do begin
               if aKol-i<MaxShortStamps div 2 then l:=aKol-i
                                              else l:=MaxShortStamps div 2;
               if l<=0 then break;
               l:=FileRead(FileSelf,pp,l*4) div 4;
               if l<=0 then break;
               for k:=1 to l do begin
                   SetBufVal(aBuf,i+k*2-1,pp[k*2-1]*TekTabl.Scale);
                   SetBufVal(aBuf,i+k*2  ,pp[k*2]/10.0);
               end;
               i:=i+l*2;
            end;
            Result:=i;
         end;
      end else begin
         { Все остальные }
         if Tu32(aLen)>(TekTabl.LenT*SizeOf(TReal64)) div 2 then
            aLen:=(TekTabl.LenT*SizeOf(TReal64)) div 2;
         aKol:=aLen div SizeOf(TReal64);
         FileSeek(FileSelf,TekTabl.OffT,0);
         if TekTabl.StampType=stLin then begin
            i:=0;
            { Читаем файл кусочиками и преобразовываем в double }
            while i<=aKol do begin
               if aKol-i<MaxShortStamps then l:=aKol-i
                                        else l:=MaxShortStamps;
               if l<=0 then break;
               l:=FileRead(FileSelf,pp,l*2) div 2;
               if l<=0 then break;
               for k:=1 to l do
                   SetBufVal(aBuf,i+k,pp[k]*TekTabl.Scale);
               i:=i+l;
            end;
            Result:=aKol;
         end;
      end;
   end;
   DoClose;
end;
end;



{ Записать int отсчеты. Только для сигналов. aBuf - array of smallint любой длины aLen (в байтах) }
function  TZamerFile.SetStampsInt(aOrder : TOrder;var aBuf;aLen : longint):longint;
var i,i1:longint;
    l: Tu32;
begin
Result:=-1;
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
if (TekTabl.Tip<>ztSignal) then Exit;

if aLen>0 then begin
   DoOpenWrite;
   { Все остальные }
   if TekTabl.LenT>=Tu32(aLen) then l:=TekTabl.OffT
      else l:=FileSeek(FileSelf,0,2);
   TekTabl.OffT:=l;
   TekTabl.LenT:=aLen;
   FileSeek(FileSelf,TekTabl.OffT,0);

   TekTabl.StampType:=stLin;
//   TekTabl.Scale:=1;
//   TekTabl.Ampl:=$7FFF;
   i:=0;
      { Преобразуем Buf в Integer и пишем кусочками в файл }
   while i<=aLen do begin
      if aLen-i<MaxShortStamps*SizeOf(smallint) then L:=aLen-i
                                                else L:=MaxShortStamps*SizeOf(smallint);
      if L<=0 then break;
      i1:=(i div SizeOf(smallint))+1;
      L:=FileWrite(FileSelf,TI16Array(aBuf)[i1],L);
      if L<=0 then break;
      i:=i+longint(L);
   end;
   Result:=i;
   SetTabl(aOrder,TekTabl);
   DoClose;
end;
end;





function  TZamerFile.SetStamps(aOrder : TOrder;var aBuf;aLen : longint):longint;
var i,k,i1:longint;
    ai:TReal64;
    l : Tu32;

function GetBufVal(var aBuf;l:longint):TReal64; inline;
begin
Result:=TReal64Array(aBuf)[l];
end;

begin
Result:=-1;
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   { Не поддерживается ! }
   Abort;
{$ENDIF}
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
if aLen>0 then begin
   DoOpenWrite;
   if TekTabl.Tip=ztGarmon then begin
      { Гармоники      : Real48 Freq1,Ampl1,Faza1,Power1,Freq2,Ampl2,Faza2,Power2, ... }
      if TekTabl.LenT>=Tu32(aLen) then l:=TekTabl.OffT
         else l:=FileSeek(FileSelf,0,2);
      TekTabl.OffT:=l;
      TekTabl.LenT:=aLen;
      FileSeek(FileSelf,TekTabl.OffT,0);
      TekTabl.StampType:=stLin;
      TekTabl.Scale:=1;
      l:=FileWrite(FileSelf,aBuf,aLen);
      Result:=l;
      SetTabl(aOrder,TekTabl);
   end else begin
      if (TekTabl.Tip=ztSpectr) and ((TekTabl.Option and opFaza)<>0) then begin
         { Спектр с фазой : Integer Ampl1,Faza1*10,Ampl2,Faza2*10, ... }
         if longint(TekTabl.LenT)>=(aLen div (SizeOf(TReal64) div 2)) then l:=TekTabl.OffT
            else l:=FileSeek(FileSelf,0,2);
         TekTabl.OffT:=l;
         TekTabl.LenT:=aLen div (SizeOf(TReal64) div 2);
         FileSeek(FileSelf,TekTabl.OffT,0);

         TekTabl.StampType:=stLin;
         if TekTabl.Scale=0 then
            if TekTabl.Ampl=0 then TekTabl.Scale:=1
                              else TekTabl.Scale:=TekTabl.Ampl/MaxIntStamp;
         i:=0;
            { Преобразуем Buf в Integer и пишем кусочками в файл }
         while i<=aLen do begin
            if aLen-i<MaxShortStamps*SizeOf(TReal64) then l:=aLen-i
                                                   else l:=MaxShortStamps*SizeOf(TReal64);
            if l<=0 then break;
            i1:=i div SizeOf(TReal64);
            for k:=1 to (l div SizeOf(TReal64)) div 2 do begin
                pp[k*2-1]:=Round(GetBufVal(aBuf,i1+k*2-1)/TekTabl.Scale);
                ai:=GetBufVal(aBuf,i1+k*2)*10.0;
                if (ai<=-3600.0) then
                   while (ai<=-3600.0) do ai:=ai+3600.0;
                if (ai>=3600.0) then
                   while (ai>=3600.0) do ai:=ai-3600.0;
                pp[k*2  ]:=Round(ai);
            end;
            l:=FileWrite(FileSelf,pp,l div (SizeOf(TReal64) div 2));
            if l<=0 then break;
            i:=i+longint(l)*(SizeOf(TReal64) div 2);
         end;
         Result:=i;
         SetTabl(aOrder,TekTabl);
      end else begin
         { Все остальные }
         if longint(TekTabl.LenT)>=(aLen div (SizeOf(TReal64) div 2)) then l:=TekTabl.OffT
            else l:=FileSeek(FileSelf,0,2);
         TekTabl.OffT:=l;
         TekTabl.LenT:=aLen div (SizeOf(TReal64) div 2);
         FileSeek(FileSelf,TekTabl.OffT,0);

         TekTabl.StampType:=stLin;
         if TekTabl.Scale=0 then
            if TekTabl.Ampl=0 then TekTabl.Scale:=1
                              else TekTabl.Scale:=TekTabl.Ampl/MaxIntStamp;
         i:=0;
            { Преобразуем Buf в Integer и пишем кусочками в файл }
         while i<=aLen do begin
            if aLen-i<MaxShortStamps*SizeOf(TReal64) then l:=aLen-i
                                                   else l:=MaxShortStamps*SizeOf(TReal64);
            if l<=0 then break;
            i1:=i div SizeOf(TReal64);
            for k:=1 to l div SizeOf(TReal64) do
                pp[k]:=Round(GetBufVal(aBuf,i1+k)/TekTabl.Scale);
            l:=FileWrite(FileSelf,pp,l div (SizeOf(TReal64) div 2));
            if l<=0 then break;
            i:=i+longint(l)*(SizeOf(TReal64) div 2);
         end;
         Result:=i;
         SetTabl(aOrder,TekTabl);
      end;
   end;
   DoClose;
end;
end;


{ Создает aBuf, читает слова-отсчеты
  Только для временного сигнала нового формата ! }
function  TZamerFile.GetStampsInt(aOrder : TOrder;var aBuf: THandle):longint;
var A:PI16Array;
begin
Result:=-1;
aBuf:=0;
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
if TekTabl.LenT>0 then begin
   DoOpen;
   FileSeek(FileSelf,TekTabl.OffT,0);
   GetMem(A, TekTabl.LenT);
   Result:=FileRead(FileSelf,A^,TekTabl.LenT);
   DoClose;
end;
end;





function  TZamerFile.GetStampsLen(aOrder : TOrder):longint;
begin
Result:=-1;
GetTabl(aOrder,TekTabl);
if (TekTabl.Exist=iFalse) then Exit;
if TekTabl.Tip<>ztGarmon then Result:=TekTabl.LenT*(SizeOf(TReal64) div 2)
                         else
{$IFDEF AllowOldFormat}
if ZamVersion=OldZamerVersion then
   Result:=(TekTabl.LenT div SizeOf(Real48))*SizeOf(TReal64)
else
{$ENDIF}
   Result:=TekTabl.LenT;
end;


function  TZamerFile.GetZamerVersion : integer;
begin
Result:=ZamVersion;
end;






function  LongAnd(l1,l2: Tu32):boolean;
begin
Result:=((l1 and l2)<>0);
end;

function  LongDec(l1,l2: Tu32):boolean;
begin
Result:=(l1>=l2);
end;

function  LongDec1(l1,l2: Tu32):boolean;
begin
Result:=(l1<=l2);
end;


function  TZamerFile.CheckZamer(var CheckedProperty : TZamerProperty) : boolean;
begin

if ZamerProperty.ZamerType=0   then ZamerProperty.ZamerType:=ztAny;
if ZamerProperty.DiagPsp=0     then ZamerProperty.DiagPsp:=dpAny;
if ZamerProperty.Synhro=0      then ZamerProperty.Synhro:=syAny;
if ZamerProperty.ZamerEdIzm=0  then ZamerProperty.ZamerEdIzm:=eiAny;
if ZamerProperty.Stamp=0       then ZamerProperty.Stamp:=stAny;
if ZamerProperty.BalansMass=0  then ZamerProperty.BalansMass:=bmAny;
if ZamerProperty.BalansPlosk=0 then ZamerProperty.BalansPlosk:=bpAny;

Result:=(LongAnd(ZamerProperty.ZamerType, CheckedProperty.ZamerType));
Result:=Result and (LongAnd(ZamerProperty.DiagPsp  , CheckedProperty.DiagPsp));
Result:=Result and (LongDec(ZamerProperty.Persent  , CheckedProperty.Persent));
Result:=Result and (LongAnd(ZamerProperty.Synhro   , CheckedProperty.Synhro));
Result:=Result and (LongAnd(ZamerProperty.ZamerEdIzm, CheckedProperty.ZamerEdIzm));
Result:=Result and (LongDec(ZamerProperty.SpectrFreq, CheckedProperty.SpectrFreq));
Result:=Result and (LongDec(ZamerProperty.AllX      , CheckedProperty.AllX));
Result:=Result and (LongDec1(ZamerProperty.SpectrStep,CheckedProperty.SpectrStep));
Result:=Result and (LongAnd(ZamerProperty.Stamp     , CheckedProperty.Stamp));
Result:=Result and (LongAnd(ZamerProperty.BalansMass, CheckedProperty.BalansMass));
Result:=Result and (LongAnd(ZamerProperty.BalansPlosk, CheckedProperty.BalansPlosk));
end;






function GetFreeName(aPath : String; aPrefix: String; aDate : TDateTime) : String;
var i : integer;
    ext, name: String;
    Year, Month, Day: Word;

begin
Result:='';

aPath:=Trim(aPath);
DecodeDate(aDate,Year, Month, Day);
if Year < 2000 then name := aPrefix+'2'
else name := aPrefix+'3';
name := name + Format('%.3d%.2d%.2d', [Year mod 100, Month, Day]);

i:=1;
while i < 1000 do begin
    ext := Format('%.3d', [i]);
    if FileSearch(name+'.'+ext, aPath)='' then break;
    inc(i);
end;
if i>999 then begin
    i:=1000;
    while True do begin
       ext := Format('%d', [i]);
       if FileSearch(name+'.'+ext, aPath)='' then break;
       inc(i);
    end;
end;
Result:=CreateAbsolutePath(name+'.'+ext, aPath);
end;



function TZamerFile.IsReadOnly: boolean;
begin
Result:=fReadOnly; 
end;

end.


