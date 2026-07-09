unit cb2Atom;
//
// Kniznica na obsluhu databazy tvorich z Atomov
//
// Visnovsky 28.11.2024
//

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

// Struktura atomu
Type
  pAtom = ^tAtom;
  tAtom = Record
   Next:  pAtom;            // Dalsi atom
   Index: Integer;          // Index
   Group: Integer;          // Index komponentu
   Typ:   Byte;             // Typ nastroja
   Layer:  Byte;            // Vrstva
   X:     Integer;          // Pozicia X  - Od
   Y:     Integer;          // Pozicia Y  - Od
   ToX:   Integer;          // Pozicia X  - Do
   ToY:   Integer;          // Pozicia Y  - Do
   R:     Integer;          // Polomer
   Name:  String[50];       // Meno nastroja, text
   Select:Boolean;          // Oznacene
   Lighed:Boolean;          // Zvyraznenie
   //Color: Byte;           // Farba
   //Pen:   Byte;           // Hrubka
  end;

// Vo forme objektu
Type TAtomDatabase = Class( TObject )
   cAtom: pAtom;   // Current - Momentale nastaveny
   bAtom: pAtom;   // Base    - Bazovy Atom
   Constructor Create;
   Destructor  Free;
   // - Pridat
   Function    Append (Typ, Layer: Byte; X,Y,ToX,ToY,R,G : Integer; Name: String ) : pAtom;
   // - Hladanie
   Function    SearchByIndex (Index : Integer) : Boolean;
   Function    SearchByName (Name : String) : Boolean;
   Function    SearchByOrder (Index : Integer) : Boolean;
   Function    SearchByLayer (sLayer : Integer) : Boolean;
   Function    SearchByType  (sType : Integer) : Boolean;
   // - Mazanie atomu
   Function    DeleteByIndex (Index : Integer) : Boolean;
   Function    DeleteChecked : Boolean;
   Procedure   AllDelete;
   // - Hladanie po jednom
   Procedure   First;
   Function    Next : Boolean;
   //
  Private
   // Premenne
   aa, cc : pAtom;
   Count  : Integer;
  End;

Const asNone    = 0;
      asPoint   = 1;
      asWay     = 2;

// publikovane premenne
Var
 Atom   : pAtom;
 aBase  : pAtom;                            // Baza databazy
 asWays          : Integer;                 // Funkcia hladania - Oznacenych ciest
 asPoints        : Integer;                 // Funkcia hladania - Oznacenych bodov
 asNewGroupIndex : Integer;                 // Funkcia hladania - Nove cislo Group

// Publikovane Funkcie
// - Inicializacia
Procedure AtomSystemInit;
Procedure AtomFree;
// - Vlozit novy atom
Function aAppend (Typ, Layer: Byte; X,Y,ToX,ToY,R,G : Integer; Name: String ) : pAtom;
Function aInsertNewCopy (aOld: pAtom) : pAtom;
// - Hladanie atomu
Function aSearchByIndex (Index : Integer) : Boolean;
Function aSearchByName (Name : String) : Boolean;
Function aSearchByOrder (Index : Integer) : Boolean;
Function aSearchBySelected : Boolean;
//Function IsComponentInAtomAt (X, Y : Integer; ToDo : Boolean) : Boolean;
Procedure aReMoveComponentInAtom (FromX, FromY, ToX, ToY : Integer; Command : Integer);
// - aSearchComponentInAtom ..-> Result: asPoint, asWay
// X,Y - poloha, Flag: OnlyOne - po jednom, MultiSelect - oznacovanie, Checked - Dovolit hned oznacit,
// enableGroup - povolit oznacenie celeho komponentu, OnlyCompPosHan - oznacenie komponentu iba PositionHandlerom,
// lEnCopper/back - Hladanie vo vrstve medi, lEnMarker - oznacenie vo vrstve popisovania
Function  aSearchComponentInAtom (X, Y : Integer; OnlyOne, MultiSelect, Checked, EnableGroup, OnlyCompPosHan, lEnCopper, lEnBack, lEnMarker : Boolean) : Byte;
Function  aSelectInRage (x1, y1, x2, y2 : Integer; Select, AllChange : Boolean) : Boolean;
Procedure aSelectGroup (GroupIndex: Integer; Selected: Boolean); overload;
Procedure aSelectGroup (gAtom : pAtom); overload;
Function  aGetNewGroupIndex : Integer;
Function  aSelectAllAtom (Selected: Boolean) : Boolean;
Procedure aSelectIsNewGroup;
Procedure aUnGroup (GroupNum: integer);
// - optimalizacia atomov
Procedure aOptimalizeWay;
Procedure aOptimalizeHole;
// - otocit a presunut komponent
Procedure aRotateSelected(OsX, osY : Integer; Flop : boolean);
Procedure aMoveAllAtom (offsetX, offsetY : Integer);
// - Mazanie atomu
Function aDeleteByIndex (Index : Integer) : Boolean;
Function aDeleteGroup (Group : Integer) : Boolean;
Function aDeleteChecked : Boolean;
Procedure aAllDelete;
// - Hladanie po jednom
Procedure aFirst; overload;             // Prvy - zaciatok   aFirst; Repeat
Function  aNext : Boolean; overload;    // ak existuje dalsi Until Not aNext
Function  aEnd : Boolean; overload;     // ak je posledny    Until aEnd
Procedure aFirst (var a : pAtom); overload;
Function  aNext (var a : pAtom) : Boolean;  overload;
Function  aEnd (var a : pAtom) : Boolean;  overload;
// zaloha databazy
Function aGoFoward : Boolean;
Function aGoBack : Boolean;
Procedure aPush;
Procedure aCopy( Var ToBase, FromBase : pAtom );

