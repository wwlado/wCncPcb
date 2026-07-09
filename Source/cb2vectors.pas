unit cb2Vectors;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

Type TwVector = Class(TObject)
   // Premenne suradnice
   Xb, Yb, Zb : Integer;      // suradnice bazoveho bodu
   X1, Y1, Z1 : Integer;      // suradnice prveho vektora
   X2, Y2, Z2 : Integer;      // suradnice druheho vektora
   Xu, Yu, Zu : Integer;      // suradnice Vektora U - B->1
   Xv, Yv, Zv : Integer;      // suradnice Vektoar V - B->2
   Xw, Yw, Zw : Integer;      // suradnice normaloveho vektora
   // Status
   VaildData  : Boolean;      // data su platne
   // Procedury
   Constructor Create; Overload;
   //  Constructor Create ( X, Y, BaseZ, xOsZ, yOsZ : Integer; FromXY : Boolean); Overload;
    //  - X, Y - velkost plochy X a Y
    //  - BaseZ - vyska pri bazi (FromXY=False -> Baza[0,0]; FromXY=True -> Baza[x,y])
    //  - xOsZ, yOsZ - vyska bodov [x,0] a [0,y]
   Constructor Create ( X, Y, BaseZ, xOsZ, yOsZ : Integer; FromXY : Boolean); Overload;
   Destructor  Free;
   // Nastavenie bodov
   Procedure PointBase (X, Y, Z : Integer);
   Procedure PointOsX  (X, Y, Z : Integer);
   Procedure PointOsY  (X, Y, Z : Integer);
   // Vypocet
   Procedure MakeVector;
   Function  GetZ (X, Y : Integer) : Integer;
   Procedure GetVector ( Var X, Y, Z : Integer );
   //
 End;


// Procedury
// -- vektor;
 Procedure wvReset;
 //Procedure wvSet ( X, Y, ZBegin, ZOsX, ZOsY, ZEnd : Integer);
 //Function wvGetZ ( X, Y : Integer ) : Integer;
 Function wvIsVaild : boolean;
 Function wvGetOutA : Integer;
 Function wvGetOutB : Integer;
 Function wvGetOutC : Integer;
 Function wvGetOutD : Integer;
// -- cez sumu
 Function wvsMathZ (X, Y, MaxX, MaxY, Z00, ZX0, Z0Y, ZXY : Integer) : Integer;
 Procedure wvsSet ( X, Y, ZBegin, ZOsX, ZOsY, ZEnd : Integer);
 Procedure wvsPutZ ( PointX, PointY, Z : Integer);
 Procedure wvsBegin ( Xmax, Ymax, Xstep, Ystep, Z00 : Integer);
 Procedure wvsEndOfRead;
 Function wvsGetZ ( X, Y : Integer ) : Integer;

implementation

 // Premenne kniznice
 Var vIsVaild, vSimple  : Boolean;      // Platne data, jednoduchy model
     aX, aY, aZ, aOut   : Integer;      // sady normalizovanych vektorov
     bX, bY, bZ, bOut   : Integer;
     cX, cY, cZ, cOut   : Integer;
     dX, dY, dZ, dOut   : Integer;
     X_Max , Y_Max      : Integer;      // celkovy rozmer
     X_Step, Y_Step     : Integer;      // krokovanie
     X_MLd , Y_MLd      : Integer;      // Maximalne Nacitanych
     MemZ               : Array [0..99, 0..99] of integer;


// Procedury interne ------------------------------------------------------- RTL
// - Nastavenie parametrov a vypocet normalovych vektorov
Procedure wvSet ( X, Y, ZBegin, ZOsX, ZOsY, ZEnd : Integer);
 var vec : TwVector;
  Begin
   // Inicializacia
   vec := TwVector.Create;
   // sada A - [0,0]
   vec.PointBase(0, 0, ZBegin);
   vec.PointOsX (X, 0, ZOsX);
   vec.PointOsY (0, Y, ZOsY);
   vec.MakeVector;
   vec.GetVector(aX, aY, aZ);
   // sada B - [x,0]
   vec.PointBase(X, 0, ZOsX);
   vec.PointOsX (X, Y, ZEnd);
   vec.PointOsY (0, 0, ZBegin);
   vec.MakeVector;
   Vec.GetVector(bX, bY, bZ);
   // sada C - [x,Y]
   vec.PointBase(X, Y, ZEnd);
   vec.PointOsX (0, Y, ZOsY);
   vec.PointOsY (X, 0, ZOsX);
   vec.MakeVector;
   Vec.GetVector(cX, cY, cZ);
   // sada D - [0,Y]
   vec.PointBase(0, Y, ZOsY);
   vec.PointOsX (0, 0, ZBegin);
   vec.PointOsY (X, Y, ZEnd);
   vec.MakeVector;
   Vec.GetVector(dX, dY, dZ);
   // Zistenie validnych dat
   vIsVaild := (aZ <> 0) and (bZ <> 0) and (cZ <> 0) and (dZ<>0);
   // Koniec
   vec.Free;
  end;

