unit cb2gCode;
//
// Kniznica konvertovania dbAtomu --> gCode
//
// Visnovsky 28.11.2024
//

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, cb2Atom, cb2Graphics, cb2Vectors;

Const   Min_ContoureWidth    = 500;         // Minimalna dlzka pre vynechanie uchytu
        Cut_ContoureWidth    = 200;         // - dlzka vynechanej casti na uchyt

Var     FlopX   , FlopY      : Boolean;      // Optocenie obrazovky
        BFlopX  , BFlopY     : Boolean;      // Otocenie spodnej strany
        BEnCut  , BEnDrill   : Boolean;      // Povolenie vyrezu a dier z hornej strany;
        BEnContour           : Boolean;      // Povolenei kontury z hornej strany
//        iDrill               : Integer;      // Velkost vrtaka
        gCodeText            : TStrings;     // Text Gcode

// Procedury a funkcie
// - inicializacia
Procedure MyGCodeInicialize;
Procedure MyGCodeDestroy;
// - nastavenie prevratenia
Procedure SetgCodeFlopXY( Flop_X, Flop_Y : Boolean);
Procedure SetgCodeBackSideFlopXY( Flop_X, Flop_Y : Boolean);
Procedure SetgCodeBackSideLayer( aDrill, aCut, aContour : Boolean);
Procedure SetgCodeDrill( DrillWidth : Double);
Procedure SetgCodeZParameter(Zero_Z, Cut_Z, Copper_Z, Move_Z : Double);
Procedure SetgCodeBegin( Begin_X, Begin_Y, Begin_Z : Double);
Procedure SetgCodeFinish( End_X, End_Y, End_Z : Double);
Procedure SetgCodeOffsetZ ( Enable : Boolean );
// - Textove operacie
Procedure gcAddText (Str : TStrings); Overload;
Procedure gcAddText (FileName : String); Overload;
Procedure gcClearText;
// - konverzia cisla na retazec pomocou korekcie pretocenia
Function xNumToStr (num: Integer) : String;       // Konverzia pre generovanie Gcode
Function yNumToStr (num: Integer) : String;       // - Hodnota sa prevracia voci iHeight a iWidth
Function rxNumToStr(num: Integer) : String;       // - Hodnota sa prevracia voci 0(polomer)
Function ryNumToStr(num: Integer) : String;       // - Ovladane funkciou FlopXY

// - Vlozenie prikazu do gCodeText
Procedure AddTogCode(Typ, Layer: Byte; X, Y, ToX, ToY, R : Integer); Overload;
Procedure AddTogCode(Atm: pAtom); Overload;     // - vsetky vrstvy, okrem spodnej
Procedure AddBackLayerTogCode(Atm: pAtom);      // - iba spodna vrstva
// Hlavna procedura generovania
Procedure DrawToGcode;                          // - vsetky vrstvy
Procedure DrawBackSideToGcode;                  // - iba spodna vrstva
// pomocne procedury
Procedure gCode_GoToBegin;
Procedure gCode_GotoEnd;
Procedure gCode_GoToBackBegin;
Procedure gCode_GotoBackEnd;


implementation

Var GoToX   , GoToY   , GoToZ    : Integer;    // Pozadovana poloha
    CurrentX, CurrentY, CurrentZ : Integer;    // Momentalna poloha
    CutZ    , CopperZ , MoveZ    : Integer;    // Vyska Prednastavena poloha Z
    BeginX  , BeginY  , BeginZ   : Integer;    // Zaciatok
    EndX    , EndY    , EndZ     : Integer;    // koniec
    G2         : String;                       // Podla otocenia G2 a G3
    b_FlopX, b_FlopY             : Boolean;    // FlopXY pre zadnu stranu - tien
    ZOffsetEnable                : Boolean;    // Pouzivat odchylku Z

 // Inicializacia