{Procedury pre buducnost}
// Procedure TMyForm.SaveSettings;



implementation
Uses  cb2Graphics;

Const aBaseMax = 99;

Var c, a : pAtom;
    aCounter: Integer;                    // pocitadlo
    aBases : Array [0..99] of pAtom;      // rukovet pre tlacidlo spat
    aBaseIndex : Integer;                 // Index rukovete
    aBaseLast  : Integer;
    ooIndex    : Integer;                 // Index oznacenia iba jedneho
    //i : Integer;

// Inicializacia
Procedure AtomSystemInit;
 Var i : Integer;
 begin
   aBase      := Nil;
   aBaseIndex := 0;
   aBaseLast  := 0;
   c          := Nil;
   aCounter   := 0;
   For i:=0 to aBaseMax do aBases[i] := Nil;
  end;
// Ukonci
Procedure AtomFree;
 Var i : Integer;
begin
  For i:=0 to aBaseMax do
   begin
    if aBases[i] <> Nil Then
     Begin
      aBase := aBases[i];
      aAllDelete;
     end;
    // koniec cyklu
   end;
end;

// novy
Function aAppend (Typ, Layer: Byte; X, Y, ToX, ToY, R, G : Integer; Name: String ) : pAtom;
//Var i : Integer;
 begin
  New(a);
  If a<>Nil Then
   begin
    // podarilo sa vytvorit atom
    c := aBase;
    if c=Nil then
     Begin
      c:=a;
      aBase:=a;
      //aBases[aBaseIndex] := aBase;
     end else Begin
       While c^.Next<>nil do
        begin
         c:=c^.Next;
        end;
       c^.Next:=a;
     end;
    // nasavenie
    Result:=a;
    a^.Next:=Nil;
    Atom:=a;
    a^.Layer:=Layer;
    a^.ToX:=ToX;
    a^.ToY:=ToY;
    a^.Group:=G;
    a^.Name:=Name;
    a^.R:=R;
    a^.Typ:=Typ;
    a^.X:=X;
    a^.Y:=Y;
    a^.Index:=aCounter;
    a^.Select:=False;
    a^.Lighed:=False;
    Inc(aCounter);
    // koniec vytvorenia
   end else Halt(1);
 end;

// Vlozit novu kopiu atomu
// - vytvory kopiu atomu a vlozi ho za atom
Function aInsertNewCopy (aOld: pAtom) : pAtom;
 Var a : pAtom;
 Begin
  if aOld<>Nil Then
   Begin
    New(a);
    If a=Nil Then Halt(1);
    a^.Next:=aOld^.Next;
    aOld^.Next:=a;
    // kopirovanie
    a^.X:=aOld^.X;
    a^.Y:=aOld^.Y;
    a^.ToX:=aOld^.ToX;
    a^.ToY:=aOld^.ToY;
    a^.R:=aOld^.R;
    a^.Group   :=aOld^.Group;
    a^.Index   :=aOld^.Index;
    a^.Layer   :=aOld^.Layer;
    a^.Lighed  :=aOld^.Lighed;
    a^.Select  :=aOld^.Select;
    a^.Name    :=aOld^.Name;
    a^.Typ     :=aOld^.Typ;
    Result:=a;
   end;
 End;

// Hladanie
// - podla indexu
Function aSearchByIndex (Index : Integer) : Boolean;
 Begin
  Result:=False;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
      If c^.Index=Index Then
       Begin // najdeny
        Atom:=c;
        Result:=True;
       End;
      c:=c^.Next;
    until c=Nil;
   end;
 end;
// - podla Mena
Function aSearchByName (Name : String) : Boolean;
 Begin
  Result:=False;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
      If c^.Name=Name Then
       Begin // najdeny
        Atom:=c;
        Result:=True;
       End;
      c:=c^.Next;
    until c=Nil;
   end;
 end;
// - podla poradia
Function aSearchByOrder (Index : Integer) : Boolean;
 Var i : Integer;
 Begin
  Result:=False;
  i:=0;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
      If i=Index Then
       Begin // najdeny
        Atom:=c;
        Result:=True;
       End;
      inc(i);
      c:=c^.Next;
    until c=Nil;
   end;
 end;
// - podla oznacenych
Function aSearchBySelected : Boolean;
 Var i : Integer;
 Begin
  Result:=False;
  i:=0;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
      If c^.Select Then
       Begin // najdeny
        Atom:=c;
        Result:=True;
       End;
      inc(i);
      c:=c^.Next;
    until c=Nil;
   end;
 end;