// - Komplexne prepocitanie
Function wvGetZ ( X, Y : Integer ) : Integer;
 Begin
  // Zistenie validity
  vIsVaild := (aZ <> 0) and (bZ <> 0) and (cZ <> 0) and (dZ<>0);
  Result   := 0;
  if vIsVaild Then
   Begin
    // Vypocty vystupnych Z
    aOut := ((aX*X) + (aY*Y)) div (-1*aZ);
    bOut := ((bX*X) + (bY*Y)) div (-1*bZ);
    cOut := ((cX*X) + (cY*Y)) div (-1*cZ);
    dOut := ((dX*X) + (dY*Y)) div (-1*dZ);
    // priemer
    Result:= (aOut + bOut + cOut + dOut) div 4;
   end;
 end;

// - Funkcia validity
Function wvIsVaild : boolean;
  begin
   Result := vIsVaild;
  end;
// - reset
Procedure wvReset;
 begin
  vIsVaild := False;
  vSimple  := True;
  aOut := 0;
  bOut := 0;
  cOut := 0;
  dOut := 0;
 end;

// - jednotlive vysledky po prepocte
Function wvGetOutA : Integer;
 Begin
  Result := aOut;
 end;
Function wvGetOutB : Integer;
 Begin
  Result := bOut;
 end;
Function wvGetOutC : Integer;
 Begin
  Result := cOut;
 end;
Function wvGetOutD : Integer;
 Begin
  Result := dOut;
 end;

// ---------------------------------------------------------------------- Objekt
// Konstruktor
 // - Jednoduchy
 Constructor TwVector.Create; Overload;
  Begin
   // Platne data
   VaildData := False;
  End;
 // - Uz s parametrami
 Constructor TwVector.Create ( X, Y, BaseZ, xOsZ, yOsZ : Integer; FromXY : Boolean); Overload;
  Begin
   // Baza
   if FromXY then
    begin          // Vektor zacina z bodu [X,Y]
      Xb := X;
      Yb := Y;
    end else begin // Vektor zacina z bodu [0,0]
     Xb := 0;
     Yb := 0;
    end;
   Zb := BaseZ;
   // bod 1
   X1 := X;
   Y1 := 0;
   Z1 := xOsZ;
   // bod 2
   X2 := 0;
   Y2 := Y;
   Z2 := yOsZ;
  // Platne data
   VaildData := False;
  // Vytvorit vektor
   MakeVector;
  End;
// Destruktor
 Destructor TwVector.Free;
  Begin
    //
  End;

// Nastavenia vektorov
 // Bazovy bod
 Procedure TwVector.PointBase (X, Y, Z : Integer);
  Begin
   Xb := X;
   Yb := Y;
   Zb := Z;
  end;
 // Bod na osy X
 Procedure TwVector.PointOsX (X, Y, Z : Integer);
  Begin
   X1 := X;
   Y1 := Y;
   Z1 := Z;
  end;
 // Bod na osy Y
 Procedure TwVector.PointOsY (X, Y, Z : Integer);
  Begin
   X2 := X;
   Y2 := Y;
   Z2 := Z;
  end;

// Vypocet normaloveho vektora
 Procedure TwVector.MakeVector;
  Begin
   // Vypocet vektora U
   Xu := Xb - X1;
   Yu := Yb - Y1;
   Zu := Zb - Z1;
   // Vypocet vektora V
   Xv := Xb - X2;
   Yv := Yb - Y2;
   Zv := Zb - Z2;
   // Vypocet normaloveho vektora
   Xw := (Yu*Zv) - (Zu*Yv);
   Yw := (Zu*Xv) - (Xu*Zv);
   Zw := (Xu*Yv) - (Yu*Xv);
   // platne data
   VaildData := (Zw <> 0);
  end;

