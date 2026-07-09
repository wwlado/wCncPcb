unit cb2dxf;

{$mode ObjFPC}{$H+}



interface

uses
  Classes, SysUtils, wStrUtils, cb2Atom, cb2Graphics,
  Clipper in 'Clipper.pas',
  Clipper.Core in 'Clipper.Core.pas',
  Clipper.Engine in 'Clipper.Engine.pas',
  Clipper.Offset in 'Clipper.Offset.pas',
  Clipper.RectClip in 'Clipper.RectClip.pas',
  Clipper.Minkowski in 'Clipper.Minkowski.pas';

 Type TDxfStructure = Record
   Pointer  : Integer;
   BeginPtr : Integer;
   EndPtr   : Integer;
   Loaded   : Boolean;
   EOL      : Boolean;
   Key      : String [10];
   Data     : String [255];
  End;

Var dxfStrings : TStrings;
    dxfPointer : TDxfStructure;
    dxfFileType: Byte;
    // DXF   - 0
    // Geber - 1
    // Eagle - 2
    //-------------------- Parametre
    dxfDrill       : Integer;
    dxfLayer       : Byte;
    dxfGroup       : Integer;
    dxfCircleSteps : Integer;
    dxfRoundError  : Integer;
    dxfSimple      : Boolean;
    // ------------------- Clipper
    dxfSubject : TPaths64;
    dxfClip    : TPaths64;
    dxfSolution: TPaths64;
    // --- Maximalna hodnota
    dxfWidthMax   : Integer;
    dxfHeightMax  : Integer;

// Hlavna procedura otavrania subouru -------------------------- Rozoznanie typu
Procedure dxfSetParameter (Layer : Byte; Group, Drill, CircleSteps, RoundError : Integer; Simple : Boolean);
Function dxfOpenFile (FileName : String) : Boolean;
Function dxfExecuteDxf : Boolean;
Function dxfExecuteGeber : Boolean;
Function dxfExecuteEagle : Boolean;
Function dxfExecute : Boolean;
// Procedury nacitania z Textu --------------------------------------------- TXT
// - Inicializacia
Function  dxfInit : Boolean;
// - Nacitanie suboru s vytvorenim
Function  dxfLoadFile (FileName : String) : Boolean;
// - Znicenie
Procedure dxfFree;

// - Nastavenie pointera pre text
Function dxfSetTxtLine( Line : Integer ) : Boolean; Overload;
Function dxfSetTxtLine( Var pDxf : TDxfStructure; Line : Integer ) : Boolean; Overload;
Procedure dxfResetTxtLine( Var pDxf : TDxfStructure );

// - Nacitanie riadku
Function dxfGetTxtLine : String; Overload;
Function dxfGetTxtLine ( Var pDxf : TDxfStructure ) : String; Overload;
Function dxfGetTxtLine ( Var Str : ShortString ) : Boolean; Overload;
Function dxfGetTxtLine ( Var pDxf : TDxfStructure; Var Str : ShortString ) : Boolean; Overload;

// - Nacitanie polozky
Function dxfGetItem : Boolean; Overload;
Function dxfGetItem ( Var pDxf : TDxfStructure ) : Boolean; Overload;
Function dxfGetItem ( Var Key, Data : String ) : Boolean; Overload;
Function dxfGetItem ( Var pDxf : TDxfStructure; Var Key, Data : String ) : Boolean; Overload;

// - Nacitanie pointerov Bloku
Function dxfSetSection ( Var SetDxf : TDxfStructure; Key, BeginDat, EndDat : String) : Boolean; OverLoad;
Function dxfSetSection ( Var pDxf, SetDxf : TDxfStructure; Key, BeginDat, EndDat : String) : Boolean; OverLoad;

// - Prekonvertovanie do databazy
Procedure dxfDrawPath64 (Data : TPath64; Clossed : Boolean);
Procedure dxfDrawPaths64 (Data : TPaths64; Clossed : Boolean);
Procedure dxfDrawUnion;