// - Hladane a prepisanie podla pozicie
Function  aSearchComponentInAtom (X, Y : Integer; OnlyOne, MultiSelect, Checked, EnableGroup, OnlyCompPosHan, lEnCopper, lEnBack, lEnMarker : Boolean) : Byte;
 Var minX, maxX, minY, maxY, whoY, grp : Integer;
     rAtom : Real;
     grpSel: Boolean;
       Cnt : Integer;
       //pnt : Boolean; // point

 // Podprocedura na oznacenie komponentu
 Function DoResult (MyResult : Byte) : Byte;
  begin
   Result:=asNone;
   if ((c^.Layer=tCopper) and lEnCopper) or (c^.Layer=tCut)     or
      ((c^.Layer=tBackCp) and lEnBack)   or (c^.Layer=tContour) or
      ((c^.Layer=tMarker) and lEnMarker) or (c^.Layer=tPosHan)  Then
    Begin
     if (c^.Group=0) or (not OnlyCompPosHan) or (c^.Typ=tPosHan) Then
      Begin
       Result:=MyResult;
       grp:=c^.Group;
       if MyResult=asPoint Then  inc(asPoints);
       if MyResult=asWay   Then  inc(asWays);
       If Checked and (not MultiSelect) Then c^.Select:=True;
       If Checked and MultiSelect Then c^.Select:= (not c^.Select);
       grpSel := c^.Select;
      end;
    end;
  end;

// Zaciatok procedury
 Begin
  cnt      := 0;
  grp      := 0;
  grpSel   := False;
  asWays   := 0;
  asPoints := 0;
  Result   := asNone;
  if (not MultiSelect) and Checked Then aSelectAllAtom(False);
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
      //pnt:=True;
      // klasicke hladnie - Hladanie prveho parametra
      If (c^.X=X) and (C^.Y=Y) Then
       Begin // najdeny
        if asNone <> DoResult(asPoint) Then Result := asPoint;
       End;
      // klasicke hladnie - Hladanie Druheho parametra
       If (c^.ToX=X) and (C^.ToY=Y) and (X>0) and (Y>0) Then
        Begin // najdeny
         if asNone <> DoResult(asPoint) Then Result := asPoint;
        End;
       c:=c^.Next;
     until (c=Nil); // or ((OnlyOne = True) And (Result <> asNone));
     // Hladnanie pri ceste stedu
     c:=aBase;
     Repeat
     If  (Result = asNone) and (C^.Typ = tWay) Then    // (Result = asNone) and
      Begin
       // Hladanie Od-Do
       // Rozlozenie Nacitanie XY
       if C^.X > C^.ToX Then
        Begin
         maxX:=c^.X;
         minX:=C^.ToX;
        end else begin
         minX:=c^.X;
         maxX:=C^.ToX;
        end;
       if C^.Y > C^.ToY Then
        Begin
         maxY:=c^.Y;
         minY:=C^.ToY;
        end else begin
         minY:=c^.Y;
         maxY:=C^.ToY;
        end;
        if (MaxX<>MinX) and (MinY<>MaxY) Then
         Begin
          rAtom := (MaxX - MinX) / (MaxY - MinY);
          whoY  := Trunc((X-MinX) / rAtom) + MinY;
         end else whoY:=Y;
      // Hladanie v rozmedzi
       If (PosCursorStep(Y)=PosCursorStep(whoY)) and
          ((maxX >= X) and (minX <= X)) and
          ((maxY >= Y) and (minY <= Y)) Then
        Begin
         Result := DoResult(asWay);
        end;
      End;
     // only one
     if OnlyOne And c^.Select and (not MultiSelect) and Checked Then
      Begin
       if cnt<>ooIndex Then
        begin
         C^.Select:=False;
         if grp=c^.Group Then grp:=0;
        end;
       Cnt:=Cnt+1;
      End;
     // Light
     c:=c^.Next;
   until (c=Nil); // or ((OnlyOne = True) And (Result <> asNone));
   // only one
   if OnlyOne and Checked Then
    Begin
     Inc(ooIndex);
     if ooIndex>Cnt Then ooIndex:=0;
    End;
   // Uplne ukoncenie pre group
    If Checked and EnableGroup Then
     Begin
      if grp>0 Then aSelectGroup(grp, grpSel);
     end;
  end;
 end;
// premiestnenie atomu
Procedure aReMoveComponentInAtom (FromX, FromY, ToX, ToY : Integer; Command : Integer);
Begin   // Vukonanie
 if aBase<>Nil Then
    Begin // existuje atom
     c:=aBase;
     Repeat
       // klasicke hladnie - Hladanie prveho parametra
       If (Command = asPoint) And (c^.Select = True) And
          ((c^.X=FromX) and (C^.Y=FromY)) and (C^.Group=0) Then
        Begin // najdeny
         C^.X := ToX;
         C^.Y := ToY;
        End;
       // klasicke hladnie - Hladanie Druheho parametra
       If (Command = asPoint) And (c^.Select = True) And
          (c^.ToX=FromX) and (C^.ToY=FromY) and (C^.Group=0) Then
        Begin // najdeny
         C^.ToX := ToX;
         C^.ToY := ToY;
        End;
      // Hladnanie pri ceste stedu
      If ((Command = asWay) or (C^.Group>0)) And (c^.Select = True) Then
       Begin
        C^.X   := C^.X   + (ToX - FromX);
        C^.ToX := C^.ToX + (ToX - FromX);
        C^.Y   := C^.Y   + (ToY - FromY);
        C^.ToY := C^.ToY + (ToY - FromY);
       End;
      // Light
      c:=c^.Next;
    until (c=Nil);
  end;
end;

