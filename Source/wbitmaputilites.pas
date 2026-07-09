unit wBitmapUtilites;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Forms, SysUtils, Graphics, cb2view;


// Procedura na vytvorenie vlastnej bitmapy
Procedure mapCreate( aWidth, aHeight : Integer);
Procedure mapFree;
Procedure mapLoad( pic : TBitmap );    // obsahuje Create
Procedure mapSave( pic : TBitmap );    // obsahuje Free
Procedure mapRepaint( pic : TBitmap ); // Podobne ako save, len nezmaze objekt

// Pixely
Procedure mapPoke ( X, Y : Integer; C : Byte);
Function  mapPeek ( X, Y : Integer) : Byte;
// Nacitanie cez tri pointery
Procedure mapSetRowPointer( Line : Integer );
Function  mapGetNextRow : Boolean;
Procedure mapSetColPointer( Col : Integer );
Function  mapGetNextCol : Boolean;
Procedure mapSetColor ( Color : Byte );
// Metody kontury
Procedure mapMetode1 (cC, cN, cL, cU : Byte);
Procedure mapMetode2 (cC, cN, cL, cU : Byte; DrillPix : Integer);
// Metoda vytiahnutia suradnic
Function  mapGetCoordinate (cU, cD : Byte; Var Cmd, X, Y : Integer; MaxPix : Integer) : Boolean;


implementation
uses MineForm;

var MyMap      : pByte;
    p1, p2, p3 : pByte;
    pEnd, pRes : pByte;
    Width      : Integer;
    Height     : Integer;
    mapBitmap  : TBitmap;
    a1, a2, a3 : Byte;
    b1, b2, b3 : Byte;
    c1, c2, c3 : Byte;
    pX, pY, pC : Integer;

// Procedura na vytvorenie vlastnej bitmapy
Procedure mapCreate( aWidth, aHeight : Integer);
 Begin
  MyMap := GetMem(aWidth*aHeight);
  Width := aWidth;
  Height:= aHeight;
 end;
Procedure mapFree;
 Begin
  FreeMem(MyMap, Width*Height);
 end;

// Ncitanie bitmamy
Procedure mapLoad( pic : TBitmap );
var
  bytesPerPixel, redOffset, greenOffset, blueOffset: byte;
  LinePixs, MemPtr: PByte;
  X, Y    : integer;
  Color   : Byte;
begin
  mapBitmap     := pic;
  Width         := pic.Width;
  Height        := pic.Height;
  MyMap         := GetMem( Width*Height );
  MemPtr        := MyMap;
  bytesPerPixel := pic.RawImage.Description.BitsPerPixel div 8;
  redOffset     := pic.RawImage.Description.RedShift div 8;
  greenOffset   := pic.RawImage.Description.GreenShift div 8;
  blueOffset    := pic.RawImage.Description.BlueShift div 8;
  {$IFNDEF ENDIAN_LITTLE}
  redOffset := bytesPerPixel - 1 - redOffset;
  greenOffset := bytesPerPixel - 1 - greenOffset;
  blueOffset := bytesPerPixel - 1 - blueOffset;
  {$ENDIF}

  for Y := 0 to Height - 1 do
  begin
    LinePixs := pic.RawImage.GetLineStart(Y);
    for X := 0 to Width - 1 do
    begin
      color:=0;
      if (LinePixs+blueOffset)^  > 127 Then Color := Color+4;
      if (LinePixs+greenOffset)^ > 127 Then Color := Color+2;
      if (LinePixs+redOffset)^   > 127 Then Color := Color+1;
      MemPtr^ :=Color;
      inc(MemPtr);
      inc(LinePixs, bytesPerPixel);
    end;
  end;
end;
// Ulozenie dat naspat
Procedure mapSave( pic : TBitmap );
var
  bytesPerPixel, redOffset, greenOffset, blueOffset: byte;
  LinePixs, MemPtr: PByte;
  X, Y    : integer;
  Color   : Byte;