Procedure MyGCodeInicialize;
 Begin
  // Hlavne premenne
  GoToX       := 0;
  GoToY       := 0;
  GoToZ       := 0;
  CurrentX    := 0;
  CurrentY    := 0;
  CurrentZ    := 0;
  G2          := 'G2';
  // Nastavenia predvolenych hodnot
  SetgCodeFlopXY             ( False, False );         // Nastavenie prevratenia
  SetgCodeBackSideFlopXY     ( True , False );         // - zadna strana -  prevratena os X
  SetgCodeDrill              ( 1.0);                   // Vrtak
  SetgCodeZParameter         ( 0, -2.2, -0.7, 5 );     // Nastavenie vrstiev
  SetgCodeBegin              ( 0, 0, 0 );              // Zaciatok
  SetgCodeFinish             ( 0, 0, 0 );              // Koniec
  // Text
  gCodeText   := TStringList.Create;
  // Povolenie odchylky
  zOffsetEnable := False;
 end;
// Uvolni pamat
Procedure MyGCodeDestroy;
 Begin
  gCodeText.Free;
 end;

 // Otocenie obrazovky
Procedure SetgCodeFlopXY( Flop_X, Flop_Y : Boolean);
 Begin
  FlopX := Flop_X;
  FlopY := Flop_Y;
  if FlopX xor FlopY Then G2:='G02' else G2:='G03';
 end;
Procedure SetgCodeBackSideFlopXY( Flop_X, Flop_Y : Boolean);
 Begin
  BFlopX := Flop_X;
  BFlopY := Flop_Y;
 end;
Procedure SetgCodeBackSideLayer( aDrill, aCut, aContour : Boolean);
 Begin
  BEnCut      := aCut;
  BEnDrill    := aDrill;
  BEnContour  := aContour;
 end;
Procedure SetgCodeDrill( DrillWidth : Double);
 Begin
  iDrill       := SpinToiNum(DrillWidth);       // Hrubka vrtaka
 end;
Procedure SetgCodeZParameter(Zero_Z, Cut_Z, Copper_Z, Move_Z : Double);
Var i : Integer;
 Begin
  i       := SpinToiNum(Zero_Z);       // nulove Z
  CutZ    := SpinToiNum(Cut_Z)    -i;  // - hodnota vytstrihnutia
  CopperZ := SpinToiNum(Copper_Z) -i;  // - hodnota medi
  MoveZ   := SpinToiNum(Move_Z)   -i;  // - hodnota presunu
 end;
Procedure SetgCodeBegin( Begin_X, Begin_Y, Begin_Z : Double);
 Begin
  BeginX := SpinToiNum(Begin_X);
  BeginY := SpinToiNum(Begin_Y);
  BeginZ := SpinToiNum(Begin_Z);
 end;
Procedure SetgCodeFinish( End_X, End_Y, End_Z : Double);
 Begin
  EndX := SpinToiNum(End_X);
  EndY := SpinToiNum(End_Y);
  EndZ := SpinToiNum(End_Z);
 end;
Procedure SetgCodeOffsetZ ( Enable : Boolean );
 Begin
  zOffsetEnable := Enable;
 end;

 // Funkcie pre generovanie GCode - konverzia cez FLOP X,Y
Function  xNumToStr(num: Integer) : String;
 Begin
 if FlopX Then num:=cb2Graphics.iWidth-num;
 Result:=cb2Graphics.iNumToStr(num);
end;
Function  yNumToStr(num: Integer) : String;
Begin
 if FlopY Then num:=cb2Graphics.iHeight-num;
 Result:=cb2Graphics.iNumToStr(num);
end;
// - vypocet polomeru polomer
Function  rxNumToStr(num: Integer) : String;
Begin
 if FlopX Then num:=(-1)*num;
 Result:=cb2Graphics.iNumToStr(num);
end;
Function  ryNumToStr(num: Integer) : String;
Begin
 if FlopY Then num:=(-1)*num;
 Result:=cb2Graphics.iNumToStr(num);
end;
// - vypocet pre pre spodnu cast dosky

// Funkcie Textu
Procedure gcAddText (Str : TStrings); Overload;
 Var i : Integer;
 Begin
  For i:=1 to Str.Count do
   Begin
    gCodeText.Append(Str.Strings[i-1]);
   end;
 end;
