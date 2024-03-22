(*
                                                  Вибро-Центр (г. Пермь)
                                                  and@vibrocenter.ru

    Описание структур нового файла замера версии 3.01 для Atlant
    Начато                              01.10.97
    Последние изменения и дополнения    27.04.23

    History :

    27.04.23    Уменьшил MaxShortStamps
                Переименовал TIntegerArray в TI16Array и TRealArray в TReal64Array (совпало со стандартным типом)

    09.09.19    Сделал MaxShortStamps = 128*1024*1024; иначе срабатывал RangeCheck

    22.08.17    Добавил lttPhaseTable     = 14; // Таблица ФЧХ канала

    05.10.16    Переименовал типы данных, чтобы не пересекались со стандартными
                Выкинул поддержку WIN16

    18.05.15    Добавил lttUTRawData      = 5; // Локальный тэг для Matrix UltraTest
                        lttUTExtRawData   = 6; // Локальный тэг для Ext Matrix (Photo) UltraTest

    25.11.13    Добавил gttAR700Old       = 8; // Глобальный тэг для прибора AR700
                        gttAR700_2        = 9; // Глобальный тэг для прибора AR700

    12.07.13    Добавил ztEnvelope        = $200; // Огибающая
                        gttVoice          = 12; // Глобальный тэг для Голосового комментария (WAV-файл)
                        lttVoice          = 12; // Локальный тэг для Голосового комментария (WAV-файл)

    07.10.11    Добавил gttAR700 - Глобальный тэг для данных AR700
                eiDecibel         = $1000; // акустический сигнал, дБ

  13.03.09    Добавил eiForce           = $800; // Сила, Н

  03.10.08    Добавил gttGrad - Глобальный тэг для данных НПО Град
              Изменил для битовых полей тип с signed32 на Tu32 (unsigned32)

  15.03.07    Добавил lttAMTest2Otm - Локальный тэг для отметчиков в АМТест2

  30.10.06    Добавил gttMotorData - Глобальный тэг для дополнительных данных по мотору

  11.05.05    Добавил gttGanimedCD - Глобальный тэг для круговой диаграммы Ганимеда

  11.04.05    Добавил lttBalansSKOtm - Локальный тэг для отметчиков в Balans-SK

  26.03.04    Добавил TCommonParam.EnglishMetric - Системные единицы/Английские

  13.11.03    Добавил gttAMTest - Глобальный тэг для AMTest

  14.05.03    Добавил gttGanimed - Глобальный тэг для таблиц Ганимеда

  14.10.02    Добавил eiTemp - Температура, град

  29.03.00    Добавил TCommonParam.AjaxDiag : TReal; - Диагностика
              изоляторов по Ajax

  28.02.00    Добавил gttNotes - Глобальный тэг для длинных примечаний в замере

  14.10.99    Добавил TTable.Offset - Смещение нуля сигнала при его снятии.
              Сам сигнал  от -Ampl до +Ampl

  09.10.98    Добавил Ti16 = SmallInt для WIN32

  06.10.98    Добавлено
                eiDinamo          = 256;  Динамограмма, Тонны
                eiVT              = 512;  Ваттметрграмма,
                gttTairTablHole   = 4;    Глобальный тэг для таблиц в Tair
                gttTairTablVer    = 5;    Глобальный тэг для таблиц в Tair

  01.06.98    Добавлен тип ztPowerBand - Мощность в полосе

  25.05.98    Версия замера 3.01 :
              Коренная переделка всех таблиц под общепринятые форматы
              переменных : Double (8b),
                           Integer (2b),
                           LongInt (4b),
              Естественно, размеры таблиц поменялись.
              Старый формат перенесен в OldZHdr.Pas

  --------------------------------------------------------------------------

  22.12.97    Убрал примеры ZamerProperty

  19.12.97    Добавил Angle в TTabl - Угол установки отметчика при снятии сигнала

  08.12.97    Вставил в TCommonParam OtmetchTabl - число таблиц с отметчиком
              Вставил в TTabl OtmetchCikl - номер цикла для отметчика

  -------------- Далее все изменения только за счет резерва ----------------
      То есть последующие изменения не должны влиять на размер файла и
      его основных структур.

  15.11.97    Добавил TypeNames и EdIzmNames

  12.11.97    Вставил в TCommonParam Comment - Примечание
              Увеличил TCommonParam.Rezerv до 200 байт

  10.11.97    Вставил в TCommonParam PodshMark    - Марка подшипника для СВК
              Добавил ztSpectrFirie - Спектр по Фурье
                      ztSpectrOgib  - Спектр огибающей

  21.10.97    Вставил в TCommonParam ProtokolName - Имя ассоциированного файла
                                                    протокола для балансировки

  02.10.97    Начало
*)