begin
  MemPtr        := MyMap;
  bytesPerPixel := pic.RawImage.Description.BitsPerPixel div 8;
  redOffset     := pic.RawImage.Description.RedShift div 8;
  greenOffset   := pic.RawImage.Description.GreenShift div 8;
  blueOffset    := pic.RawImage.Description.BlueShift div 8;
  {$IFNDEF ENDIAN_LITTLE}
  redOffset := bytesPerPixel - 1 - redOffset;
  greenOffset := bytesPerPixel - 1 - greenOffset;
  blueOffset := bytesPerPixel - 1 - blueOffset;
  {$ENDIF}
  pic.BeginUpdate(False);
  for Y := 0 to Height - 1 do
  begin
    LinePixs := pic.RawImage.GetLineStart(Y);
    for X := 0 to Width - 1 do
    begin
      Color := MemPtr^;
      if (Color and 4) > 0 then (LinePixs+blueOffset)^  := 255
                           else (LinePixs+blueOffset)^  := 0;
      if (Color and 2) > 0 then (LinePixs+greenOffset)^ := 255
                           else (LinePixs+greenOffset)^ := 0;
      if (Color and 1) > 0 then (LinePixs+redOffset)^   := 255
                           else (LinePixs+redOffset)^   := 0;
      inc(MemPtr);
      inc(LinePixs, bytesPerPixel);
    end;
  end;
  FreeMem(MyMap, Width*Height);
  pic.EndUpdate(False);
end;
// Prekresli
Procedure mapRepaint( pic : TBitmap );
var
  bytesPerPixel, redOffset, greenOffset, blueOffset: byte;
  LinePixs, MemPtr: PByte;
  X, Y    : integer;
  Color   : Byte;
begin
  MemPtr        := MyMap;
  bytesPerPixel := pic.RawImage.Description.BitsPerPixel div 8;
  redOffset     := pic.RawImage.Description.RedShift div 8;
  greenOffset   := pic.RawImage.Description.GreenShift div 8;
  blueOffset    := pic.RawImage.Description.BlueShift div 8;
  {$IFNDEF ENDIAN_LITTLE}
  redOffset := bytesPerPixel - 1 - redOffset;
  greenOffset := bytesPerPixel - 1 - greenOffset;
  blueOffset := bytesPerPixel - 1 - blueOffset;
  {$ENDIF}
  pic.BeginUpdate(False);
  for Y := 0 to Height - 1 do
  begin
    LinePixs := pic.RawImage.GetLineStart(Y);
    for X := 0 to Width - 1 do
    begin
      Color := MemPtr^;
      if (Color and 4) > 0 then (LinePixs+blueOffset)^  := 255
                           else (LinePixs+blueOffset)^  := 0;
      if (Color and 2) > 0 then (LinePixs+greenOffset)^ := 255
                           else (LinePixs+greenOffset)^ := 0;
      if (Color and 1) > 0 then (LinePixs+redOffset)^   := 255
                           else (LinePixs+redOffset)^   := 0;
      inc(MemPtr);
      inc(LinePixs, bytesPerPixel);
    end;
  end;
  pic.EndUpdate(False);
end;

// Pixels
Procedure mapPoke ( X, Y : Integer; C : Byte);
Var p : pByte;
 Begin
  p:=myMap;
  inc(p, X+(y*Width));
  p^:=c;
 end;
Function mapPeek ( X, Y : Integer) : Byte;
Var p : pByte;
 Begin
  p:=myMap;
  inc(p, X+(y*Width));
  Result:=p^;
 end;
// Nacitanie po Riadkoch
Procedure mapSetRowPointer( Line : Integer );
 Begin
  // nacitanie prveho riadku
  p1:=myMap;
  inc(p1, Line*Width);
  // nacitanie druheho riadku
  p2:=p1;
  inc(p2, Width);
  // nacitanie tretieho riadku
  p3:=p2;
  inc(p3, Width);
  // koniec
  pEnd:=p2-2;
 end;
