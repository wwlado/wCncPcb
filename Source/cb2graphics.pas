unit cb2Graphics;
//
// Kniznica konvertovania dbAtomu --> Bitmap
//
// Visnovsky 28.11.2024
//

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LCLIntf, Graphics, cb2Atom, cb2Vectors;

// Konstanty
Const Color_Grid   = clRed;                      // Farba mriezky
      Color_Cursor = clRed;                      // Farba kurzora
      Width_Cursor = 1;                          // - Hrubka kurzora
      Color_mCut   = clFuchsia;                  // Farba vyrezu   - mys
      Color_mContour = clFuchsia;                // Farba vyrezu   - mys
      Color_mBContour = clYellow;                // Farba vyrezu   - mys - Horna strana
      Color_mCopper= clLime;                     // Farva mede     - mys
      Color_mBackCp= clRed;                      // Farva mede zo zadu  - mys
      Color_mLabel = clGray;                     // Farba znacenia - mys
      Color_mPoint = clMoneyGreen;               // Farba uchytovacieho bodu - clSkyBlue, clCream
      Color_Cut    = clPurple;                   // Farba vyrezu
      Color_Contour= clPurple;                   // Farba vyrezu kontury
      Color_BContour= clOlive;                  // Farba vyrezu kontury - Horna strana
      Color_Copper = clGreen;                    // Farva mede
      Color_BackCp = clMaroon;                   // Farva mede zo zadnej strany
      Color_Label  = clGray;                     // Farba znacenia
      Color_Point  = clMoneyGreen;               // Farba uchytovacieho bodu - clSkyBlue, clCream
      Color_Select = $8080FF;                    // Farba vybranej polozky
      Color_Light  = $C0C0FF;                    // Farba zvyraznenej polozky
      Color_Mouse  = $FFFFFE;                    // Farba pre schemu MYS
      Color_Normal = $FFFEFF;                    // Normalna farebna schema
      Color_Shadow = clSilver;                   // Farba pri cnc rezime
      Border_Right = 3;                          // Uchyt z prava
      Border_Down  = 3;                          // Uchyt z dola

// Typy objektu a vrstvy
Const tHole        = 1;                          // Diera - r je vnutorny polomer
      tCircle      = 2;                          // Kruh  - rozmery od do
      tWay         = 3;                          // Ciara - cesta
      tText        = 4;                          // Text  - iba popis
      tRectangle   = 5;                          // Stvorec - r je zaoblenie
      tComponent   = 6;                          //
      tCopper      = 100;                        // Medena vrstva
      tBackCp      = 101;                        // Medena vrstva z druhej strany
      tCut         = 110;                        // Rez
      tMarker      = 120;                        // Popis
      tContour     = 130;                        // Kontura - vyrez plosneho spoja
      tBContour    = 140;                        // - zadna kontura
      tBegin       = 0;                          // Vseobecne edit
      tSelect      = 253;
      tPosHan      = 254;                        // Uchopovač

// Velkost pisma pri zoomIndexe
Const FontSizeIndex_0 = 2;
      FontSizeIndex_1 = 5;
      FontSizeIndex_2 = 10;
      FontSizeIndex_3 = 20;
      FontSizeIndex_4 = 40;

// Premenne
var iWidth          , iHeight    : Integer;      // rozmer pracovnej plochy v 0.01mm
    iOffsetX        , iOffsetY   : Integer;      // offset komponentu
    iCursorStep     , iGridStep  : Integer;      // krok posuvu kurzora a mriezky v 0.01mm
    ZoomIndex                    : Integer;      // Index zvacsenia
                                                 // 0 - 0.25x; 1 - 0.5x; 2 - 1x; 3 - 2x; 4 - 4x
    MyX             , MyY        : Integer;      // Pozicia kurzora v iNum
    iDrill                       : Integer;      // Velkost vrtaka
    cncView                      : Boolean;      // Zobrazenie CNC
    FontSizeIndex                : Integer;      // Velkost fontu

// Objekty
var MyBitmap                     : TBitmap;      // Bitova Mapa


// Vytvorenie
Procedure MyGraphicsInitialize;