// -- Oznac atomy v sekcii
Function aSelectInRage (x1, y1, x2, y2 : Integer; Select, AllChange : Boolean) : Boolean;
 var ax, ay, bx, by : Integer;
 Begin
  Result:=False;
  if x1<x2 Then
   Begin
    ax:=x1;
    bx:=x2;
   end else begin
    ax:=x2;
    bx:=x1;
   end;
  if y1<y2 Then
   Begin
    ay:=y1;
    by:=y2;
   end else begin
    ay:=y2;
    by:=y1;
   end;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
     if AllChange Then c^.Select:=Not Select;
      If ((c^.Typ=tWay) and (c^.ToX>=ax) and (c^.ToY>=ay) and (c^.ToX<=bx) and (c^.ToY<=by)) or
         ((c^.X>=ax) and (c^.Y>=ay) and (c^.X<=bx) and (c^.Y<=by)) Then
       Begin // najdeny
        c^.Select:=Select;
        Result:=True;
       End;
      c:=c^.Next;
    until c=Nil;
   end;
 end;

// Zmena oznacenia groupu
Procedure aSelectGroup (GroupIndex: Integer; Selected: Boolean); overload;
begin
 if aBase<>Nil Then
  Begin // existuje atom
   a:=aBase;
   if GroupIndex>0 Then
    Repeat
      if a^.Group=GroupIndex Then a^.Select:=Selected;
      a:=a^.Next;
    until (a=Nil);
  end;
end;
// Oznac vsetky atomy jedneho groupu podla daneho atomu
Procedure aSelectGroup (gAtom : pAtom); overload;
begin
 if (aBase<>Nil) and (gAtom<>Nil) Then
  Begin // existuje atom
   a:=aBase;
   if gAtom^.Group>0 Then
    Repeat
      if a^.Group=gAtom^.Group Then a^.Select:=gAtom^.Select;
      a:=a^.Next;
    until (a=Nil);
  end;
end;
// Najdenie volneho indexu group
Function aGetNewGroupIndex : Integer;
 begin
  Result := 1;
  if aBase<>Nil Then
   Begin // existuje atom
    a:=aBase;
     Repeat
       if a^.Group=Result Then
        Begin
         Inc(Result);
         a:=aBase;
        end else a:=a^.Next;
     until (a=Nil);
   end;
  asNewGroupIndex := Result;
 end;
// Oznac/odznac vsetky - vybrane
Function aSelectAllAtom (Selected: Boolean): Boolean;
begin
 Result:=False;
 if aBase<>Nil Then
  Begin // existuje atom
   a:=aBase;
    Repeat
      if a^.Select<>Selected Then Result:=True;
      a^.Select:=Selected;
      a:=a^.Next;
    until (a=Nil);
  end;
end;
// Zlul oznacene do komponentu - group
Procedure aSelectIsNewGroup;
begin
 if aBase<>Nil Then
  Begin // existuje atom
   aGetNewGroupIndex;
   a:=aBase;
    Repeat
      if a^.Select=True Then a^.Group:=asNewGroupIndex;
      a:=a^.Next;
    until (a=Nil);
  end;
end;
// Rozdel Group
Procedure aUnGroup (GroupNum: integer);
begin
 if aBase<>Nil Then
  Begin // existuje atom
   aGetNewGroupIndex;
   a:=aBase;
    Repeat
      if a^.Group=GroupNum Then a^.Group:=0;
      a:=a^.Next;
    until (a=Nil);
  end;
end;

// - Presun vsetkych atomov
Procedure aMoveAllAtom (offsetX, offsetY : Integer);
Begin   // Vukonanie
 if aBase<>Nil Then
    Begin // existuje atom
     c:=aBase;
     Repeat
      // Hladnanie pri ceste stedu
        C^.X   := C^.X   + offsetX;
        C^.ToX := C^.ToX + offsetX;
        C^.Y   := C^.Y   + offsetY;
        C^.ToY := C^.ToY + offsetY;
      // Light
      c:=c^.Next;
    until (c=Nil);
  end;
end;

// Optimalizacia ciest - databazy
Procedure aOptimalizeWay;
var c, a, b  : pAtom;
       d     : Boolean;
    i, l     : Integer;

 // Funkcia zistenia ci su obe pointery cesty a rovnakej vrstvy mede
 Function isWayOnLayer (a1, a2 : pAtom) : Boolean; overload;
  Begin
   Result:=False;
   If (a1<>Nil) and (a2<>nil) Then
    Begin // obe jestvuju
     if (a1^.Typ=tWay) and (a2^.Typ=tWay) and (a1^.Layer=a2^.Layer) and
       ((a1^.Layer=tCopper) or (a1^.Layer=tBackCp)) Then Result:=True;
    end;  // obe jestvuju
  end;

 // Funkcia zistenia ci su obe pointery cesty a rovnakej vrstvy mede
 Function isWayOnLayer (a1 : pAtom) : Boolean; overload;
  Begin
   Result:=False;
   If (a1<>Nil) Then
    Begin // obe jestvuju
     if (a1^.Typ=tWay) and ((a1^.Layer=tCopper) or (a1^.Layer=tBackCp)) Then Result:=True;
    end;  // obe jestvuju
  end;

 // Funkcia vypoctu vzdialenosti
 Function AbsLength (a1 : pAtom) : Integer;
  Begin
   Result:=Abs(a1^.X - Atom^.ToX) + Abs(a1^.Y - Atom^.ToY);
  end;