Function mapGetNextRow : Boolean;
 Begin
  pRes:=p2+1;
  a1:=p1^; a2:=(p1+1)^; a3:=(p1+2)^;
  b1:=p2^; b2:=pRes^  ; b3:=(p2+2)^;
  c1:=p3^; c2:=(p3+1)^; c3:=(p3+2)^;
  Result:= p1<pEnd;
  if Result then
   Begin
    Inc(p1);
    Inc(p2);
    Inc(p3);
   end;
 end;
// Nacitanie po Stlpcoch
Procedure mapSetColPointer( Col : Integer );
 Begin
  // nacitanie prveho riadku
  p1:=myMap;
  inc(p1, Col);
  // nacitanie druheho riadku
  p2:=p1;
  inc(p2, Width);
  // nacitanie tretieho riadku
  p3:=p2;
  inc(p3, Width);
  // koniec
  pEnd:=p1+((Height-2)*Width);
 end;
Function mapGetNextCol : Boolean;
 Begin
  pRes:=p2+1;
  a1:=p1^; a2:=(p1+1)^; a3:=(p1+2)^;
  b1:=p2^; b2:=pRes^  ; b3:=(p2+2)^;
  c1:=p3^; c2:=(p3+1)^; c3:=(p3+2)^;
  Result:= p1<pEnd;
  if Result then
   Begin
    p3:=p2;
    p2:=p1;
    Inc(p1, Width);
   end;
 end;
// ulozit farbu
Procedure mapSetColor ( Color : Byte );
 Begin
  pRes^:=Color;
 end;