// Konvertovanie
Function iNumToPix (num : Integer): Integer;      // 0.01mm na pixely
Function PixToiNum (num : Integer): Integer;      // Pixely na 0.01mm
Function SpinToiNum(num : Double) : Integer;      // Float(Double) na 0.01mm
Function iNumToSpin(num : Integer) : Double;      // 0.01mm na Float
Function iNumToStr (num: Integer) : String;       // 0.01mm na retazec
Function xCursorStep(X, MaxX : Integer) : Integer;// Zaoukruhlenie suradnici X podla iCursorStep
Function yCursorStep(Y, MaxY : Integer) : Integer;// Zaoukruhlenie suradnici Y podla iCursorStep
Function posCursorStep (pos : Integer) : Integer; // --//--
// Nacitanie hodnot z komponentov
Procedure LoadSizeFromSpinEdit(iX, iY : Double);  // nacitanie velkosti zo SpinEditu
Procedure LoadOffsetFromSpinEdit(iX, iY : Double);// nasitanie offestu
Procedure LoadStepsFromSpinEdit(iGrid, iCursor : Double);
Procedure LoadZoom (Index : Integer);
Procedure ChangeZoom (Minus : Boolean);
Procedure LoadDrillFromSpinEdit( DrillWidth : Double);
Procedure LoadComponentOrientation(cFlopX, cFlopY, cRotate90 : Boolean);
Procedure LoadLayerEnable(cCopper, cBackCp, cMarker : Boolean);
Function cncSetView (EnableCncView : Boolean) : Boolean;

// Vytvorenie obrazu
Procedure RebuildBitmap;
// Nakresli kurzor
Procedure DrawCursor(Pic : TCanvas; X, Y : Integer);

// Vykreslenie komponentu do Canvasu
Procedure AddToCanvas(Pic : TCanvas; Colour : TColor; Typ, Layer: Byte; X, Y, ToX, ToY, R : Integer; Name: String ); OverLoad;
Procedure AddToCanvas(Pic : TCanvas; Colour : TColor; Atm : pAtom); OverLoad;
Procedure dbDrawToCanvas (Pic : TCanvas; dbA : TAtomDatabase; IsMouse: Boolean; X, Y : Integer);
Procedure aAppendComponent (dbA : TAtomDatabase; X, Y : Integer);

// Hlavna procedura vykreslenia
Procedure DrawToBitmap;
Procedure DrawToBitmapAndSaveTo ( FileName : String; aCut, aContour, aCopper, aBackCp, aMarker : Boolean);

implementation

Var
   comFlopX, comFlopY, comRotate : Boolean;      // Otocenie komponentu
   elCopper, elBackCp, elMarker  : Boolean;      // Povolenie vykreslenia vrstiev
   comOffsetX, comOffsetY        : Integer;      // Posuv v komponente


// Inicializacia
Procedure MyGraphicsInitialize;
 Begin
  ZoomIndex   := 2;            // 1x
  iCursorStep := 50;           // Krok Kurzora - 0.5mm
  iGridStep   := 100;          // Krok mriezky - 1mm
  LoadSizeFromSpinEdit(40, 40);// Nastavenie velkosti na 4cm
  LoadOffsetFromSpinEdit(0, 0);// Nastavenie offsetu na nulu
  LoadComponentOrientation(false, false, false);
  LoadLayerEnable(True, True, True);
  comOffsetX := 0;
  comOffsetY := 0;
  cncView    := False;
  // Vytvorenie bitmapy
  MyBitmap:= TBitmap.Create;
 end;


// Prekonvertovanie hodnoty cez ZOOM
Function  iNumToPix(num : Integer) : Integer;
Begin
 num:=num div 10;
 Case ZoomIndex of
  0 : Result:=num div 4;
  1 : Result:=num div 2;
  2 : Result:=num;
  3 : Result:=num * 2;
  4 : Result:=num * 4;
  Else Result:=num;
 End;
End;
// Prekonvertovanie hodnoty cez ZOOM
Function  PixToiNum(num : Integer) : Integer;
Begin
 num:=num * 10;
 Case ZoomIndex of
  0 : Result:=num * 4;
  1 : Result:=num * 2;
  2 : Result:=num;
  3 : Result:=num div 2;
  4 : Result:=num div 4;
  Else Result:=num;
 End;