// hlavny kod procedury
 Begin
  // Odzancenie vsetkych atomov
  aSelectAllAtom(False);

  // Vyhladanie naveznych atomov
  aFirst;
  Repeat
   if (Atom<>Nil) and isWayOnLayer(Atom, Atom^.Next) Then
    Begin
     if (Atom^.ToX=Atom^.Next^.X) and (Atom^.ToY=Atom^.Next^.Y) Then Atom^.Next^.Select:=True;
    end;
  until aEnd;
  // optimalizacia
  aFirst;
  a:=Atom;
  Repeat
   d:=False; // done - ak sa spravy ukon
   // zistenie existencie atomov
   If isWayOnLayer(Atom) Then
    Begin // atom existuje a je cesta
     // zistenie, ci nasleduje
     If isWayOnLayer(Atom, Atom^.Next) Then
      Begin
       a:=Atom^.Next;
       if (a^.X=Atom^.ToX) and (a^.Y=Atom^.ToY) Then d:=True;
      end;
     // Hladanie najbizsieho bodu
     if (not d) and (Atom^.Next<>Nil) Then;
      Begin // hladanie bodu
       a:=Atom^.Next;
       c:=nil;
       l:=(-1);
       if a<>nil then
        Repeat               // cyklus  - na hladanie nablizsieho bodu
         // Zistenie vzdialenosti
         if isWayOnLayer(a, Atom) Then
          Begin        // ak ide o tu istu cestu
           i:=AbsLength(a);
           if ((i<l) or (l=(-1))) and (Not a^.Select) Then
            Begin
             l:=i;
             c:=a;
            end;
          end;         // ak ide o tu istu cestu
         a:=a^.Next;
        until (a=nil); // cyklus
       // zistenie, ci nenasleduje najblizsi bod
       if (not d) and (c<>Atom^.Next) and (c<>nil) Then
        Begin  // presun atomu
         a:=c;
         Repeat   // hladanie nadviazanych atomov
          b:=a;
          a:=a^.Next;
          d:=True;
          if isWayOnLayer(a, b) Then d:= not ((a^.X=b^.ToX) and (a^.Y=b^.ToY));
         until (a=Nil) or d; // hladanie nadviazanych atomov
         // presun
         // Atom.next <- miesto vlozenia
         // C         <- zaciatok presuvaneho bloku atomov
         // B         <- posledny presuvany atom
         a:=Atom^.Next; //
         if (a<>nil) and (c<>nil) and (b<>nil) then // najdenie napojenia presuvaneho bloku
          Begin
           Repeat
            if a^.Next=c then a^.Next:=b^.Next;  // V mieste vystrihnuteho bloku napoj zbytok atomov
            a:=a^.Next;
           until a=nil;
           b^.Next   := Atom^.Next; // koniec kopirovaneho bloku - predchadzajuci blok
           Atom^.Next:= C;          // pripoj kopirovany blok
          End;
        end;   // presun atomu
      end; // hladanie blizsieho bodu
    end;   // atom existuje a je cesta
   until aEnd;
   // Odzancenie vsetkych atomov
   aSelectAllAtom(False);
 end;
// Optimalizacia dier - databazy
Procedure aOptimalizeHole;
var c, a, b  : pAtom;
       d     : Boolean;
    i, l     : Integer;

 // Funkcia zistenia ci su obe pointery cesty a rovnakej vrstvy mede
 Function isHoleOnLayer (a1, a2 : pAtom) : Boolean; OverLoad;
  Begin
   Result:=False;
   If (a1<>Nil) and (a2<>nil) Then
    Begin // obe jestvuju
     if (a1^.Typ=tHole) and (a2^.Typ=tHole) and (a1^.Layer=a2^.Layer) and
        ((a1^.Layer=tCut) or (a1^.Layer=tContour)) Then Result:=True;
    end;  // obe jestvuju
  end;
 // Funkcia zistenia ci su obe pointery cesty a rovnakej vrstvy mede
 Function isHoleOnLayer (a1 : pAtom) : Boolean; OverLoad;
  Begin
   Result:=False;
   If (a1<>Nil) Then
    Begin // jestvuju
     if (a1^.Typ=tHole) and ((a1^.Layer=tCut) or (a1^.Layer=tContour)) Then Result:=True;
    end;  // jestvuju
  end;

 // Funkcia vypoctu vzdialenosti
 Function AbsLength (a1 : pAtom) : Integer;
  Begin
   Result:=Abs(a1^.X - Atom^.X) + Abs(a1^.Y - Atom^.Y);
  end;