// - Vkladanie dat
Procedure dxfAddReset;    // vynulovanie
Procedure dxfAddLine ( x1, y1, x2, y2, d : Integer);
Procedure dxfAddRectangle ( x1, y1, W, H : Integer);
Procedure dxfAddCircle ( x, y, r, Steps : Integer);
Procedure dxfAddBeginLine ( x, y, d : Integer);
Procedure dxfAddNextLine ( x1, y1, x2, y2, d : Integer);
// simple - bez union
Procedure dxfDrwLine ( x1, y1, x2, y2, d : Integer);
Procedure dxfDrwRectangle ( x1, y1, W, H : Integer);
Procedure dxfDrwCircle ( x, y, r, Steps : Integer);
Procedure dxfDrwBeginLine ( x, y, d : Integer);
Procedure dxfDrwNextLine ( x1, y1, x2, y2, d : Integer);


// - Ine procedury
Function dxfIntSqrt ( num : Int64) : Int64;


implementation
Uses MineForm;


// Procedury nacitania z Textu --------------------------------------------- TXT
// - Vytvorenie string listu
Function  dxfInit : Boolean;
 Begin
  If not Assigned(dxfStrings) Then dxfStrings:=TStringList.Create;
  Result:=Assigned(dxfStrings);
  If Result Then
   Begin
    dxfPointer.Pointer  := 0;
    dxfPointer.BeginPtr := 0;
    dxfPointer.EndPtr   := dxfStrings.Count;
    dxfPointer.EOL      := (dxfPointer.EndPtr=0);
    dxfPointer.Loaded   := False;
    dxfSetParameter (TCopper, 0, 80, 32, 10, False);
   end;
 End;
// - Nacitanie suboru s vytvorenim
Function  dxfLoadFile (FileName : String) : Boolean;
Begin
 Result:=False;
 If not Assigned(dxfStrings) Then dxfStrings:=TStringList.Create;
 If FileExists(FileName) Then
  Begin
   dxfStrings.LoadFromFile(FileName);
   Result:=True;
   dxfPointer.Pointer  := 0;
   dxfPointer.BeginPtr := 0;
   dxfPointer.EndPtr   := dxfStrings.Count;
   dxfPointer.EOL      := (dxfPointer.EndPtr=0);
   dxfPointer.Loaded   := False;
  end;
End;
// - Znicenie
Procedure dxfFree;
 Begin
  if Assigned(dxfStrings) Then dxfStrings.Free;
 end;
// Nastavenie parametrov
Procedure dxfSetParameter (Layer : Byte; Group, Drill, CircleSteps, RoundError : Integer; Simple : Boolean);
 Begin
  dxfLayer        := Layer;
  dxfGroup        := Group;
  dxfDrill        := Drill;
  dxfCircleSteps  := CircleSteps;
  dxfRoundError   := RoundError;
  dxfSimple       := Simple;
 end;

// Otvorenie suboru --------------------------------------------------- OpenFile
Function dxfOpenFile (FileName : String) : Boolean;
 Begin
  Result:=False;
  if dxfLoadFile(FileName) Then
   Begin
    if dxfStrings.Count>3 Then
     Begin
      dxfFileType:=1;
      if dxfStrings.Strings[0]='G75*' Then dxfFileType:=1;                   // Geber
      if StrDelSpace(dxfStrings.Strings[0])='0'  Then dxfFileType:=0;        // Dxf
      if StrIfIn(dxfStrings.Strings[2], '<EAGLE', True) Then dxfFileType:=2; // Eagle
      Result:=(dxfFileType<255);
     end;
   end;
 end;

// Nacitanie suboru
// - dxf
Function dxfExecuteDxf : Boolean;
 var dxfBlock, dxfHeader, dxfEntities : TDxfStructure;
 Begin
  Result:=dxfSetTxtLine(0);
  if Result Then
   Begin
    dxfSetSection( dxfEntities, '2', 'ENTITIES', 'ENDSEC');
    dxfSetSection( dxfBlock   , '2', 'BLOCKS'  , 'ENDSEC');
    dxfSetSection( dxfHeader  , '2', 'HEADER'  , 'ENDSEC');
   end;

 end;