End;
// Prekonvertovanie FloatSpinEdit na iNum
Function SpinToiNum(num : Double) : Integer;
Begin
 Result:=Trunc(num * 100);
End;
// Prekonvertovanie iNum na Float
Function iNumToSpin(num : Integer) : Double;
Begin
 Result:=num / 100;
End;
// Prelozenie z iNum na retazec
Function iNumToStr(num: Integer) : String;
Var s, sing : String;
    iq, iw  : Integer;
Begin
 sing:='';
 s:=IntToStr(num);
 if num<>0 then
  Begin
   if num<0 then sing:='-';
   num:=Abs(num);
   iq:=(num div 100);
   iw:=num - (iq * 100);
   s:=Sing+IntToStr(iq);
   if iw>0 Then
    Begin
     if iw>9 Then
      Begin
       s:=s+'.'+IntToStr(iw);
      end else begin
       s:=s+'.0'+IntToStr(iw);
      end;
    End else s:=s+'.00';
  end;
 Result:=s;
end;
// Funkcia prepoctu kurzora - zaokruhlenie
Function  xCursorStep(X, MaxX : Integer) : Integer;
 Begin
  MyX:=PixToiNum(X);
  if X<(MaxX-Border_Right) Then  MyX:=(MyX div iCursorStep) * iCursorStep else MyX:=iWidth;
  Result:=iNumToPix(MyX);
 end;
Function  yCursorStep(Y, MaxY : Integer) : Integer;
 Begin
  MyY:=PixToiNum(Y);
  if Y<(MaxY-Border_Down) Then  MyY:=(MyY div iCursorStep) * iCursorStep else MyY:=iHeight;
  Result:=iNumToPix(MyY);
 end;
Function posCursorStep (pos : Integer)   : Integer;
 Begin
  Result := (Pos div iCursorStep) * iCursorStep;
 End;

// Velkost pracovneho prostredia
Procedure LoadSizeFromSpinEdit(iX, iY : Double);
 Begin
  iWidth  := SpinToiNum(iX);
  iHeight := SpinToiNum(iY);
 end;
Procedure LoadOffsetFromSpinEdit(iX, iY : Double);
 Begin
  iOffsetX := SpinToiNum(iX);
  iOffsetY := SpinToiNum(iY);
 end;
// nacitanie kurzora a mriezky
Procedure LoadStepsFromSpinEdit(iGrid, iCursor : Double);
 Begin
  iCursorStep  := SpinToiNum(iCursor);
  iGridStep    := SpinToiNum(iGrid);
 End;
// Nastavenie zoom index
Procedure LoadZoom (Index : Integer);
 Begin
  ZoomIndex := Index;
  If ZoomIndex < 0 Then ZoomIndex := 0;
  If ZoomIndex > 4 Then ZoomIndex := 4;
  // Velkost pisma
  Case ZoomIndex of
   0 : FontSizeIndex:=FontSizeIndex_0;
   1 : FontSizeIndex:=FontSizeIndex_1;
   2 : FontSizeIndex:=FontSizeIndex_2;
   3 : FontSizeIndex:=FontSizeIndex_3;
   4 : FontSizeIndex:=FontSizeIndex_4;
  end;
 end;
// zmena zumu
Procedure ChangeZoom (Minus : Boolean);
Begin
 If Minus Then  Dec (ZoomIndex)
          Else  Inc (ZoomIndex);
 If ZoomIndex < 0 Then ZoomIndex := 0;
 If ZoomIndex > 4 Then ZoomIndex := 4;
 // Velkost pisma
 Case ZoomIndex of
  0 : FontSizeIndex:=FontSizeIndex_0;
  1 : FontSizeIndex:=FontSizeIndex_1;
  2 : FontSizeIndex:=FontSizeIndex_2;
  3 : FontSizeIndex:=FontSizeIndex_3;
  4 : FontSizeIndex:=FontSizeIndex_4;
 end;
end;
// nastavy nastavenia otocenia komponentu
Procedure LoadComponentOrientation(cFlopX, cFlopY, cRotate90 : Boolean);
 begin
  comFlopX  :=cFlopX;
  comFlopY  :=cFlopY;
  comRotate := cRotate90;
 end;