// Metody - vytvorenia ciary
// cC - copper, cN - none, cL - Line, cU - Cross X
{
// metoda 1.1
Procedure mapMetode1_1 (cC, cN, cL, cU : Byte);
Var c1, c2, c3 : Byte;
    x , y , u  : Integer;
    d          : Boolean;
Begin
 Repeat
  d:=true;  // DONE
  // Z hora dole
  For Y:=1 to Height-2 do
   begin
    u:=(Height-1)-y;
    For X:=0 to Width-1 do
     Begin
       // hore -> dole
       c2:=mapPeek(x,y);
       if (c2=cN) Then
        Begin
         c1:=mapPeek(x,y+1);
         c3:=mapPeek(x,y-1);
         if ((c1=cC) or (c1=cL)) Then
          Begin  // z medi do prazdnej
            If (c3=cC) or (c3=cL)  Then mapPoke(x,y,cU)
                                   Else mapPoke(x,y,cL);
            d:=False;
          end;   // z medi do praznej
        End;
        // Dole -> Hore
        c2:=mapPeek(x,u);
        if (c2=cN) Then
         Begin
          c1:=mapPeek(x,u-1);
          c3:=mapPeek(x,u+1);
          if ((c1=cC) or (c1=cL))Then
           Begin  // z medi do prazdnej
            If (c3=cC) or (c3=cL)  Then mapPoke(x,u,cU)
                                   Else mapPoke(x,u,cL);
            d:=False;
           end;   // z medi do praznej
         End;
     End; // Slucka X
   End;   // Slucka Y
   // z boka
   For X:=1 to Width-2 do
    begin
     u:=(Width-1)-X;
     For Y:=0 to Height-1 do
      Begin
        // hore -> dole
        c2:=mapPeek(x,y);
        if (c2=cN) Then
         Begin
          c1:=mapPeek(x+1,y);
          c3:=mapPeek(x-1,y);
          if ((c1=cC) or (c1=cL)) Then
           Begin  // z medi do prazdnej
             If (c3=cC) or (c3=cL)  Then mapPoke(x,y,cU)
                                    Else mapPoke(x,y,cL);
             d:=False;
           end;   // z medi do praznej
         End;
         // Dole -> Hore
        c2:=mapPeek(u,y);
        if (c2=cN) Then
         Begin
          c1:=mapPeek(u-1,y);
          c3:=mapPeek(u+1,y);
          if ((c1=cC) or (c1=cL)) and (c2=cN) Then
            Begin  // z medi do prazdnej
              If (c3=cC) or (c3=cL)  Then mapPoke(u,y,cU)
                                     Else mapPoke(u,y,cL);
              d:=False;
            end;   // z medi do praznej
         End;
      End; // Slucka X
    End;   // Slucka Y
  //
  if mapBitmap<>nil Then mapRepaint(mapBitmap);
  application.ProcessMessages;
 Until d;
End;
// metoda 1.2
Procedure mapMetode1_2 (cC, cN, cL, cU : Byte);
Var c1, c2, c3 : Byte;
    c4, c5     : Byte;
    x , y , u  : Integer;
    d          : Boolean;

// Procedura
 Procedure mapPut( x1, y1 : Integer );
  begin
   if ((c1=cC) or (c1=cL)) Then
    Begin  // z medi do prazdnej
      if ((C4=cC) and (c5=cC)) or ((c1=cC) and (c3=cC)) then
       Begin // obkolisenie medou
        mapPoke(x1,y1,cC);
       end else begin // inac
        If ((c3=cC) or (c3=cL)) Then mapPoke(x1,y1,cU)
                                Else mapPoke(x1,y1,cL);
       end;
      d:=False;
    end;   // z medi do praznej
  End;

 // Procedura
  Procedure mapControl( x1, y1 : Integer );
   begin
    if (c1=cC) and (c2=cC) and (c3=cL) and (c4=cL) and (c5=cl) Then mapPoke(x1,y1,cL);
   End;

//
    Begin
     Repeat
      d:=true;  // DONE
      // Z hora dole
      For Y:=1 to Height-2 do
       begin
        u:=(Height-1)-y;
        For X:=1 to Width-2 do
         Begin
           // hore -> dole
           c2:=mapPeek(x,y);
             c1:=mapPeek(x,y+1);
             c3:=mapPeek(x,y-1);
             c4:=mapPeek(x-1,y);
             c5:=mapPeek(x+1,y);
           if (c2=cN) Then
            Begin
             mapPut(x,y);
            End;
           mapControl(x, y);
            // Dole -> Hore
           c2:=mapPeek(x,u);
             c1:=mapPeek(x,u-1);
             c3:=mapPeek(x,u+1);
             c4:=mapPeek(x+1,u);
             c5:=mapPeek(x-1,u);
           if (c2=cN) Then
            Begin
             mapPut(x,u);
            End;
           mapControl(x, u);
         End; // Slucka X
       End;   // Slucka Y
       // z boka
       For X:=1 to Width-2 do
        begin
         u:=(Width-1)-X;
         For Y:=1 to Height-2 do
          Begin
            // hore -> dole
            c2:=mapPeek(x,y);
              c1:=mapPeek(x+1,y);
              c3:=mapPeek(x-1,y);
              c4:=mapPeek(x,y+1);
              c5:=mapPeek(x,y-1);
            if (c2=cN) Then
             Begin
              mapPut(x,y);
             End;
            mapControl(x, y);
             // Dole -> Hore
            c2:=mapPeek(u,y);
              c1:=mapPeek(u-1,y);
              c3:=mapPeek(u+1,y);
              c4:=mapPeek(u,y+1);
              c5:=mapPeek(u,y-1);
            if (c2=cN) Then
             Begin
              mapPut(u,y);
             End;
            mapControl(u, y);
          End; // Slucka X
        End;   // Slucka Y
  //
  if mapBitmap<>nil Then mapRepaint(mapBitmap);
  //if mapBitmap<>nil Then form2.OpenPicture(mapBitmap);
  //sleep(500);
  application.ProcessMessages;
 Until d or MineForm.sStopBtn;
End;
}
// metoda 1.3
Procedure mapMetode1 (cC, cN, cL, cU : Byte);
Var x , y      : Integer;
    d          : Boolean;