// - Geber
Function dxfExecuteGeber : Boolean;
 Var Line : String;
     A, B, C, D : Integer;
     N          : String;
     P, X, Y    : Integer;
     s, l       : String;
     i, j, Q, W : Integer;
 Begin
  N:='';
  p:=3;
  dxfResetTxtLine(dxfPointer);
  dxfAddReset;
  x:=0; y:=0;
  q:=0; w:=0;
  dxfWidthMax   := 0;
  dxfHeightMax  := 0;
  Repeat
   Line:=UpperCase(dxfGetTxtLine);
   If Line='%MOIN*%' Then Form1.imbInch.Click;
   If Line='%MOMM*%' Then Form1.imbMM.Click;
   If Line='%FSLAX26Y26*%' Then P:=5;
   If Line='%FSLAX46Y46*%' Then P:=5;
   If Line='%FSLAX24Y24*%' Then P:=3;
   If Line='%FSLAX33Y33*%' Then P:=2;
   If Line[1]='D' Then // Volba nastroja
    Begin
     l:=strGetTextToChars(Line, '*', '*');
     j:=Length(l);
     For i:=0 To dxfStrings.Count-1 do
      Begin     // Slucka
       if Length(dxfStrings.Strings[i])>(j+5) Then
        Begin   // ak je dlsi retazec
         strDepartmentText(UpperCase(dxfStrings.Strings[i]), ',', '*', 'X');
         If (strDataCount>1) and (Length(strData[0])>j+3) and (Copy(strData[0], 4, j)=l) Then
          Begin // Spravny parameter
           N:=Copy(strData[0], j+4, Length(strData[0])-(j+3));
           If strDataCount>1 Then  Form1.ConvertStrToiNum(strData[1], A);
           If strDataCount>2 Then  Form1.ConvertStrToiNum(strData[2], B);
           If strDataCount>3 Then  Form1.ConvertStrToiNum(strData[3], C);
           If strDataCount>4 Then  Form1.ConvertStrToiNum(strData[4], D);
          end;  // Spravny parameter
        End;    // ak je dlhsi retazec
      end;      // Slucka
    end;
   // Hlavny
   If Line[1]='X' Then // Volba nastroja
    Begin
     strDepartmentText(strGetTextToChars(Line, '*', '*'), 'X', 'Y', 'D' );
     If strDataCount>3 Then
      Begin // nacitanie hodnot
       If Form1.ConvertStrToiNum(strInsCharInPos(strData[1],Length(strData[1])-P ,'.'), X) And
          Form1.ConvertStrToiNum(strInsCharInPos(strData[2],Length(strData[2])-P ,'.'), Y) Then
           Begin // prekonvertovane suradnice
            Case strData[3] of
             '01' : Begin // Ciara
                     if A>0 Then Begin
                             if dxfSimple Then dxfDrwNextLine( q, w, X, Y, A+dxfRoundError )
                                          Else dxfAddNextLine( q, w, X, Y, A+dxfRoundError );
                            End Else begin
                             If dxfWidthMax <X Then dxfWidthMax :=X;
                             If dxfHeightMax<Y Then dxfHeightMax:=Y;
                            end;
                     q:=X; w:=Y;
                    end;  // Ciara
             '02' : Begin // Zaciatok
                     if A>0 Then Begin
                             if dxfSimple Then dxfDrwBeginLine( X, Y, A+dxfRoundError )
                                          Else dxfAddBeginLine( X, Y, A+dxfRoundError );
                            End Else begin
                             If dxfWidthMax <X Then dxfWidthMax :=X;
                             If dxfHeightMax<Y Then dxfHeightMax:=Y;
                            end;
                     q:=X; w:=Y;
                    end;  // Zaciatok
             '03' : Begin // Komponent
                     if dxfSimple Then
                      Begin
                       case N of
                        'C'   : dxfDrwCircle(X, Y, (A+dxfRoundError) div 2, dxfCircleSteps);
                        'R'   : dxfDrwRectangle (X, Y, A+dxfRoundError, B);
                        'OC8' : dxfDrwCircle(X, Y, (A+dxfRoundError) div 2, 8);
                       end;
                      end else begin
                       case N of
                        'C'   : dxfAddCircle(X, Y, (A+dxfRoundError) div 2, dxfCircleSteps);
                        'R'   : dxfAddRectangle (X, Y, A+dxfRoundError, B);
                        'OC8' : dxfAddCircle(X, Y, (A+dxfRoundError) div 2, 8);
                       end;
                      end;
                      q:=X; w:=Y;
                    end;  // Komponent
            end;
           End;  // prekonvertovane suradnice
      end;  // nacitanie hodnot
    End;
  Until dxfPointer.EOL;
  if not dxfSimple Then dxfDrawUnion;
  Result:=True;
 end;