// nastavenie hrubky vrtaka
Procedure LoadDrillFromSpinEdit( DrillWidth : Double);
 Begin
  iDrill       := SpinToiNum(DrillWidth);       // Hrubka vrtaka
 end;
// nastavenie vykreslenia vrstiev
Procedure LoadLayerEnable(cCopper, cBackCp, cMarker : Boolean);
 begin
  elCopper := cCopper;
  elBackCp := cBackCp;
  elMarker := cMarker;
 end;

// nastavenie zobrazenia pre cnc
Function cncSetView (EnableCncView : Boolean) : Boolean;
 Begin
  Result  := cncView <> EnableCncView;
  cncView := EnableCncView;
 end;

// Vytrvorenie bitmapy
Procedure RebuildBitmap;
 var i,j,k : Integer;
     c     : TColor;
begin
// Nastavenie velkosti
MyBitmap.SetSize(iNumToPix(iWidth)+1,
                 iNumToPix(iHeight)+1);
MyBitmap.Canvas.Brush.Style  :=bsClear;
MyBitmap.Canvas.Pen.Color    :=clWhite;
MyBitmap.Canvas.Brush.Color  :=clWhite;
MyBitmap.Canvas.FillRect(0, 0, MyBitmap.Width, MyBitmap.Height);
MyBitmap.Canvas.Pen.Color    :=clBlack;
MyBitmap.Canvas.Pen.Width    :=1;
// Mriezka
j:=0;
c:=Color_Grid;
While j<=iHeight do
 Begin
  i:=0;
  While i<=iWidth do
   Begin
    if wvIsVaild then
     begin
      k:=wvsGetZ(i, j)*10;
      if k<(-255) Then c := RGB(255, 0, 0);
      if k>( 255) Then c := RGB(0, 0, 255);
      if k=0      Then c := RGB(0, 0, 0);
      if (k>0) and (k< 256) Then c := RGB(0, 0, k);
      if (k<0) and (k>-256) Then c := RGB(Abs(k), 0, 0);
      MyBitmap.Canvas.Pixels[iNumToPix(i)-1, iNumToPix(j)]:=c;
      MyBitmap.Canvas.Pixels[iNumToPix(i)+1, iNumToPix(j)]:=c;
      MyBitmap.Canvas.Pixels[iNumToPix(i), iNumToPix(j)+1]:=c;
      MyBitmap.Canvas.Pixels[iNumToPix(i), iNumToPix(j)-1]:=c;
      MyBitmap.Canvas.Pixels[iNumToPix(i)-1, iNumToPix(j)-1]:=c;
      MyBitmap.Canvas.Pixels[iNumToPix(i)+1, iNumToPix(j)-1]:=c;
      MyBitmap.Canvas.Pixels[iNumToPix(i)-1, iNumToPix(j)+1]:=c;
      MyBitmap.Canvas.Pixels[iNumToPix(i)+1, iNumToPix(j)+1]:=c;
     end;
    MyBitmap.Canvas.Pixels[iNumToPix(i), iNumToPix(j)]:=c;
    i:=i+iGridStep;
   end;
  j:=j+iGridStep;
 end;
 // Vykreslenie atomov
 DrawToBitmap;
end;

// Vykreslenie kurzora
Procedure DrawCursor(Pic : TCanvas; X, Y : Integer);
 Begin
  Pic.Pen.Color:=Color_Cursor;
  Pic.Pen.Width:=Width_Cursor;
  Pic.Line(0, Y, iNumToPix(iWidth), Y );
  Pic.Line(X, 0, X, iNumToPix(iHeight));
 end;