// Start
 Begin
  // preprocesor. vypln diery a vymaz vyrastky
  if Form1.imgCleaner.Checked then
   Repeat
    d:=True;
    For Y:=0 to Height-3 do
     Begin
      // z Hora dole
      mapSetRowPointer(Y);
      While mapGetNextRow do
       Begin
        // vybezok medi
        If (b2=cC) Then // stredny vybezok je med
         begin
          if (c2=Cc) and (a2=cN) and (b1=cN) and (b3=cN) Then mapSetColor(cN);
          if (a2=Cc) and (c2=cN) and (b1=cN) and (b3=cN) Then mapSetColor(cN);
          if (b1=Cc) and (b3=cN) and (a2=cN) and (c2=cN) Then mapSetColor(cN);
          if (b3=Cc) and (b1=cN) and (a2=cN) and (c2=cN) Then mapSetColor(cN);
         end;
        If (b2=cN) Then // stredny vybezok je med
         begin
          if (c2=Cc) and (a2=cC) Then mapSetColor(cC);
          if (b1=cC) and (b3=cC) Then mapSetColor(cC);
         end;
        if b2<>pRes^ Then d:=false;
       end; // while
     end;   // for Y
    Until d or MineForm.sStopBtn;
   // Hlavna slucka
  Repeat
   d:=true;  // DONE
   // Horizontalne
   For Y:=0 to Height-3 do
    Begin
     // z Hora dole
     mapSetRowPointer(Y);
     While mapGetNextRow do
      Begin
         if (b2=cN) Then // Prazdny
          Begin
           if (c2=cC) or (c2=cL) then // linka, alebo med
            begin
              if (a2=cC) or (a2=cL) Then mapSetColor(cU)
               else begin  // nie je druha strana mede, alebo linky
                 if (c2=cL) and ((c1=cU) and (b1=cL)) or ((c3=cU) and (b3=cL))
                  then mapSetColor(cU)
                  else mapSetColor(cL);
                d:=False;
               end;        // nie je druha strana mede, alebo linky
            end;                      // linka, med
          end;           // prazdny
      end; // while
     // z dola hore
     mapSetRowPointer(Height-Y-3);
     While mapGetNextRow do
      Begin
         if (b2=cN) Then // Prazdny
          Begin
           if (a2=cC) or (a2=cL) then // linka, alebo med
            begin
              if (c2=cC) or (c2=cL) Then mapSetColor(cU)
               else begin  // nie je druha strana mede, alebo linky
                 if (a2=cL) and ((a1=cU) and (b1=cL)) or ((a3=cU) and (b3=cL))
                  then mapSetColor(cU)
                  else mapSetColor(cL);
                 d:=False;
               end;        // nie je druha strana mede, alebo linky
            end;                      // linka, med
          end;           // prazdny
      end; // while
     //
    end;   // for Y
   // Horizontalne
   For X:=0 to Width-3 do
    Begin
     // z lava do prava
     mapSetColPointer(X);
     While mapGetNextCol do
      Begin
         if (b2=cN) Then // Prazdny
          Begin
           if (b3=cC) or (b3=cL) then // linka, alebo med
            begin
              if (b1=cC) or (b1=cL) Then mapSetColor(cU)
               else begin  // nie je druha strana mede, alebo linky
                 if (b3=cL) and ((c2=cL) and (c3=cU)) or ((a2=cL) and (a3=cU))
                  then mapSetColor(cU)
                  else mapSetColor(cL);
                 d:=False;
               end;        // nie je druha strana mede, alebo linky
            end;                      // linka, med
          end;           // prazdny
      end; // while
     // z prava do lava
     mapSetColPointer(Width-X-3);
     While mapGetNextCol do
      Begin
         if (b2=cN) Then // Prazdny
          Begin
           if (b1=cC) or (b1=cL) then // linka, alebo med
            begin
              if (b3=cC) or (b3=cL) Then mapSetColor(cU)
               else begin  // nie je druha strana mede, alebo linky
                 if (b1=cL) and ((a1=cU) and (a2=cL)) or ((c1=cU) and (c2=cL))
                  then mapSetColor(cU)
                  else mapSetColor(cL);
                 d:=False;
               end;        // nie je druha strana mede, alebo linky
            end;                      // linka, med
          end;           // prazdny
      end; // while
     //
    end;   // for Y


   // Vykreslenie
   if mapBitmap<>nil Then mapRepaint(mapBitmap);
   //if mapBitmap<>nil Then form2.OpenPicture(mapBitmap);
   //sleep(500);
   application.ProcessMessages;
  Until d or MineForm.sStopBtn;
 End;