// - Eagle
Function dxfExecuteEagle : Boolean;
 Begin

 end;
// - vseobecne
Function dxfExecute : Boolean;
 Begin
  Result:=False;
  case dxfFileType of
   0: Result:=dxfExecuteDXF;
   1: Result:=dxfExecuteGeber;
   2: Result:=dxfExecuteEagle;
  end;
 end;

// -----------------------------------------------------------------------------
// - Nastavenie pointera pre text
Function dxfSetTxtLine( Line : Integer ) : Boolean; Overload;
 Begin
  Result:=False;
  if Assigned(dxfStrings) Then
   Begin
    Result:= ((Line<dxfStrings.Count) and (Line>=0));
    if Result Then dxfPointer.Pointer:=Line;
   end;
 end;
// - Variant
Function dxfSetTxtLine( Var pDxf : TDxfStructure; Line : Integer ) : Boolean; Overload;
 Begin
  Result:=False;
  if Assigned(dxfStrings) Then
   Begin
    Result:= ((Line<dxfStrings.Count) and (Line>=0));
    if Result Then pDxf.Pointer:=Line;
   end;
 end;
// - Reset
Procedure dxfResetTxtLine( Var pDxf : TDxfStructure );
 Begin
    pDxf.Pointer:=pDxf.BeginPtr;
 end;


// - Nacitanie riadku
Function dxfGetTxtLine : String; Overload;
Begin
 Result            := '';
 dxfPointer.Loaded := False;
 dxfPointer.EOL    := True;
 if Assigned(dxfStrings) and (dxfPointer.Pointer<dxfStrings.Count) and (dxfPointer.Pointer>=0) Then
  Begin
   Result      := dxfStrings.Strings[dxfPointer.Pointer];
   dxfPointer.Loaded := True;
   Inc(dxfPointer.Pointer);
   dxfPointer.EOL    := (dxfPointer.Pointer>=dxfStrings.Count);
  end;
end;
// - Variant
Function dxfGetTxtLine ( Var pDxf : TDxfStructure ) : String; Overload;
 Begin
  Result      := '';
  pDxf.Loaded := False;
  pDxf.EOL    := True;
  if Assigned(dxfStrings) and (pDxf.Pointer<dxfStrings.Count) and (pDxf.Pointer>=0) Then
   Begin
    Result      := dxfStrings.Strings[pDxf.Pointer];
    pDxf.Loaded := True;
    Inc(pDxf.Pointer);
    pDxf.EOL    := (pDxf.Pointer>=dxfStrings.Count);
   end;
 end;
// - Variant
Function dxfGetTxtLine ( Var Str : ShortString ) : Boolean; Overload;
Begin
 Str               := '';
 dxfPointer.Loaded := False;
 dxfPointer.EOL    := True;
 if Assigned(dxfStrings) and (dxfPointer.Pointer<dxfStrings.Count) and (dxfPointer.Pointer>=0) Then
  Begin
   Str         := dxfStrings.Strings[dxfPointer.Pointer];
   dxfPointer.Loaded := True;
   Inc(dxfPointer.Pointer);
   dxfPointer.EOL    := (dxfPointer.Pointer>=dxfStrings.Count);
  end;
 Result := dxfPointer.Loaded;
end;
// - Variant
Function dxfGetTxtLine ( Var pDxf : TDxfStructure; Var Str : ShortString ) : Boolean; Overload;
 Begin
  Str         := '';
  pDxf.Loaded := False;
  pDxf.EOL    := True;
  if Assigned(dxfStrings) and (pDxf.Pointer<dxfStrings.Count) and (pDxf.Pointer>=0) Then
   Begin
    Str         := dxfStrings.Strings[pDxf.Pointer];
    pDxf.Loaded := True;
    Inc(pDxf.Pointer);
    pDxf.EOL    := (pDxf.Pointer>=dxfStrings.Count);
   end;
  Result := pDxf.Loaded;
 end;