unit Zamhdr;

{$MODE Delphi}
{$CODEPAGE UTF8}
{$H+}

{$A-} { На всякий случай убрать выравнивание }

interface

{ Типы переменных }
Type TReal64    = Double; { 8b }
     Tc8        = AnsiChar;   { 1b char }
     Tu8        = Byte;   { 1b - используется только для резерва }
     Ti16       = SmallInt;{ 2b signed }
     Tu32       = Longword;{ 4b unsigned }
     TZamDate   = array [1..3] of Ti16; { Год, месяц, день }
     TZamTime   = array [1..3] of Ti16; { Часы, минуты, секунды }

const iFalse    = 0;
      iTrue     = 1;

{------------------------------------------------------------------------------}
{ Всякое общее }
const MaxShortStamps = 8*1024;
Type PI16Array =^TI16Array;
     TI16Array = array [1..MaxShortStamps] of Ti16;
     PReal64Array =^TReal64Array;
     TReal64Array = array [1..MaxShortStamps] of TReal64;

     { Масштабный коэфициент по умолчанию }
const MaxIntStamp = 15000;

{------------------------------------------------------------------------------}
     { Заголовок замера - общие параметры }

Type TZamerPath    = array [0..80] of Tc8;
     TZamerSign    = array [0..5] of Tc8;
     TFileName     = array [0..12] of Tc8;

const ZamerVersion = 301; { Текущая версия замера }