{
// Metoda 2.1
Procedure mapMetode2_1 (cC, cN, cL, cU : Byte; DrillPix : Integer);
Var c1, c2, c3 : Byte;
    x , y , u  : Integer;
    d          : Boolean;
    c          : Integer;
Begin
 c:=DrillPix div 2;
 if C<1 then c:=1;
 Repeat
  Dec(c);
  d:=true;  // DONE
  // Z hora dole
  For Y:=1 to Height-2 do
   begin
    u:=(Height-1)-y;
    For X:=0 to Width-1 do
     Begin
       // hore -> dole
       c1:=mapPeek(x,y+1);
       c2:=mapPeek(x,y);
       c3:=mapPeek(x,y-1);
       if ((c1=cC) or (c1=cL)) and (c2=cN) Then
        Begin  // z medi do prazdnej
          If (c3=cC) or (c3=cL) or (c=0) Then mapPoke(x,y,cU)
                                         Else mapPoke(x,y,cL);
          d:=False;
        end;   // z medi do praznej
        // Dole -> Hore
        c1:=mapPeek(x,u-1);
        c2:=mapPeek(x,u);
        c3:=mapPeek(x,u+1);
        if ((c1=cC) or (c1=cL)) and (c2=cN) Then
         Begin  // z medi do prazdnej
           If (c3=cC) or (c3=cL) or (c=0) Then mapPoke(x,u,cU)
                                          Else mapPoke(x,u,cL);
           d:=False;
         end;   // z medi do praznej
     End; // Slucka X
   End;   // Slucka Y
   // z boka
   For X:=1 to Width-2 do
    begin
     u:=(Width-1)-X;
     For Y:=0 to Height-1 do
      Begin
        // hore -> dole
        c1:=mapPeek(x+1,y);
        c2:=mapPeek(x,y);
        c3:=mapPeek(x-1,y);
        if ((c1=cC) or (c1=cL)) and (c2=cN) Then
         Begin  // z medi do prazdnej
           If (c3=cC) or (c3=cL) or (c=0) Then mapPoke(x,y,cU)
                                          Else mapPoke(x,y,cL);
           d:=False;
         end;   // z medi do praznej
         // Dole -> Hore
         c1:=mapPeek(u-1,y);
         c2:=mapPeek(u,y);
         c3:=mapPeek(u+1,y);
         if ((c1=cC) or (c1=cL)) and (c2=cN) Then
          Begin  // z medi do prazdnej
            If (c3=cC) or (c3=cL) or (c=0) Then mapPoke(u,y,cU)
                                           Else mapPoke(u,y,cL);
            d:=False;
          end;   // z medi do praznej
      End; // Slucka X
    End;   // Slucka Y
  //
  if mapBitmap<>nil Then mapRepaint(mapBitmap);
  application.ProcessMessages;
 Until d or (c=0) or MineForm.sStopBtn;
End;
}
// Metoda 2.2
Procedure mapMetode2 (cC, cN, cL, cU : Byte; DrillPix : Integer);
Var x , y      : Integer;
    d          : Boolean;
    c          : Integer;