Procedure gcAddText (FileName : String); Overload;
 Var i   : Integer;
     Str : TStrings;
 Begin
  Str:= TStringList.Create;
  Str.LoadFromFile(FileName);
  For i:=1 to Str.Count do
   Begin
    gCodeText.Append(Str.Strings[i-1]);
   end;
  Str.Free;
 end;
Procedure gcClearText;
 Begin
  gCodeText.Clear;
 end;

 // Nastavenie Z
 Procedure gcZToMove;    // Z pozicia presuvu
  var oZ : Integer;
  Begin
   // povoleny offset
   oZ := 0;
   if zOffsetEnable Then oZ:=wvsGetZ(CurrentX, CurrentY);
   //
   if (CurrentZ<>(MoveZ+oz)) Then gCodeText.Append('G00 Z'+iNumToStr((MoveZ+oz)));
   CurrentZ := (MoveZ+oz);
  end;
 Procedure gcZToCut;     // Z pozicia Kontura a diery
  var oZ : Integer;
  Begin
   // povoleny offset
   oZ := 0;
   if zOffsetEnable Then oZ:=wvsGetZ(CurrentX, CurrentY);
   //
   if (CurrentZ<>(CutZ+oZ)) Then
    Begin
     if CurrentZ<(CutZ+oZ)  Then gCodeText.Append('G00 Z'+iNumToStr((CutZ+oZ)))
      Else Begin
       if (CurrentZ>oZ) Then gCodeText.Append('G00 Z'+iNumToStr(oZ));
       gCodeText.Append('G01 Z'+iNumToStr((CutZ+oZ)));
      End;
    End;
   CurrentZ := (CutZ+oZ);
  end;
 Procedure gcZToCopper;  // Z pozicia cesty
  var oZ : Integer;
  Begin
   // povoleny offset
   oZ := 0;
   if zOffsetEnable Then oZ:=wvsGetZ(CurrentX, CurrentY);
   //
   if (CurrentZ<>(CopperZ+oZ)) Then
    Begin
     if CurrentZ<(CopperZ+oZ) Then gCodeText.Append('G00 Z'+iNumToStr((CopperZ+oZ)))
      Else Begin
       if (CurrentZ>oZ)   Then gCodeText.Append('G00 Z'+iNumToStr(oZ));
       gCodeText.Append('G01 Z'+iNumToStr((CopperZ+oZ)));
      End;
    End;
   CurrentZ:=(CopperZ+oZ);
  end;
 // Nastavene
 Procedure gcZIsCut;
  Begin
   GoToZ := CutZ;
  end;
 Procedure gcZIsCopper;
  Begin
   GoToZ := CopperZ;
  end;
 Procedure gcZIsMove;
  Begin
   GoToZ :=MoveZ;
  end;
 Procedure gcZIsZero;
  Begin
   GoToZ := 0;
  end;
 // Posuv
 Procedure gcToCurrent; Overload;
  Begin
   CurrentX:=GoToX;
   CurrentY:=GoToY;
   CurrentZ:=GoToZ;
  end;
 // pripocet z
 Procedure gcToCurrent(OffsetZ : Integer); Overload;
  Begin
   CurrentX:=GoToX;
   CurrentY:=GoToY;
   CurrentZ:=GoToZ + OffsetZ;
  end;
 // pripocet - najst offset
 Procedure gcToCurrent(OffsetZ : Boolean); Overload;
  var oZ : Integer;
  Begin
   // povoleny offset
   oZ := 0;
   if zOffsetEnable and OffsetZ Then oZ:=wvsGetZ(GoToX, GoToY);
   //
   CurrentX:=GoToX;
   CurrentY:=GoToY;
   CurrentZ:=GoToZ + oz;
  end;
 // - Vracia prepocitanu poziciu Z
 Function gcGetGoToZPos : Integer;
  var oZ : Integer;
  Begin
   // povoleny offset
   oZ := 0;
   if zOffsetEnable Then oZ:=wvsGetZ(GoToX, GoToY);
   Result := GoToZ + oz;
  end;
 // Posuv
 Procedure gcMove;        // Posuv
  var oZ : Integer;
  Begin
   // povoleny offset
   oZ := 0;
   if zOffsetEnable Then oZ:=wvsGetZ(GoToX, GoToY);
   //
   if (GoToX<>CurrentX) or (GoToY<>CurrentY) Then
    Begin
     gcZToMove;
     if zOffsetEnable Then gCodeText.Append('G00 X'+xNumToStr(GotoX)+' Y'+yNumToStr(GotoY)+' Z'+yNumToStr(MoveZ+oz))
                      Else gCodeText.Append('G00 X'+xNumToStr(GotoX)+' Y'+yNumToStr(GotoY));
    end;
   if (GotoZ+oZ)<>CurrentZ Then
     Begin
      if ((GotoZ+oZ)<0) and ((GotoZ+oZ)<CurrentZ) Then
       Begin
        gCodeText.Append('G00 Z'+iNumToStr(oZ));
        gCodeText.Append('G01 Z'+iNumToStr((GotoZ+oZ)));
       end else gCodeText.Append('G00 Z'+iNumToStr((GotoZ+oZ)));
     end;
   gcToCurrent(oz);
  end;
 // Nastavenia XY
 Procedure gcSetXY(X, Y : Integer);
  Begin
   GoToX:=X;
   GotoY:=Y;
  end;
 Procedure gcGoToXY;     // Pomally posuv na XY
  var oZ : Integer;
  Begin
   // povoleny offset
   oZ := 0;
   if zOffsetEnable Then oZ:=wvsGetZ(GoToX, GoToY);
   //
   if zOffsetEnable Then gCodeText.Append('G01 X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY)+' Z'+iNumToStr(GoToZ+oZ))
                    else gCodeText.Append('G01 X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY));
   gcToCurrent(oz);
  end;
 // LAYER to Z
 Procedure gcLayerToZ (Layer : Byte);
  Begin
   Case Layer of
    tCut     : gcZIsCut;
    tCopper  : gcZIsCopper;
    tContour : gcZIsCut;
    tBackCp  : gcZIsCopper;
    else       gcZIsMove;
   end;
  end;

// Dekodovanie prikazu a vlozenie do gCodeText
Procedure AddTogCode(Typ, Layer: Byte; X, Y, ToX, ToY, R : Integer); Overload;
 Var i : Integer;
 Begin
   // Odfiltrovanie nepouzivanych vrstiev
   If (Layer = tCut) or (Layer = tCopper) or (Layer = tContour) or (Layer = tBackCp) Then
    Begin
     gcLayerToZ(Layer); // nastavenie Z podla vrstvy
     Case Typ of
      // -- Diera
      tHole : Begin     // DIERA
       GoToX:=X;             // - Nastavenie XY
       GotoY:=Y;
       gcMove;               // - Chod na poziciu
       If (iDrill < R) Then  // Vacsia diera
        Begin
         i:= (R - iDrill) div 2;
         GotoX:= X - i;
         gcGoToXY;
         gCodeText.Append('G02 X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY)+
                          ' I'+rxNumToStr(i)+' J0');
        end;                // koniec vacsej diery
       gcToCurrent(True);   // Uloz suradnice ako vychodzie
       end;
      // Kruznica
      tCircle : Begin     // Kruznica
       i:= R div 2;
       GotoX:= X - i;
       GotoY:= Y;
       gcMove;            // - Chod na poziciu
       gCodeText.Append('G02 X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY)+
                        ' I'+rxNumToStr(i)+' J0');
       gcToCurrent(True);
       end;
      // Cesta - ciara
      tWay: Begin         // Cesta
        GoToX:=X;         // Nastavenie XY
        GotoY:=Y;
        gcMove;           // - chod na miesto
        If Layer = tContour Then
         Begin            // Kontura
          // Horizontalna ciara
          if (Y = ToY) and (Abs(X-ToX) > Min_ContoureWidth) Then
           Begin
            gcZToCopper;
            gcZIsCopper;
            if (X < ToX) Then
             Begin
              GoToX := GoToX + Cut_ContoureWidth;
             end else begin
              GoToX := GoToX - Cut_ContoureWidth;
             end;
             gcGoToXY;
             gcZToCut;
             gcLayerToZ(Layer); // nastavenie Z podla vrstvy
           end;
          // Vertikalna ciara
          if (X = ToX) and (Abs(Y-ToY) > Min_ContoureWidth) Then
           Begin
            gcZToCopper;
            gcZIsCopper;
            if (Y < ToY) Then
             Begin
              GoToY := GoToY + Cut_ContoureWidth;
             end else begin
              GoToY := GoToY - Cut_ContoureWidth;
             end;
             gcGoToXY;
             gcZToCut;
             gcLayerToZ(Layer); // nastavenie Z podla vrstvy
           end;
         End;           // - koniec delenia podla vrstvy
        GoToX:=ToX;     // Nastavenie XY
        GotoY:=ToY;
        gcGoToXY;       // - rez ciaru
        gcToCurrent(True);     // - uloz suradnicu
       end;
       // Obdlznik zaobleny
      tRectangle: Begin
        // Zistenie smerovania
        If X>ToX Then
         Begin
          i  := X;
          X  := ToX;
          ToX:= i;
         End;
        If Y>ToY Then
         Begin
          i  := Y;
          Y  := ToY;
          ToY:= i;
         End;
        // Zaciname
        GoToX:=X + R;
        GoToY:=Y;
        gcMove;
        // ak ide o konturu
        If (Layer = tContour) and ((ToX-X-R-R) > Min_ContoureWidth) Then
         Begin            // Kontura
          gcZToCopper;
          gcZIsCopper;
          GotoX :=X + R + Cut_ContoureWidth;
          gcGoToXY;
          gcZToCut;
          gcLayerToZ(Layer); // nastavenie Z podla vrstvy
         end;
        GoToX := ToX - R;
        gcGoToXY;
        GotoX := ToX;
        GoToY := Y + R;
        // gcGetGoToZPos
        gCodeText.Append(G2+' X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY)+
                         ' Z'+iNumToStr(gcGetGoToZPos)+' I0 J'+ryNumToStr(R));
        gcToCurrent(True);     // - uloz suradnicu
        GotoY := ToY - R;
        gcGoToXY;
        GoToX := ToX - R;
        GotoY := ToY;
        gCodeText.Append(G2+' X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY)+
                         ' Z'+iNumToStr(gcGetGoToZPos)+' I'+rxNumToStr((-1)*R)+' J0');
        gcToCurrent(True);     // - uloz suradnicu
        // ak ide o konturu
        If (Layer = tContour) and ((ToX-X-R-R) > Min_ContoureWidth) Then
         Begin            // Kontura
          gcZToCopper;
          gcZIsCopper;
          GotoX := ToX - R - Cut_ContoureWidth;
          gcGoToXY;
          gcZToCut;
          gcZIsCut;
          gcLayerToZ(Layer); // nastavenie Z podla vrstvy
         end;
        GoToX := X + R;
        gcGoToXY;
        GotoX := X;
        GoToY := ToY - R;
        gCodeText.Append(G2+' X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY)+
                         ' Z'+iNumToStr(gcGetGoToZPos)+' I0 J'+ryNumToStr((-1)*R));
        gcToCurrent(True);     // - uloz suradnicu
        GoToY := Y + R;
        gcGoToXY;
        GoToX := X + R;
        GoToY := Y;
        gCodeText.Append(G2+' X'+xNumToStr(GoToX)+' Y'+yNumToStr(GoToY)+
                        ' Z'+iNumToStr(gcGetGoToZPos)+' I'+rxNumToStr(R)+' J0');
        gcToCurrent(True);
       end;
      End; // koniec CASE
    End;   // koniec Podmienky vrstvy
 End;
Procedure AddTogCode(Atm: pAtom); Overload;
 Begin
  if (Atm^.Layer <> tBackCp) and (Atm^.Layer <> tBContour) Then
   AddTogCode(Atm^.Typ, Atm^.Layer, Atm^.X, Atm^.Y, Atm^.ToX, Atm^.ToY, Atm^.R);
 End;
Procedure AddBackLayerTogCode(Atm: pAtom);
 Begin
  if ((Atm^.Layer = tHole   ) and BEnDrill)   or
     ((Atm^.Layer = tCut    ) and BEnCut)     or
     ((Atm^.Layer = tContour) and BEnContour) or
      (Atm^.Layer = tBackCp)  or (Atm^.Layer = tBContour) Then Begin
    // ak su splnene vsetky podmienky                    +- Tu -+
    if  Atm^.Layer = tBContour Then AddTogCode(Atm^.Typ, tContour, Atm^.X, Atm^.Y, Atm^.ToX, Atm^.ToY, Atm^.R)
                               Else AddTogCode(Atm^.Typ, Atm^.Layer, Atm^.X, Atm^.Y, Atm^.ToX, Atm^.ToY, Atm^.R);

   end;
 End;

// Hlavna procedura vytvorenie gCodu
Procedure DrawToGcode;
Begin
  gCodeText.Append('; --- Begin of generate gCode ---');
  // Nastavenie vychodiskoveho bodu
  CurrentX := BeginX;
  CurrentY := BeginY;
  CurrentZ := BeginZ;
  // Prva slucka
  aFirst;
  Repeat
   if Atom<>Nil Then
    Begin   // Atom existuje
     if Atom^.Layer <> tContour Then
      Begin // nie je kontura
       AddTogCode(Atom);  // Vykonaj
      End;  // nie je kontura
    End;    // atom existuje
  Until (Not aNext);
  // Kontura nakoniec
  aFirst;
  Repeat
   if Atom<>Nil Then
    Begin   // Atom existuje
     if Atom^.Layer = tContour Then
      Begin // je kontura
       AddTogCode(Atom);  // Vykonaj
      End;  // je kontura
    End;    // atom existuje
  Until (Not aNext);
  // Koniec vratenie na poslednu polohu
  GotoX := EndX;
  GotoY := EndY;
  GotoZ := EndZ;
  gcMove;
  gCodeText.Append('; --- End of generate gCode ---');
end;
// - Hlavna procedura vytvorenia zadnej strany gCode
Procedure DrawBackSideToGcode;
Begin
  // Nastavenie otoccenia vrstvy
  b_FlopX := FlopX;
  b_FlopY := FlopY;
  SetgCodeFlopXY(bFlopX, bFlopY);
  // - zapis textu
  gCodeText.Append('; --- Begin of generate gCode ---');
  // Nastavenie vychodiskoveho bodu
  CurrentX := BeginX;
  CurrentY := BeginY;
  CurrentZ := BeginZ;
  // Prva slucka
  aFirst;
  Repeat
   if Atom<>Nil Then
    Begin   // Atom existuje
     AddBackLayerTogCode(Atom);  // Vykonaj
    End;    // atom existuje
  Until (Not aNext);
  // Koniec vratenie na poslednu polohu
  GotoX := EndX;
  GotoY := EndY;
  GotoZ := EndZ;
  gcMove;
  gCodeText.Append('; --- End of generate gCode ---');
  // Vtrat naspat hodnoty flopXY
  SetgCodeFlopXY(b_FlopX, b_FlopY);
end;

// Procedury pre externe volanie a tvorenie gCodu
Procedure gCode_GoToBegin;
 Begin
  CurrentX := BeginX;
  CurrentY := BeginY;
  CurrentZ := BeginZ;
 end;
Procedure gCode_GotoEnd;
 Begin
  GotoX := EndX;
  GotoY := EndY;
  GotoZ := EndZ;
  gcMove;
 end;
Procedure gCode_GoToBackBegin;
 Begin
  b_FlopX := FlopX;
  b_FlopY := FlopY;
  SetgCodeFlopXY(bFlopX, bFlopY);
  CurrentX := BeginX;
  CurrentY := BeginY;
  CurrentZ := BeginZ;
 end;
Procedure gCode_GotoBackEnd;
 Begin
  GotoX := EndX;
  GotoY := EndY;
  GotoZ := EndZ;
  gcMove;
  SetgCodeFlopXY(b_FlopX, b_FlopY);
 end;


end.