// hlavny kod procedury
 Begin
  // Odzancenie vsetkych atomov
  aSelectAllAtom(False);
  // optimalizacia
  aFirst;
  a:=Atom;
  Repeat
   // zistenie existencie atomov
   If isHoleOnLayer(Atom) Then
    Begin // atom existuje a je cesta
     // Hladanie najbizsieho bodu
     if (Atom^.Next<>Nil) Then;
      Begin // hladanie bodu
       a:=Atom^.Next;
       c:=nil;
       l:=(-1);
       if a<>nil then
        Repeat               // cyklus  - na hladanie nablizsieho bodu
         // Zistenie vzdialenosti
         if isHoleOnLayer(a, Atom) Then
          Begin        // ak ide o tu istu vrstvu
           i:=AbsLength(a);
           if ((i<l) or (l=(-1))) Then
            Begin
             l:=i;
             c:=a;
            end;
          end;         // ak ide o tu istu vrstvu
         a:=a^.Next;
        until (a=nil); // cyklus
       // presun
       // Atom.next <- miesto vlozenia
       // C         <- zaciatok presuvaneho bloku atomov
       a:=Atom^.Next; //
       if (a<>nil) and (c<>nil) and (c<>a) then // najdenie napojenia presuvaneho bloku
        begin //
         Repeat
          if a^.Next=c then a^.Next:=c^.Next;  // V mieste vystrihnuteho bloku napoj zbytok atomov
          a:=a^.Next;
         until a=nil;
         c^.Next   := Atom^.Next; // koniec kopirovaneho bloku - predchadzajuci blok
         Atom^.Next:= C;          // pripoj kopirovany blok
        end;
      end; // hladanie blizsieho bodu
    end;   // atom existuje a je cesta
   until aEnd;
   // Odzancenie vsetkych atomov
   aSelectAllAtom(False);
 end;

// Otocenie komponentu
Procedure aRotateSelected(OsX, OsY : Integer; Flop : boolean);
 var x1, x2, y1, y2, ox, oy : Integer;
 Begin
  ox:=OsX;
  oy:=OsY;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
      If (c^.Select) Then //
       Begin
        if (c^.Group=0) Then
         Begin // samotny
          if flop then
           begin
            x1:= (OsX - c^.X) + OsX;
            y1:= (OsY - c^.Y) + OsY;
            x2:= (OsX - c^.ToX) + OsX;
            y2:= (OsY - c^.ToY) + OsY;
           end else begin
            y1:= OsY - (OsX - c^.X);// + OsY;
            x1:= (OsY - c^.Y) + OsX;
            y2:= OsY - (OsX - c^.ToX);// + OsY;
            x2:= (OsY - c^.ToY) + OsX;
           end;
          c^.X   := X1;
          c^.Y   := Y1;
          c^.ToX := X2;
          c^.ToY := Y2;
         end else begin  // group
          if (c^.Typ<>tPosHan) then
           Begin // komponenty
            if flop then
             begin
              x1:= (OX - c^.X) + OX;
              y1:= (OY - c^.Y) + OY;
              x2:= (OX - c^.ToX) + OX;
              y2:= (OY - c^.ToY) + OY;
             end else begin
              y1:= OY - (OX - c^.X);// + OY;
              x1:= (OY - c^.Y) + OX;
              y2:= OY - (OX - c^.ToX);// + OY;
              x2:= (OY - c^.ToY) + OX;
             end;
            c^.X   := X1;
            c^.Y   := Y1;
            c^.ToX := X2;
            c^.ToY := Y2;
           end else begin // uchyt
            ox:=C^.ToX;
            oy:=C^.ToY;
           end;
         end;
       end; // oznacene
      c:=c^.Next;
    until c=Nil;
   end;
 end;

// Zmazanie
// - podla indexu
Function aDeleteByIndex (Index : Integer) : Boolean;
 Begin
  Result:=False;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    a:=nil;
    Repeat
      If c^.Index=Index Then
       Begin // najdeny
        if a=Nil then
         begin // prvy
          aBase:=c^.Next;
          Dispose(c);
          c:=Nil;
          //aBases[aBaseIndex]:=aBase;
         end else begin
          a^.Next:=c^.Next;
          Dispose(c);
          c:=Nil;
         end;
        Result:=True;
       End else Begin
        a:=c;
        c:=c^.Next;
       end;
    until c=Nil;
   end;
 end;
// - podla Group
Function aDeleteGroup (Group : Integer) : Boolean;
Var done : boolean;
 Begin
  Result:=False;
  Repeat
  Done:=True;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    a:=nil;
    Repeat
      If c^.Group=Group Then
       Begin // najdeny
        if a=Nil then
         begin // prvy
          aBase:=c^.Next;
          Dispose(c);
          c:=Nil;
          //aBases[aBaseIndex]:=aBase;
         end else begin
          a^.Next:=c^.Next;
          Dispose(c);
          c:=Nil;
         end;
        Result:=True;
        Done:=False;
       End else Begin
        a:=c;
        c:=c^.Next;
       end;
    until c=Nil;
   end;
  until Done;
 end;
// - Zmazanie oznacenych poloziek
Function aDeleteChecked : Boolean;
Var done : boolean;
 Begin
  Result:=False;
  Repeat
  Done:=True;
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    a:=nil;
    Repeat
      If c^.Select Then
       Begin // najdeny
        if a=Nil then
         begin // prvy
          aBase:=c^.Next;
          Dispose(c);
          c:=Nil;
          //aBases[aBaseIndex]:=aBase;
         end else begin
          a^.Next:=c^.Next;
          Dispose(c);
          c:=Nil;
         end;
        Result:=True;
        Done:=False;
       End else Begin
        a:=c;
        c:=c^.Next;
       end;
    until c=Nil;
   end;
  until Done;
 end;
// - Zmazanie vsetkych poloziek
Procedure aAllDelete;
 Begin
  if aBase<>Nil Then
   Begin // existuje atom
    c:=aBase;
    Repeat
      a:=c;
      c:=c^.Next;
      if a<>Nil Then Dispose(a);
    until c=Nil;
    aBase:=Nil;
    //aBases[aBaseIndex]:=aBase;
   end;
 end;