// Vykreslenie komponnentov
Procedure AddToCanvas(Pic : TCanvas; Colour : TColor; Typ, Layer: Byte; X, Y, ToX, ToY, R : Integer; Name: String ); OverLoad;
 Var D, Ang : Integer;
 Begin
  // povolenie vykreslenia vrstvy
  If ((Layer=tCopper) and elCopper) Or ((Layer=tBackCp) and elBackCp) Or
     ((Layer=tMarker) and elMarker) Or (Layer=tCut) Or (Layer=tContour) Or (Layer=tBContour)  Then
  BEGIN
  // Nastavenie farby
  If Colour = Color_Normal Then                       // Pouzita normalna schema
   Begin
    If Layer = tCut      Then Colour := Color_Cut;
    If Layer = tContour  Then Colour := Color_Contour;
    If Layer = tBContour Then Colour := Color_BContour;
    If Layer = tCopper   Then Colour := Color_Copper;
    If Layer = tBackCp   Then Colour := Color_BackCp;
    If Layer = tMarker   Then Colour := Color_Label;
    if Typ   = tPosHan   Then Colour := Color_Point;
   end;
  If Colour = Color_Mouse Then                        // Pouzita schema pre mys
   Begin
    If Layer = tCut      Then Colour := Color_mCut;
    If Layer = tContour  Then Colour := Color_mContour;
    If Layer = tBContour Then Colour := Color_mBContour;
    If Layer = tCopper   Then Colour := Color_mCopper;
    If Layer = tBackCp   Then Colour := Color_mBackCp;
    If Layer = tMarker   Then Colour := Color_mLabel;
    if Typ   = tPosHan   Then Colour := Color_mPoint;
   end;
  // Prevod cisel
  Ang := R; // Uhol
  X:=   iNumToPix(X);
  Y:=   iNumToPix(Y);
  ToX:= iNumToPix(ToX);
  ToY:= iNumToPix(ToY);
  R:=   iNumToPix(R);
  D:=   iNumToPix(iDrill);
  // Vykreslenie do canvas
  Case Typ of
   tHole: Begin // Diera
     Pic.Pen.Width   := 1;
     Pic.Pen.Color   := clBlack;
     Pic.Brush.Style := bsClear;
     Pic.Brush.Color := Colour;
     R:=R div 2;
     Pic.Ellipse(X-R, Y-R, X+R, Y+R);
    end;
   tCircle: Begin // Kruh
     if Layer = tMarker Then Pic.Pen.Width   := 3
                        Else Pic.Pen.Width   := D;
     Pic.Pen.Color   := Colour;
     Pic.Brush.Style := bsClear;
     //Pic.Brush.Color := clNone;
     R:= R div 2;
     Pic.Ellipse(X-R, Y-R, X+R, Y+R);
    end;
   tWay: Begin // Cesta
     if Layer = tMarker Then Pic.Pen.Width   := 3
                        Else Pic.Pen.Width   := D;
     //Pic.Pen.Width   := D;
     Pic.Pen.Color   := Colour;
     Pic.Brush.Style := bsClear;
     Pic.Brush.Color := Colour;
     Pic.Line(X, Y, ToX, ToY);
    end;
   tRectangle: Begin // Stvorec
     Pic.Pen.Width   := D;
     Pic.Pen.Color   := Colour;
     Pic.Brush.Style := bsClear;
     //Pic.Brush.Color := clNone;
     Pic.RoundRect(X, Y, ToX, ToY, R*2, R*2);
    end;
   tText: Begin // Cesta
     Pic.Pen.Width   := 1;
     Pic.Pen.Color   := Colour;
     Pic.Brush.Style := bsClear;
     If Colour<>clBlack Then
      Begin
       Pic.Line(X, Y-2, X, Y+3);
       Pic.Line(X-2, Y, X+3, Y);
      end;
     //Pic.Brush.Color := clNone;
     Pic.Font.Color  := Colour;
     Case Ang of
      1   : Pic.Font.Orientation:=900;
      2   : Pic.Font.Orientation:=1800;
      3   : Pic.Font.Orientation:=2700;
      else
       Pic.Font.Orientation:=0;
      end;
     Pic.Font.Size:=FontSizeIndex;
     Pic.TextOut(X, Y, Name);
    end;
   tPosHan: Begin // Uchyt
     Pic.Pen.Width   := 1;
     Pic.Pen.Color   := Colour;
     Pic.Brush.Style := bsClear;
     Pic.Brush.Color := Colour;
     Pic.Line(X, Y-5, X, Y+6);
     Pic.Line(X-5, Y, X+6, Y);
    end;
  end;  // koniec Case
  END; // povolenie vykreslenie vrstvy
 end;
// - v podobe atomu
Procedure AddToCanvas(Pic : TCanvas; Colour : TColor; Atm : pAtom); OverLoad;
 Begin
  AddToCanvas(Pic, Colour, Atm^.Typ, Atm^.Layer, Atm^.X, Atm^.Y, Atm^.ToX, Atm^.ToY, Atm^.R, Atm^.Name);
 end;