// - Nacitat polozku
Function dxfGetItem : Boolean; Overload;
 Begin
  Result := False;
  if dxfGetTxtLine(dxfPointer.Key) and dxfGetTxtLine(dxfPointer.Data) Then
   Begin           // Nacitane polozky
    dxfPointer.Key := strDelFirstSpace(dxfPointer.Key);      // bez medzier
    Result         := True;
   end else Begin  // Nenacitane polozky
    dxfPointer.Key :='';
    dxfPointer.Data:='';
   end;            // Koniec polozkam
  dxfPointer.Loaded:= Result;
 end;
// - Variant
Function dxfGetItem ( Var pDxf : TDxfStructure ) : Boolean; Overload;
Begin
 Result := False;
 if pDxf.Pointer<pDxf.BeginPtr Then pDxf.Pointer:=pDxf.BeginPtr;
 if (pDxf.Pointer>=pDxf.BeginPtr) and (pDxf.Pointer<pDxf.EndPtr) and
    dxfGetTxtLine(pDxf, pDxf.Key) and dxfGetTxtLine(pDxf, pDxf.Data) Then
  Begin           // Nacitane polozky
   pDxf.Key       := strDelFirstSpace(pDxf.Key);      // bez medzier
   Result         := True;
  end else Begin  // Nenacitane polozky
   pDxf.Key       := '';
   pDxf.Data      := '';
  end;            // Koniec polozkam
  pDxf.Loaded     := Result;
end;
// - Variant
Function dxfGetItem ( Var Key, Data : String ) : Boolean; Overload;
 Begin
  Result := False;
  if dxfGetTxtLine(dxfPointer.Key) and dxfGetTxtLine(dxfPointer.Data) Then
   Begin           // Nacitane polozky
    dxfPointer.Key := strDelFirstSpace(dxfPointer.Key);      // bez medzier
    Result         := True;
   end else Begin  // Nenacitane polozky
    dxfPointer.Key :='';
    dxfPointer.Data:='';
   end;            // Koniec polozkam
   Key  := dxfPointer.Key;
   Data := dxfPointer.Data;
   dxfPointer.Loaded    := Result;
 end;
// - Variant
Function dxfGetItem ( Var pDxf : TDxfStructure; Var Key, Data : String ) : Boolean; Overload;
Begin
 Result := False;
 if pDxf.Pointer<pDxf.BeginPtr Then pDxf.Pointer:=pDxf.BeginPtr;
 if (pDxf.Pointer>=pDxf.BeginPtr) and (pDxf.Pointer<pDxf.EndPtr) and
    dxfGetTxtLine(pDxf, pDxf.Key) and dxfGetTxtLine(pDxf, pDxf.Data) Then
  Begin           // Nacitane polozky
   pDxf.Key       := strDelFirstSpace(pDxf.Key);      // bez medzier
   Result         := True;
  end else Begin  // Nenacitane polozky
   pDxf.Key       :='';
   pDxf.Data      :='';
  end;            // Koniec polozkam
  Key  := pDxf.Key;
  Data := pDxf.Data;
  pDxf.Loaded     := Result;
end;

// - Nacitanie pointerov Bloku
Function dxfSetSection ( Var SetDxf : TDxfStructure; Key, BeginDat, EndDat : String) : Boolean; OverLoad;
 Var OnLoad     : Boolean;
     LdBg, LdEd : Boolean;
 Begin
  BeginDat        := UpperCase(BeginDat);
  EndDat          := UpperCase(EndDat);
  OnLoad          := False;
  SetDxf.BeginPtr := 0;
  SetDxf.EndPtr   := 0;
  LdBg            := False;
  LdEd            := False;
  Result          := dxfSetTxtLine(SetDxf, 0);
  if Result then
   Begin                   // a.) Text je na zaciatku
    While dxfGetItem(SetDxf) do
     Begin                 // b.) - slucka nacitania
      if onLoad and (LdEd=False) {and (SetDxf.Key=Key)} and (UpperCase(SetDxf.Data)=EndDat)         Then
       Begin
        SetDxf.EndPtr:=SetDxf.Pointer-2;
        OnLoad:=False;
        LdEd  :=True;
       end;
      if (Not OnLoad) and (LdBg=False) and (SetDxf.Key=Key) and (UpperCase(SetDxf.Data)=BeginDat) Then
       Begin
        SetDxf.BeginPtr:=SetDxf.Pointer;
        OnLoad:=True;
        LdBg  :=True;
       end;
     end;                  // b.)
    Result:=(SetDxf.BeginPtr<SetDxf.EndPtr) and LdBg and LdEd;
    SetDxf.Pointer:=SetDxf.BeginPtr;
   end else Result:=False; // a.) - Chyba
 End;