Begin
 c:=DrillPix div 2;
 if C<1 then c:=1;
 // preprocesor. vypln diery a vymaz vyrastky
 if Form1.imgCleaner.Checked then
  Repeat
   d:=True;
   For Y:=0 to Height-3 do
    Begin
     // z Hora dole
     mapSetRowPointer(Y);
     While mapGetNextRow do
      Begin
       // vybezok medi
       If (b2=cC) Then // stredny vybezok je med
        begin
         if (c2=Cc) and (a2=cN) and (b1=cN) and (b3=cN) Then mapSetColor(cN);
         if (a2=Cc) and (c2=cN) and (b1=cN) and (b3=cN) Then mapSetColor(cN);
         if (b1=Cc) and (b3=cN) and (a2=cN) and (c2=cN) Then mapSetColor(cN);
         if (b3=Cc) and (b1=cN) and (a2=cN) and (c2=cN) Then mapSetColor(cN);
        end;
       If (b2=cN) Then // stredny vybezok je med
        begin
         if (c2=Cc) and (a2=cC) Then mapSetColor(cC);
         if (b1=cC) and (b3=cC) Then mapSetColor(cC);
        end;
       if b2<>pRes^ Then d:=false;
      end; // while
    end;   // for Y
   Until d or MineForm.sStopBtn;
  // Hlavna slucka
 Repeat
   Dec(c);
    d:=true;  // DONE
    // Horizontalne
    For Y:=0 to Height-3 do
     Begin
      // z Hora dole
      mapSetRowPointer(Y);
      While mapGetNextRow do
       Begin
          if (b2=cN) Then // Prazdny
           Begin
            if (c2=cC) or (c2=cL) then // linka, alebo med
             begin
               if (a2=cC) or (a2=cL) or (c=0) Then mapSetColor(cU)
                else begin  // nie je druha strana mede, alebo linky
                  if (c2=cL) and ((c1=cU) and (b1=cL)) or ((c3=cU) and (b3=cL))
                   then mapSetColor(cU)
                   else mapSetColor(cL);
                 d:=False;
                end;        // nie je druha strana mede, alebo linky
             end;                      // linka, med
           end;           // prazdny
       end; // while
      // z dola hore
      mapSetRowPointer(Height-Y-3);
      While mapGetNextRow do
       Begin
          if (b2=cN) Then // Prazdny
           Begin
            if (a2=cC) or (a2=cL) then // linka, alebo med
             begin
               if (c2=cC) or (c2=cL) or (c=0) Then mapSetColor(cU)
                else begin  // nie je druha strana mede, alebo linky
                  if (a2=cL) and ((a1=cU) and (b1=cL)) or ((a3=cU) and (b3=cL))
                   then mapSetColor(cU)
                   else mapSetColor(cL);
                  d:=False;
                end;        // nie je druha strana mede, alebo linky
             end;                      // linka, med
           end;           // prazdny
       end; // while
      //
     end;   // for Y
    // Horizontalne
    For X:=0 to Width-3 do
     Begin
      // z lava do prava
      mapSetColPointer(X);
      While mapGetNextCol do
       Begin
          if (b2=cN) Then // Prazdny
           Begin
            if (b3=cC) or (b3=cL) then // linka, alebo med
             begin
               if (b1=cC) or (b1=cL) or (c=0) Then mapSetColor(cU)
                else begin  // nie je druha strana mede, alebo linky
                  if (b3=cL) and ((c2=cL) and (c3=cU)) or ((a2=cL) and (a3=cU))
                   then mapSetColor(cU)
                   else mapSetColor(cL);
                  d:=False;
                end;        // nie je druha strana mede, alebo linky
             end;                      // linka, med
           end;           // prazdny
       end; // while
      // z prava do lava
      mapSetColPointer(Width-X-3);
      While mapGetNextCol do
       Begin
          if (b2=cN) Then // Prazdny
           Begin
            if (b1=cC) or (b1=cL) then // linka, alebo med
             begin
               if (b3=cC) or (b3=cL) or (c=0) Then mapSetColor(cU)
                else begin  // nie je druha strana mede, alebo linky
                  if (b1=cL) and ((a1=cU) and (a2=cL)) or ((c1=cU) and (c2=cL))
                   then mapSetColor(cU)
                   else mapSetColor(cL);
                  d:=False;
                end;        // nie je druha strana mede, alebo linky
             end;                      // linka, med
           end;           // prazdny
       end; // while
      //
     end;   // for Y


    // Vykreslenie
    if mapBitmap<>nil Then mapRepaint(mapBitmap);
    //if mapBitmap<>nil Then form2.OpenPicture(mapBitmap);
    //sleep(500);
    application.ProcessMessages;
   Until d or (c=0) or MineForm.sStopBtn;
 End;