const CurrentZamerSign : TZamerSign = ('V','C','3','0','1',#0);

     { Заголовок замера - общие параметры }
Type TZamerHeader = packed record
        Path       : TZamerPath; { Путь к файлу }
        Date       : TZamDate;      { Дата и время создания }
        Time       : TZamTime;
end;


{------------------------------------------------------------------------------}
     { Заголовок замера - Диагностические признаки файла замера }

const { ZamerType - Тип замера }
      ztOther           = 0; { Прочее - непонятный тип }
      ztSKZ             = 1; { СКЗ }
      ztSignal          = 2; { Сигнал }
      ztSpectr          = 4; { Спектр }
      ztSpectrPower     = 8; { Спектр мощности }
      ztSpectrFurie     = 16; { Спектр по Фурье }
      ztSpectrOgib      = 32; { Спектр огибающей }
      ztGarmon          = 64; { Гармоники }
      ztKepstr          = 128; { Кепстр }
      ztPowerBand       = 256; { Мощность в полосе }
      ztEnvelope        = $200; // Огибающая 
      ztAny             = $FFFF; { Любой }

const { DiagPsp - Наличие диагностического паспорта к замеру }
      dpYes             = 2; { Есть }
      dpNot             = 1; { Нет - свободный формат }
      dpAny             = $FFFF; { Любой }

const { Synhro - Синхронность регистрации сигналов }
      sySynhro          = 4; { Синхронно }
      sySynhronyze      = 2; { Синхронизировано }
      syNot             = 1; { Не синхронно }
      syAny             = $FFFF; { Любой }

const { ZamerEdIzm - Размерность информации }
      eiAcceleration    = 4; { Ускорение, м/с2 }
      eiVelocity        = 2; { Скорость, мм/с}
      eiDisplacement    = 1; { Перемещение, мкм }
      eiVolt            = 16; { Вольты, В }
      eiAmper           = 32; { Амперы, А }
      eiOhm             = 64; { Омы, Ом }
      eiNikta           = 128; { Комплексный замер для Nikt-ы }
      eiDinamo          = 256; { Динамограмма, Тонны }
      eiVT              = 512; { Ваттметрграмма, }
      eiTemp            = $400; { Температура, град }
      eiForce           = $800; // Сила, Н 
      eiDecibel         = $1000; // акустический сигнал, дБ
      eiAny             = $FFFF; { Любая }

const { Stamp - Наличие отметчика }
      stPhoto           = 4; { Фото }
      stElectro         = 2; { Электронный }
      stNot             = 1; { Нет }
      stAny             = $FFFF; { Любой }

const { BalansMass - Наличие пробных корректирующих масс в балансировке }
      bmYes             = 2; { Есть }
      bmNot             = 1; { Нет }
      bmAny             = $FFFF; { Любой }

const { BalansPlosk - Наличие плоскостей с грузами для балансировки }
      bpYes             = 2; { Есть }
      bpNot             = 1; { Нет }
      bpAny             = $FFFF; { Любое }

     {
       Заголовок замера - Диагностические признаки файла замера
          F - поле флажков - при наложении по AND должно быть <>0
          V> - числовые значения - должно быть больше, чем в замере
          V< - числовые значения - должно быть меньше, чем в замере
     }
Type PZamerProperty =^TZamerProperty;
     TZamerProperty = packed record
        ZamerType           : Tu32; { F Тип замера }
        DiagPsp             : Tu32; { F Наличие диагностического паспорта
                                        к замеру }
        Persent             : Ti16; { V> Объем замера относительно паспорта
                                        в процентах }
        Synhro              : Tu32; { F Синхронность регистрации сигналов }
        ZamerEdIzm          : Tu32; { F Размерность информации }
        SpectrFreq          : Tu32; { V> Максимальная частота спектра, Гц }
        SpectrStep          : Tu32; { V< Ширина спектральной линии *1000, Гц }
        AllX                : Tu32; { V> Число отсчетов в _сигнале_ }
        Stamp               : Tu32; { F Наличие отметчика }
        BalansMass          : Tu32; { F Наличие пробных корректирующих масс
                                        в балансировке }
        BalansPlosk         : Tu32; { F Наличие плоскостей с грузами
                                        для балансировки }

        Reserv              : array [1..30] of Tu8; { Резерв }
end;


(* Пример настроек на Палладу
const PalladaZamerProperty : TZamerProperty =
        ( ZamerType        : ztSignal or ztSpectr or ztGarmon;
          DiagPsp          : dpYes;
          Persent          : 60;
          Synhro           : syAny;
          ZamerEdIzm       : eiAcceleration or eiVelocity or eiDisplacement;
          SpectrFreq       : 500;
          SpectrStep       : 500; { 0.5*1000 }
          AllX             : 256;
          Stamp            : stAny;
          BalansMass       : bmNot;
          BalansPlosk      : 0
        );
*)


{------------------------------------------------------------------------------}
       { Таблица с технологическими параметрами }

const TechParamKol = 50; { Число технологических параметров }
Type TTechParamRecord = packed record
       Num     : Ti16;   { Номер технологического параметра }
       ParamR  : TReal64;   { Его значение }
end;
Type TTechParam = array [1..TechParamKol] of TTechParamRecord;


{------------------------------------------------------------------------------}
            { Таблица тэгов }
{
      Механизм тэгов предназначен для хранения в файле замера
  любого типа информации. Каждая запись TTagTableRecord
  хранит уникальный номер тэга NumT>0 и ссылку, где он хранится
  в файле замера. Место под OffT+LenT может быть занято непосредственно
  значением параметра. Если NumT=0 - место в строке не занято.
      Существует глобальная таблица для всего замера
  ( gttBalansMass - глобальный тэг для балансировочных масс ) и
  локальная таблица для каждого из сигналов (lttAriadnaDiag -
  локальный тэг для результатов диагностики в Ariadne ).

}

            { Таблица тэгов }
const GlobalTagTableKol = 30; { Число строк в таблице тэгов }
Type TTagNum = Ti16;
Type  TTagTableRecord = packed record
        NumT     : TTagNum;
        OffT     : Tu32; // Смещение в файле
        LenT     : Tu32;
end;
Type TTagTable = array [1..GlobalTagTableKol] of TTagTableRecord;

const gttBalansMass     = 1; { Глобальный тэг для балансировочных масс }
      gttNiktaDiag      = 3; { Глобальный тэг для результатов диагностики
                               в Nikte }
      gttTairTablHole   = 4; { Глобальный тэг для таблиц в Tair}
      gttTairTablVer    = 5; { Глобальный тэг для таблиц в Tair}
      gttNotes          = 6; { Глобальный тэг для длинных примечаний в замере }
      gttGanimed        = 7; { Глобальный тэг для таблиц Ганимеда }
      gttAMTest         = 8; { Глобальный тэг для AMTest }
      gttGanimedCD      = 9; { Глобальный тэг для круговой диаграммы Ганимеда }
      gttMotorData      = 10;{ Глобальный тэг для дополнительных данных по мотору }
      gttGrad           = 11;{ Глобальный тэг для данных НПО Град }
      gttVoice          = 12; // Глобальный тэг для Голосового комментария (WAV-файл)

      gttAR700Old       = 8; // Глобальный тэг для прибора AR700
      gttAR700_2        = 9; // Глобальный тэг для прибора AR700 

      lttAriadnaDiag    = 2; { Локальный тэг для результатов диагностики
                               в Ariadne }
      lttBalansSKOtm    = 3; { Локальный тэг для отметчиков в Balans-SK }

      lttAMTEst2Otm     = 4; { Локальный тэг для отметчиков в АМТест-2 }

      lttUTRawData      = 5; { Локальный тэг для Matrix UltraTest }
      lttUTExtRawData   = 6; { Локальный тэг для Ext Matrix (Photo) UltraTest }

      lttVoice          = 12; // Локальный тэг для Голосового комментария (WAV-файл)

      lttPhaseTable     = 14; // Таблица ФЧХ канала

      gttNext           = 999; { Следующие таблицы тэгов }
      lttNext           = 999;


{------------------------------------------------------------------------------}
       { Остальные общие параметры для замера - те, которые
         нужны для всего замера для конкретной программы,
         но не влияют на определение подходит ли замер
         для данной программы }

const { Ocenka - Оценка }
      ocOff       = 9; { выкл }
      ocNeud      = 6; { недопустимая }
      ocUdovl     = 3; { удовлетв    }
      ocGood      = 0; { хор   }

{------------------ Для Nikt-ы ----------------------}
const { NiktaKolFaz - Какие фазы зарегистрированы }
      nkfYesA         = 1; { Есть фаза A}
      nkfYesB         = 2; { Есть фаза B}
      nkfYesC         = 4; { Есть фаза C}

const { NiktaHarZamer - Характер замера }
      nhzVkl          = 1; { Включение }
      nhzOtkl         = 2; { Отключение }
      nhzVklOtkl      = 3; { Включение-Отключение }
      nhzOtklVkl      = 4; { Отключение-Включение }
      nhzOtklVklOtkl  = 5; { Отключение-Включение-Отключение }

{------------------EnglishMetric----------------------}
const emSystem=0; // Системные единицы
const emEnglish=1;// Английские
{------------------            ----------------------}

       { Остальные общие параметры для замера }
Type TCommonParam = packed record
        KolTabl            : Ti16; { Максимальное количество Tabl,
                                         т.е. под них зарезервированно место.
                                         Здесь же таблицы под отметчики }
        OtmetchTabl        : Ti16; { Сколько из KolTabl относятся к
                                     сигналам отметчиков, пишутся с
                                     KolTabl-OtmetchTabl+1 по KolTabl номера =
                                     числу циклов снятия сигнала }
        Comment            : array [0..50] of Tc8; { Примечание }
        Ocenka             : Ti16; { Оценка 9-выкл
                                            6-нед
                                            3-уд
                                            0-хор}

        NiktaKolFaz        : Ti16; { Количество зарегестрированных фаз - 1,2,3 }
        NiktaHarZamer      : Ti16; { Характер замера }

        ProtokolName       : TFileName; { Имя ассоциированного файла протокола
                                          для балансировки }

        PodshMark          : array [0..15] of Tc8; { Марка подшипника для СВК }

        AjaxDiag           : TReal64; { Диагностика изоляторов по Ajax }

        EnglishMetric      : Ti16; { 0-Системные единицы; 1-Английские }

        Reserv             : array [1..189] of Tu8; { Резерв }
end;


{------------------------------------------------------------------------------}
       { Cтрока таблицы для одного снятия сигнала }

const LocalTagTableKol = 10; { Число записей в локальной таблице тэгов }

Type TLocalTagTable = array [1..LocalTagTableKol] of TTagTableRecord;

const { Option - Флажки опций замера }
      opFaza      = 1; { Присутствует ли фаза в спектре }
      opSynhro    = 2; { Синхронный }

const { StampType - Тип записи отсчетов }
      stLin       = 0; { Линейный }

       { Cтрока таблицы для одного снятия сигнала }
Type TTabl = packed record
         Exist     : Ti16;   { 0 - нет/1 - строка заполнена - введено вместо
                                   проверки LenT=0}
         Date      : TZamDate;     { Дата и время снятия замера }
         Time      : TZamTime;
         SKZ       ,            { СКЗ }
         Ampl      ,            { Максимальная Амплитуда, Abs() }
         Faza      ,            { Начальная фаза для сигналов с отметчиком в градусах }
         X0        ,            { Нач. значение }
         XN        ,            { Кон. значение }
         dX        : TReal64;      { Шаг }
         Option    : Ti16;      { Флажки опций замера }
         Tip       : Ti16;      { Тип замера ztXXXXX }
         EdIzm     : Tu32;   { Размерность информации eiXXXX }
         AllX      : Tu32;   { Число отсчетов }

         Scale     : TReal64;      { Множитель приведения TReal64 := Integer * Scale }

         StampType : Ti16;      { Тип записи отсчетов - пока только stLin }
         OffT      : Tu32;   { Смещение в файле }
         LenT      : Tu32;   { Длина в файле - теперь может быть равнв 0 }

         LocalTagTable : TLocalTagTable; { Локальная таблица тэгов }

         OtmetchCikl : Ti16;    { Номер цикла для отметчика или 0 для
                                      сигнала }
         Angle     : TReal64;    { Угол установки отметчика при снятии
                                  сигнала }

         Offset    : TReal64;      { Смещение нуля сигнала }
         Reserv    : array [1..35] of Tu8; { Резерв }
end;


{------------------------------------------------------------------------------}
        { Таблица грузов для балансировки }

const BalansMassKol = 20; { Число строк в таблице грузов для балансировки }
Type TBalansMassRecord = packed record
       NumPlosk  : Ti16; { Номер плоскости }
       Mass      : TReal64; { Масса в граммах }
       Angle     : TReal64; { Угол в градусах }
end;
Type TBalansMass = array [1..BalansMassKol] of TBalansMassRecord;


{------------------------------------------------------------------------------}
     { Общая структура файла замера }

Type TZamerRecord = packed record
        ZamerSign           : TZamerSign; { Сигнатура файла замера }
        ZamerHeader         : TZamerHeader;     { Заголовок замера -
                                                  общие параметры }
        ZamerProperty       : TZamerProperty;   { Заголовок замера -
                                                  Диагностические признаки
                                                  файла замера }
        TechParam           : TTechParam;       { Таблица технологических
                                                  параметров }
        CommonParam         : TCommonParam;     { Остальные общие параметры
                                                  для замера }
        TagTable            : TTagTable;        { Таблица тэгов }
end;
{ Далее идет KolTabl штук TTabl }
{ Далее - любая инфа : отсчеты, значения тэгов ... }


{------------------------------------------------------------------------------}
{   Формирование имени файла замера
    Имя замера : MВГГММДД.XXX
                 || | | |  |
                 || | | |  + номер замера по порядку 001..999
                 || | | + день
                 || | + месяц
                 || + год div 100
                 |+ век 2 - 1900
                 |      3 - 2000
                 |      4 - 2100
                 + просто буква M - это замер

    Всего в один день может быть до 999 замеров.
    Пример : M2971005.008 - 8-ой замер от 05.10.1997
}

{------------------------------------------------------------------------------}


implementation


initialization
Assert(sizeof(TReal64)=8);
Assert(sizeof(Tc8)=1);
Assert(sizeof(Tu32)=4);
Assert(sizeof(TZamDate)=6);
Assert(sizeof(TZamTime)=6);

Assert(sizeof(TZamerHeader)=93);
Assert(sizeof(TZamerProperty)=72);
Assert(sizeof(TTechParamRecord)=10);
Assert(sizeof(TTechParam)=500);
Assert(sizeof(TTagTableRecord)=10);
Assert(sizeof(TTagTable)=300);

end.