// - Variant
Function dxfSetSection ( Var pDxf, SetDxf : TDxfStructure; Key, BeginDat, EndDat : String) : Boolean; OverLoad;
 Var OnLoad     : Boolean;
     LdBg, LdEd : Boolean;
 Begin
  BeginDat        := UpperCase(BeginDat);
  EndDat          := UpperCase(EndDat);
  OnLoad          := False;
  SetDxf.BeginPtr := pDxf.BeginPtr;
  SetDxf.EndPtr   := pDxf.EndPtr;
  LdBg            := False;
  LdEd            := False;
  Result          := dxfSetTxtLine(SetDxf, pDxf.BeginPtr);
  if Result then
   Begin                   // a.) Text je na zaciatku
    While dxfGetItem(SetDxf) and (SetDxf.Pointer<pDxf.EndPtr) do
     Begin                 // b.) - slucka nacitania
      if onLoad and (LdEd=False) {and (SetDxf.Key=Key)} and (UpperCase(SetDxf.Data)=EndDat)         Then
       Begin
        SetDxf.EndPtr:=SetDxf.Pointer-2;
        OnLoad:=False;
        LdEd  :=True;
       end;
      if (Not OnLoad) and (LdBg=False) and (SetDxf.Key=Key) and (UpperCase(SetDxf.Data)=BeginDat) Then
       Begin
        SetDxf.BeginPtr:=SetDxf.Pointer;
        OnLoad:=True;
        LdBg  :=True;
       end;
     end;                  // b.)
    Result:=(SetDxf.BeginPtr<SetDxf.EndPtr) and LdBg and LdEd;
    SetDxf.Pointer:=SetDxf.BeginPtr;
   end else Result:=False; // a.) - Chyba
 End;

// ------------------------------------------------------------------------ DRAW
// - Path - Konverzia jedneho objektu
Procedure dxfDrawPath64 (Data : TPath64; Clossed : Boolean);
 Var i, j : Integer;
     x, y : Integer;
 Begin
  j := Length(data);
  If j>1 Then
   Begin
    x:= Data[0].X;
    y:= Data[0].Y;
    For i:=1 to j-1 do
     Begin
      aAppend(tWay, dxfLayer, x, y, Data[i].X, Data[i].Y, dxfDrill, dxfGroup, '');
      x:= Data[i].X;
      y:= Data[i].Y;
     end;
    If Clossed Then
     Begin
      aAppend(tWay, dxfLayer, x, y, Data[0].X, Data[0].Y, dxfDrill, dxfGroup, '');
     end;
   end;
 end;
// - PathS - Konverzia viacerich objektov
Procedure dxfDrawPaths64 (Data : TPaths64; Clossed : Boolean);
 Var i, j : Integer;
 Begin
  j := Length(data);
  If j>0 Then
   Begin
    For i:=0 to j-1 do
     Begin
      dxfDrawPath64 ( Data[i], Clossed );
     end;
   end;
 end;
// - Vytvor
Procedure dxfDrawUnion;
 Var d : TPaths64;
 Begin
  d:=Union(dxfSubject, frNonZero);
  if dxfDrill>0 Then d:=InflatePaths(d, dxfDrill div 2);
  dxfDrawPaths64( d, True );
 end;

// -------------------------------------------------------------------- Vytvorit
// ResetAddReset;
Procedure dxfAddReset;
 Begin
  SetLength(dxfSubject, 0);
 end;