// Prehladavanie databazy
// - Prvy atom
Procedure aFirst; overload;
 Begin
  Atom:=aBase;
 end;
// - Dalsi atom
Function  aNext : Boolean; overload;
Begin
 If Atom<>Nil Then
  Begin
   Atom:=Atom^.Next;
   Result := (Atom <> Nil);
  End Else Result:=False;
end;
// - Dalsi atom
Function  aEnd : Boolean; overload;
Begin
 If Atom<>Nil Then
  Begin
   Atom:=Atom^.Next;
   Result := (Atom = Nil);
  End Else Result:=True;
end;
// Prehladavanie databazy
// - Prvy atom
Procedure aFirst (var a : pAtom); overload;
 Begin
  a:=aBase;
 end;
// - Dalsi atom
Function  aNext (var a : pAtom) : Boolean;  overload;
Begin
 If a<>Nil Then
  Begin
   a:=a^.Next;
   Result := (a <> Nil);
  End Else Result:=False;
end;
// - Dalsi atom negovane
Function  aEnd (var a : pAtom) : Boolean;  overload;
Begin
 If a<>Nil Then
  Begin
   a:=a^.Next;
   Result := (a = Nil);
  End Else Result:=True;
end;

// Kopirovanie databazy
Procedure aPush;
 Var i : Integer;
 Begin
  // Vymazanie posledneho clena
  if aBases[aBaseMax]<>Nil Then
   Begin // existuje atom
    c:=aBases[aBaseMax];
    Repeat
      a:=c;
      c:=c^.Next;
      if a<>Nil Then Dispose(a);
    until c=Nil;
   end;
  // Posun vsetky o jednu
  For i:=aBaseMax Downto 1 do aBases[i]:=aBases[i-1];
  aBases[0] := nil;
  // prekopiruj databazu do pamate
  aCopy(aBases[0],aBase);
  // ulozenie indexu databazy
  If aBaseIndex<0   Then aBaseIndex:=0;
  If aBaseIndex<100 Then Inc(aBaseIndex);
  aBaseLast := aBaseIndex;
 end;
// - funkcia spat
Function aGoBack : Boolean;
 Var i : Integer;
 Begin
  aGoBack := (aBaseIndex>0);
  If aGoBack Then
   Begin
    Dec(aBaseIndex);
    // Posun vsetky o jednu
    a := aBases[0];
    For i:=1 to aBaseMax do aBases[i-1]:=aBases[i];
    aBases[aBaseMax] := aBase;
    aBase := a;
   end;
 end;
// - hunkcia dalej
Function aGoFoward : Boolean;
 Var i : Integer;
 Begin
  aGoFoward := (aBaseIndex<aBaseLast);
  If aGoFoward Then
   Begin
    Inc(aBaseIndex);
    // Posun vsetky o jednu
    a := aBases[aBaseMax];
    For i:=aBaseMax Downto 1 do aBases[i]:=aBases[i-1];
    aBases[0] := aBase;
    aBase := a;
   end;
 end;

// kopirovanie
Procedure aCopy( Var ToBase, FromBase : pAtom );
 Var d : pAtom;
 Begin
 // ak je uz bunka obsadena, vymaz ju
 if ToBase<>Nil Then
  Begin // existuje atom
   c:=ToBase;
   Repeat
    a:=c;
    c:=c^.Next;
    if a<>Nil Then Dispose(a);
   until c=Nil;
   ToBase:=Nil;
  End;
 // skopiruj from base
 if FromBase<>Nil Then
  Begin // existuje atom
   c:=FromBase;
   d:=Nil;
   Repeat
    // vytvor atom
    New(a);
    If a=Nil Then Halt(1) Else
     begin
      // podarilo sa vytvorit atom
      if ToBase=Nil then ToBase := a; // ak je prvy atom
      a^      := c^;                        // kopirovanie udajov
      a^.Next := Nil;
      if d<>Nil Then d^.Next := a;    // pripoj atom
      d := a;                         // adresa predchadzajuceho
     end;
    c:=c^.Next;
   until c=Nil;
  End;
  // koniec
 end;

// OBJEKT --------------------------------------------------------------- OBJEKT
// Inicializacia
Constructor TAtomDatabase.Create;
 begin
   bAtom      := Nil;
   cAtom      := Nil;
   cc         := Nil;
   aa         := Nil;
   Count      := 0;
  end;
// Ukonci
Destructor TAtomDatabase.Free;
begin
  // Zmazat vsetko
  AllDelete;
end;

// novy
Function TAtomDatabase.Append (Typ, Layer: Byte; X, Y, ToX, ToY, R, G : Integer; Name: String ) : pAtom;
 begin
  New(aa);
  If aa<>Nil Then
   begin
    // podarilo sa vytvorit atom
    cc := bAtom;
    if cc=Nil then
     Begin
      cc:=aa;
      bAtom:=aa;
      //aBases[aBaseIndex] := aBase;
     end else Begin
       While cc^.Next<>nil do
        begin
         cc:=cc^.Next;
        end;
       cc^.Next:=aa;
     end;
    // nasavenie
    Result:=aa;
    aa^.Next:=Nil;
    cAtom:=aa;
    aa^.Layer:=Layer;
    aa^.ToX:=ToX;
    aa^.ToY:=ToY;
    aa^.Group:=G;
    aa^.Name:=Name;
    aa^.R:=R;
    aa^.Typ:=Typ;
    aa^.X:=X;
    aa^.Y:=Y;
    aa^.Index:=Count;
    aa^.Select:=False;
    aa^.Lighed:=False;
    Inc(Count);
    // koniec vytvorenia
   end else Halt(1);
 end;