// Vypocet suradnici Z podla suradnice XY
 Function TwVector.GetZ ( X, Y : Integer) : Integer;
  begin
   // platne data
   VaildData := (Zw <> 0);
   Result    := 0;
   if VaildData Then Result := ((Xw*X) + (Yw*Y)) div (-1*Zw);
  end;

// Export normaloveho vektora
 Procedure TwVector.GetVector ( Var X, Y, Z : Integer );
  Begin
   X := Xw;
   Y := Yw;
   Z := Zw;
  end;

// --- Pomerom ------------------------------------------------------- pomer ---
Function wvsMathZ (X, Y, MaxX, MaxY, Z00, ZX0, Z0Y, ZXY : Integer) : Integer;
Var A, B, C, D : int64;
 Begin
  A := (Z00*(MaxX-X)*(MaxY-Y)) Div (MaxX * MaxY);
  B := (ZX0*(     X)*(MaxY-Y)) Div (MaxX * MaxY);
  C := (Z0Y*(MaxX-X)*(     Y)) Div (MaxX * MaxY);
  D := (ZXY*(     X)*(     Y)) Div (MaxX * MaxY);
  Result := A+B+C+D;
 end;

// - Nastavenie parametrov pomocov pomeru
Procedure wvsSet ( X, Y, ZBegin, ZOsX, ZOsY, ZEnd : Integer);
 Begin
  MemZ[0,0] := ZBegin;
  MemZ[1,0] := ZOsX;
  MemZ[0,1] := ZOsY;
  MemZ[1,1] := ZEnd;
  X_Max     := X;
  Y_Max     := Y;
  vSimple   := True;
  vIsVaild  := True;
 end;

// - Nastavenie parametrov Z
Procedure wvsPutZ ( PointX, PointY, Z : Integer);
 Begin
  If PointX>99 Then
   Begin
    vIsVaild:=False;
    PointX:=99;
   end;
  If PointY>99 Then
   Begin
    vIsVaild:=False;
    PointY:=99;
   end;
  MemZ[PointX,PointY] := Z;
  If X_MLd<PointX Then X_MLd:=PointX;
  If Y_MLd<PointY Then Y_MLd:=PointY;
 end;
// - Inicializacia Maximalnych parametrov
Procedure wvsBegin ( Xmax, Ymax, Xstep, Ystep, Z00 : Integer);
 Begin
  X_MLd:=0;
  Y_MLd:=0;
  X_Max     := Xmax;
  Y_Max     := Ymax;
  X_Step    := Xstep;
  Y_Step    := Ystep;
  MemZ[0,0] := Z00;
  vSimple   := False;
  vIsVaild  := False;
 end;
// - Ukoncenie nacitania
Procedure wvsEndOfRead;
Var i, j, k : Integer;
 Begin
  k:=MemZ[0,0];
  For i:=0 To X_MLd do
  For j:=0 To Y_MLd do
   MemZ[i,j]:=MemZ[i,j]-k;
  vSimple   := False;
  vIsVaild  := (X_MLd>0) and (Y_MLd>0);
 end;

// - Komplexne prepocitanie
Function wvsGetZ ( X, Y : Integer ) : Integer;
var myX, myY : Integer;
    pXa ,pYa : Integer;
    pXb ,pYb : Integer;
 Begin
  if vSimple Then
   Begin          // Jednoduchy vypocet
    Result:=wvsMathZ( X, Y, X_Max, Y_Max, MemZ[0,0], MemZ[1,0], MemZ[0,1], MemZ[1,1]);
   end else Begin // Zlozeny vypocet
    MyX := X mod X_Step;
    MyY := Y mod Y_Step;
    pXa := X div X_Step;
    pYa := Y div Y_Step;
    if pXa>X_MLd Then pXa:=X_MLd;
    if pYa>Y_MLd Then pYa:=Y_MLd;
    pXb := pXa + 1;
    pYb := pYa + 1;
    if pXb>X_MLd Then pXb:=X_MLd;
    if pYb>Y_MLd Then pYb:=Y_MLd;
    Result:=wvsMathZ( MyX, MyY, X_Step, Y_Step, MemZ[pXa,pYa], MemZ[pXb,pYa], MemZ[pXa,pYb], MemZ[pXb,pYb]);
   end;           // Koniec vypoctu
 end;


end.