// - Ciara
procedure dxfAddLine ( x1, y1, x2, y2, d : Integer);
 var X, Y, L, R : Int64;
     p          : TPath64;
 Begin
  R := d div 2;
  // vektor a z neho kolmy vektor
  Y :=  (x2 - x1);
  X := -(y2 - y1);
  // vypocet dlzky kolmeho vektora
  L := dxfintSqrt( X*X + Y*Y );
  // prepocet offsetu X, Y
  if L<>0 Then
   Begin
    X := (X * R) div L;
    Y := (Y * R) div L;
   end else Begin
    X:=0;
    Y:=0;
   end;
  // vytvorenie stvorca
  SetLength(p, 4);
  p[3].X:=x1+X;
  p[3].Y:=y1+Y;
  p[2].X:=x2+X;
  p[2].Y:=y2+Y;
  p[1].X:=x2-X;
  p[1].Y:=y2-Y;
  p[0].X:=x1-X;
  p[0].Y:=y1-Y;
  // ulozit
  AppendPath(dxfSubject, p);
 end;
// - Obdlznik
procedure dxfAddRectangle ( x1, y1, W, H : Integer);
 var X, Y       : Int64;
     p          : TPath64;
 Begin
  x:=W div 2;
  y:=H div 2;
  // vytvorenie stvorca
  SetLength(p, 4);
  p[0].X:=x1+X;
  p[0].Y:=y1-Y;
  p[1].X:=x1+X;
  p[1].Y:=y1+Y;
  p[2].X:=x1-X;
  p[2].Y:=y1+Y;
  p[3].X:=x1-X;
  p[3].Y:=y1-Y;
  // ulozit
  AppendPath(dxfSubject, p);
 end;
// - Kruh
Procedure dxfAddCircle ( x, y, r, Steps : Integer);
 var p : TPath64;
 Begin
  p := Ellipse(Rect64(x-r, y-r, x+r, y+r), Steps);
  AppendPath(dxfSubject, p);
 end;
// - Zaciatok ciary - kruh
Procedure dxfAddBeginLine ( x, y, d : Integer);
 var p : TPath64;
     r : Integer;
 Begin
  r := d div 2;
  p := Ellipse(Rect64(x-r, y-r, x+r, y+r), dxfCircleSteps);
  AppendPath(dxfSubject, p);
 end;
// - dalsia ciara
Procedure dxfAddNextLine ( x1, y1, x2, y2, d : Integer);
 Begin
  dxfAddLine      ( x1, y1, x2,  y2, d);
  dxfAddBeginLine ( x2, y2, d);
 end;

// - Ciara
procedure dxfDrwLine ( x1, y1, x2, y2, d : Integer);
 Begin
  aAppend(tWay, dxfLayer, x1, y1, x2, y2, d, dxfGroup, '');
 end;
// - Obdlznik
procedure dxfDrwRectangle ( x1, y1, W, H : Integer);
 var X, Y       : Int64;
 Begin
  x:=W div 2;
  y:=H div 2;
  aAppend(tWay, dxfLayer, x1-x, y1-y, x1+x, y1-y, 0, dxfGroup, '');
  aAppend(tWay, dxfLayer, x1+x, y1-y, x1+x, y1+y, 0, dxfGroup, '');
  aAppend(tWay, dxfLayer, x1+x, y1+y, x1-x, y1+y, 0, dxfGroup, '');
  aAppend(tWay, dxfLayer, x1-x, y1+y, x1-x, y1-y, 0, dxfGroup, '');
 end;
// - Kruh
Procedure dxfDrwCircle ( x, y, r, Steps : Integer);
 Begin
  aAppend(tCircle, dxfLayer, x, y, 0, 0, r*2, dxfGroup, '');
 end;
// - Zaciatok ciary - kruh
Procedure dxfDrwBeginLine ( x, y, d : Integer);
 Begin
  //
 end;
// - dalsia ciara
Procedure dxfDrwNextLine ( x1, y1, x2, y2, d : Integer);
 Begin
  dxfDrwLine      ( x1, y1, x2,  y2, d);
 end;


// ----------------------------------------------------------- Specialne funkcie
// Druha odmocnina INT
Function dxfIntSqrt ( num : Int64) : Int64;
 Var min, max, mid : Int64;
 Begin
  Result := 1;
  min    := 1;
  max    := num;
  while (min <= max) do
   Begin
    mid := min + ((max - min) div 2);
    if ((mid*mid) <= num) then
     begin
      Result := mid;
      min    := mid + 1;
     end else begin
      max    := mid - 1;
     end;
   end;
 end;


end.