// - v podobe atomu komponenta - pretocene
Procedure dbDrawToCanvas (Pic : TCanvas; dbA : TAtomDatabase; IsMouse: Boolean; X, Y : Integer);
 var fX, fY, tX, tY, i : Integer;
 Begin
  // Zistenie, ci je Atom existuje
  If dbA<>Nil then // tMetaData;
   Begin
    dbA.First;
    Repeat
     If dbA.cAtom<>Nil Then
      Begin // atom existuje
       // zistenie tMetaData
       if dbA.cAtom^.Typ=255 then
        begin          // hlavicka
         comOffsetX := dbA.cAtom^.ToX;
         comOffsetY := dbA.cAtom^.ToY;
         AddToCanvas (Pic, Color_Normal, tPosHan, tMarker, X, Y, X, Y, 1, '');
        end else begin // data
         // pretocenie v osi X
         If comFlopX Then
          begin
           fX:=comOffsetX - dbA.cAtom^.X;
           tX:=comOffsetX - dbA.cAtom^.ToX;
          end else begin
           fX:=dbA.cAtom^.X - comOffsetX;
           tX:=dbA.cAtom^.ToX - comOffsetX;
          end;
          // pretocenie v osi Y
          If comFlopY Then
           begin
            fY:=comOffsetY - dbA.cAtom^.Y;
            tY:=comOffsetY - dbA.cAtom^.ToY;
           end else begin
            fY:=dbA.cAtom^.Y - comOffsetY;
            tY:=dbA.cAtom^.ToY - comOffsetY;
           end;
          // Otocenie o 90 stupne
          If comRotate Then
           Begin
            i  := fX;  // zmena From
            fX := fY;
            fY := i;
            i  := tX;  // zmena To
            tX := tY;
            tY := i;
           end;
          if isMouse Then AddToCanvas (Pic, Color_Mouse, dbA.cAtom^.Typ, dbA.cAtom^.Layer,
                                       fX+X, fY+Y, tX+X, tY+Y, dbA.cAtom^.R, dbA.cAtom^.Name)
                     Else AddToCanvas (Pic, Color_Normal, dbA.cAtom^.Typ, dbA.cAtom^.Layer,
                                       fX+X, fY+Y, tX+X, tY+Y, dbA.cAtom^.R, dbA.cAtom^.Name)

        end;           // koniec dat
      end;  // atom existuje
    Until (Not dbA.Next);
    // Ukoncenie
   end;
 end;

// Komponent do databazy
Procedure aAppendComponent (dbA : TAtomDatabase; X, Y : Integer);
 var fX, fY, tX, tY, i, grp : Integer;
Begin
  // Zistenie, ci je Atom existuje
  If dbA<>Nil then // tMetaData;
   Begin
    grp := aGetNewGroupIndex;
    dbA.First;
    Repeat
     If dbA.cAtom<>Nil Then
      Begin // atom existuje
       // zistenie tMetaData
       if dbA.cAtom^.Typ=255 then
        begin          // hlavicka
         comOffsetX := dbA.cAtom^.ToX;
         comOffsetY := dbA.cAtom^.ToY;
         aAppend( tPosHan, tMarker, X, Y, X, Y, 1, grp, 'Uchop');
        end else begin // data
         // pretocenie v osi X
         If comFlopX Then
          begin
           fX:=comOffsetX - dbA.cAtom^.X;
           tX:=comOffsetX - dbA.cAtom^.ToX;
          end else begin
           fX:=dbA.cAtom^.X - comOffsetX;
           tX:=dbA.cAtom^.ToX - comOffsetX;
          end;
          // pretocenie v osi Y
          If comFlopY Then
           begin
            fY:=comOffsetY - dbA.cAtom^.Y;
            tY:=comOffsetY - dbA.cAtom^.ToY;
           end else begin
            fY:=dbA.cAtom^.Y - comOffsetY;
            tY:=dbA.cAtom^.ToY - comOffsetY;
           end;
          // Otocenie o 90 stupne
          If comRotate Then
           Begin
            i  := fX;  // zmena From
            fX := fY;
            fY := i;
            i  := tX;  // zmena To
            tX := tY;
            tY := i;
           end;
          aAppend( dbA.cAtom^.Typ, dbA.cAtom^.Layer, fX+X, fY+Y, tX+X, tY+Y, dbA.cAtom^.R, grp, dbA.cAtom^.Name);
        end;           // koniec dat
      end;  // atom existuje
    Until (Not dbA.Next);
    // Ukoncenie
   end;
 end;