// Hladanie
// - podla indexu
Function TAtomDatabase.SearchByIndex (Index : Integer) : Boolean;
 Begin
  Result:=False;
  if bAtom<>Nil Then
   Begin // existuje atom
    cc:=bAtom;
    Repeat
      If cc^.Index=Index Then
       Begin // najdeny
        cAtom:=cc;
        Result:=True;
       End;
      cc:=cc^.Next;
    until cc=Nil;
   end;
 end;
// - podla Mena
Function TAtomDatabase.SearchByName (Name : String) : Boolean;
 Begin
  Result:=False;
  if bAtom<>Nil Then
   Begin // existuje atom
    cc:=bAtom;
    Repeat
      If cc^.Name=Name Then
       Begin // najdeny
        cAtom:=cc;
        Result:=True;
       End;
      cc:=cc^.Next;
    until cc=Nil;
   end;
 end;
// - podla poradia
Function TAtomDatabase.SearchByOrder (Index : Integer) : Boolean;
 Var i : Integer;
 Begin
  Result:=False;
  i:=0;
  if bAtom<>Nil Then
   Begin // existuje atom
    cc:=bAtom;
    Repeat
      If i=Index Then
       Begin // najdeny
        cAtom:=cc;
        Result:=True;
       End;
      inc(i);
      cc:=cc^.Next;
    until cc=Nil;
   end;
 end;
// - podla spodu
Function  TAtomDatabase.SearchByLayer (sLayer : Integer) : Boolean;
Var i : Integer;
Begin
 Result:=False;
 i:=0;
 if bAtom<>Nil Then
  Begin // existuje atom
   cc:=bAtom;
   Repeat
     If cc^.Layer=sLayer Then
      Begin // najdeny
       cAtom:=cc;
       Result:=True;
      End;
     inc(i);
     cc:=cc^.Next;
   until cc=Nil;
  end;
end;
// - podla Typu
Function  TAtomDatabase.SearchByType  (sType : Integer) : Boolean;
Var i : Integer;
Begin
 Result:=False;
 i:=0;
 if bAtom<>Nil Then
  Begin // existuje atom
   cc:=bAtom;
   Repeat
     If cc^.Typ=sType Then
      Begin // najdeny
       cAtom:=cc;
       Result:=True;
      End;
     inc(i);
     cc:=cc^.Next;
   until cc=Nil;
  end;
end;

// Zmazanie
// - podla indexu
Function TAtomDatabase.DeleteByIndex (Index : Integer) : Boolean;
 Begin
  Result:=False;
  if bAtom<>Nil Then
   Begin // existuje atom
    cc:=bAtom;
    aa:=nil;
    Repeat
      If cc^.Index=Index Then
       Begin // najdeny
        if aa=Nil then
         begin // prvy
          bAtom:=cc^.Next;
          Dispose(cc);
          cc:=Nil;
          //aBases[aBaseIndex]:=aBase;
         end else begin
          aa^.Next:=cc^.Next;
          Dispose(cc);
          cc:=Nil;
         end;
        Result:=True;
       End else Begin
        aa:=cc;
        cc:=cc^.Next;
       end;
    until cc=Nil;
   end;
 end;
// - Zmazanie oznacenych poloziek
Function TAtomDatabase.DeleteChecked : Boolean;
Var done : boolean;
 Begin
  Result:=False;
  Repeat
  Done:=True;
  if bAtom<>Nil Then
   Begin // existuje atom
    cc:=bAtom;
    aa:=nil;
    Repeat
      If cc^.Select Then
       Begin // najdeny
        if aa=Nil then
         begin // prvy
          bAtom:=cc^.Next;
          Dispose(cc);
          cc:=Nil;
          //aBases[aBaseIndex]:=aBase;
         end else begin
          aa^.Next:=cc^.Next;
          Dispose(cc);
          cc:=Nil;
         end;
        Result:=True;
        Done:=False;
       End else Begin
        aa:=cc;
        cc:=cc^.Next;
       end;
    until cc=Nil;
   end;
  until Done;
 end;
// - Zmazanie vsetkych poloziek
Procedure TAtomDatabase.AllDelete;
 Begin
  if bAtom<>Nil Then
   Begin // existuje atom
    cc:=bAtom;
    Repeat
      aa:=cc;
      cc:=cc^.Next;
      if aa<>Nil Then Dispose(aa);
    until cc=Nil;
    bAtom:=Nil;
    count:=0;
    //aBases[aBaseIndex]:=aBase;
   end;
 end;

// Prehladavanie databazy
// - Prvy atom
Procedure TAtomDatabase.First;
 Begin
  cAtom:=bAtom;
 end;
// - Dalsi atom
Function  TAtomDatabase.Next : Boolean;
Begin
 If cAtom<>Nil Then
  Begin
   cAtom  := cAtom^.Next;
   Result := (cAtom <> Nil);
  End Else Result:=False;
end;

end.