// Metoda ncitania hodnot
// cmd :  0 - hladanie    - prve volanie
//        1 - zaciatocna suradnica
//        2 - ciara   cU (prepis ciary) -> cD (done - prepisana)
//        3 - koniec
Function  mapGetCoordinate (cU, cD : Byte; Var Cmd, X, Y : Integer; MaxPix : Integer) : Boolean;
 var aX, aY, cPix, Prev : Integer;
 Begin
  Result:=True;
  // --- Trasovanie
  if (Cmd>0) Then
   Begin // Trasovanie
    Prev:=Cmd;
    if (Cmd=1) or (cmd=10) Then Cmd:=30;
    // V pravo
    if ((Cmd=30) or (Prev=2)) and (X<(Width-1)) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x+1, y)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Inc(x);
        mapPoke(x, y, cD);
        cmd:=2;
        Prev:=0;
       End;
     end;
    // v Lavo
    if ((Cmd=30) or (Prev=3)) and (X>0) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x-1, y)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Dec(x);
        mapPoke(x, y, cD);
        cmd:=3;
        Prev:=0;
       End;
     end;
    // Dole
    if ((Cmd=30) or (Prev=4)) and (Y<(Height-1)) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x, y+1)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Inc(y);
        mapPoke(x, y, cD);
        cmd:=4;
        Prev:=0;
       End;
     end;
    // Hore
    if ((Cmd=30) or (Prev=5)) and (Y>0) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x, y-1)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Dec(y);
        mapPoke(x, y, cD);
        cmd:=5;
        Prev:=0;
       End;
     end;
    // Dole ->
    if ((Cmd=30) or (Prev=6)) and (Y<(Height-1)) and (X<(Width-1)) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x+1, y+1)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Inc(y);
        Inc(x);
        mapPoke(x, y, cD);
        cmd:=6;
        Prev:=0;
       End;
     end;
    // Hore ->
    if ((Cmd=30) or (Prev=7)) and (Y>0) and (X<(Width-1)) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x+1, y-1)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Dec(y);
        Inc(x);
        mapPoke(x, y, cD);
        cmd:=7;
        Prev:=0;
       End;
     end;
    // Dole <-
    if ((Cmd=30) or (Prev=8)) and (Y<(Height-1)) and (X>0) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x-1, y+1)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Inc(y);
        Dec(x);
        mapPoke(x, y, cD);
        cmd:=8;
        Prev:=0;
       End;
     end;
    // Hore <-
    if ((Cmd=30) or (Prev=9)) and (Y>0) and (X>0) then
     Begin
      cPix:=MaxPix;
      While (mapPeek(x-1, y-1)=cU) and (cPix>0) do
       Begin
        Dec(cPix);
        Dec(y);
        Dec(x);
        mapPoke(x, y, cD);
        cmd:=9;
        Prev:=0;
       End;
     end;
    if (Prev>1) and (Prev<10) Then Cmd:=10;
   End;  // Trasovanie
  // --- najdenie bodu
  if Cmd=0 Then   // prveho bodu
   Begin
     Result:=False;
     // hladanie
     For aY:=0 to Height-1 do
      For aX:=0 to Width-1 do
       Begin
        // najdeny
        If mapPeek(ax, ay) = cU Then
         Begin
          X:=aX;
          Y:=aY;
          mapPoke(X, Y, cD);
          Cmd:=1;
          Result:=True;
          Exit;
         End;
       End; // slucka
   end;           // prveho dodu
   // --- Vykreslenie
   //if mapBitmap<>nil Then mapRepaint(mapBitmap);
   //application.ProcessMessages;
 end;


end.