// Vykreslenie do cansvas
Procedure DrawToBitmap;
 var Colour : TColor;
 Begin
  //MyBitmap.BeginUpdate(False);
  // najprv vsetky vrstvy korem popisu a uchytu
  aFirst;
  Repeat
   if Atom<>Nil Then
    Begin   // Atom existuje
     if (Atom^.Layer<>tMarker) and (Atom^.Typ<>tPosHan) Then
      begin
       if cncView Then
        Begin
         Colour := Color_Shadow;                      // Predvoleny normalny rezim
         If Atom^.Select Then Colour := Color_Normal; // Farba vybranej polozky
         If Atom^.Lighed Then Colour := Color_Light;  // Farba zvyraznenej polozky
        end else begin
         Colour := Color_Normal;                      // Predvoleny normalny rezim
         If Atom^.Select Then Colour := Color_Select; // Farba vybranej polozky
         If Atom^.Lighed Then Colour := Color_Light;  // Farba zvyraznenej polozky
        end;
       AddToCanvas(MyBitmap.Canvas, Colour, Atom);  // vloz grafiku
     end;
    End;    // atom existuje
  Until (Not aNext);
  // potom popis a uchyt
  aFirst;
  Repeat
   if Atom<>Nil Then
    Begin   // Atom existuje
     if (Atom^.Layer=tMarker) or (Atom^.Typ=tPosHan) Then
      begin // vrstva marker a popis
       if cncView Then
        Begin
         Colour := Color_Shadow;                      // Predvoleny normalny rezim
         If Atom^.Select Then Colour := Color_Normal; // Farba vybranej polozky
         If Atom^.Lighed Then Colour := Color_Light;  // Farba zvyraznenej polozky
        end else begin
         Colour := Color_Normal;                      // Predvoleny normalny rezim
         If Atom^.Select Then Colour := Color_Select; // Farba vybranej polozky
         If Atom^.Lighed Then Colour := Color_Light;  // Farba zvyraznenej polozky
        end;
       AddToCanvas(MyBitmap.Canvas, Colour, Atom);  // vloz grafiku
     end; // pre vrstvu marker
    End;    // atom existuje
  Until (Not aNext);
  //MyBitmap.EndUpdate(False);
 end;

// Vykreslenie do cansvas
Procedure DrawToBitmapAndSaveTo ( FileName : String; aCut, aContour, aCopper, aBackCp, aMarker : Boolean);
 var BMP : TBitmap;
 Begin
  // Nastavenie bitmapy
  BMP := TBitmap.Create;
  BMP.SetSize(iNumToPix(iWidth)+1,
                   iNumToPix(iHeight)+1);
  BMP.Canvas.Brush.Style  :=bsClear;
  BMP.Canvas.Pen.Color    :=clWhite;
  BMP.Canvas.Brush.Color  :=clWhite;
  BMP.Canvas.FillRect(0, 0, MyBitmap.Width, MyBitmap.Height);
  BMP.Canvas.Pen.Color    :=clBlack;
  BMP.Canvas.Pen.Width    :=1;
  // Vykreslenie
  aFirst;
  Repeat
   if Atom<>Nil Then
    Begin   // Atom existuje
     If  ((Atom^.Layer = tCut    ) and (aCut     = True))
      or ((Atom^.Layer = tContour) and (aContour = True))
      or ((Atom^.Layer = tCopper ) and (aCopper  = True))
      or ((Atom^.Layer = tBackCp ) and (aBackCp  = True))
      or ((Atom^.Layer = tMarker ) and (aMarker  = True)) Then
       Begin
        If Atom^.Typ<>tPosHan Then AddToCanvas(BMP.Canvas, clBlack, Atom);  // vloz grafiku
       end;
    End;    // atom existuje
  Until (Not aNext);
  // Ulozit
  BMP.SaveToFile(FileName);
  BMP.Free;
 end;

end.



