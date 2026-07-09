unit wSerial;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Serial, Crt, wNumStr;

 {procedury}
 Procedure sInit (StrLst : TStrings);             // Iicializacia
 Function  sConnect (COMStr : String; COMSpeed : Integer) : Boolean;  // Pripoji port
 Procedure sDisconnect;                           // Odpoji port
 Function  sQuery : Boolean;                      // Data boli prijate do bufera
 Function  sRead (SepareChar : Char) : String;    // - konverzia do stringu po znak (separator)
 Function  sReadForce : String;                   // - priama konverzia do Stringu
 Procedure sSend (Text : String);                 // Odoslanie dat
 Function  sIsConnected : Boolean;                // - vracia, ked je pripojeny
 Procedure sRefreshPortList;                      // - vytvorenie listu
 //Procedure wAvrBrdReset;                          // Vynulovanie tlacidiel
 //Function wAvrBrdQuery : Boolean;                 // Prijate data z wAvrBrd -> Player


Var sDbg : TStrings;                              // spravy o pripojeni a chybach
    sEOB : Boolean;                               // Koniec bufra pri nacitani retazca
    //sPlayer1 : byte;                              // Premenne playerov
    //sPlayer2 : byte;                              // - ku kazdemu playerovy
    //sPlayer3 : byte;                              //   priradi cislo tlacidla
    //sPlayer4 : byte;
    //sPlayer5 : byte;                              // posledny player
    //sPlayer6 : byte;                              // posledny player
    //sPlayer  : char;
    //fOnlyOne : Boolean;                           // Dovoli nacitat hodnotu, iba ak je predtym 0 (iba jedna volba)
    //fBlock   : Boolean;                           // Zakaze nacitanie hodnoty (pauza)
    //fAutoReset: Boolean;                          // povolenie pustenie tlacitka
    sPortAviable : String;
    sPortArray   : Array [0..100] of String[20];
    sPortLength  : Integer;


implementation

{premenne pre pripojenie serioveho portu}
Var sDev  : String;
    sPort : TserialHandle;
    sPar  : TParityType;
    sSpeed: LongInt;
    sBit  : Integer;
    sStop : Integer;
    cnt   : Boolean;

{premenne pre prenos}
    sRdBuf : Array [0..255] of char;   // nacitaci bufer
    sRdBufP: Integer;                  // - pocet nacitanych dat
    sBuf   : Array [0..1023] of char;  // vlastny bufer
    sRdPtr : Integer;                  // - pointer citania
    sWrPtr : Integer;                  // - pointer zapisu
    sTxt   : String;                   // Vystupny text
    sMsg   : Boolean;                  // Povolenie textoveho vystupu
    //dp     : Integer;

 { Procedury }

 // Vracia status pripojenia
Function  sIsConnected : Boolean;                // - vracia, ked je pripojeny
 begin
  Result := cnt;
 end;

 // Pripojenie
 Function sConnect (COMStr : String; COMSpeed : Integer) : Boolean;
  begin
   { ak je pripojeny }
   if cnt then
    begin
     cnt := False; // stav odpojene
     if sPort <> 0 then serClose (sPort); // odpojenie portu
     if sMsg Then sDbg.Append('Odpojene.');
    end;
   { Pripojenie portu }
    sPar  := NoneParity;
    if COMSpeed=0 then sSpeed:= 115200
                  else sSpeed:= ComSpeed;
    sBit  := 8;
    sStop := 1;
    sBuf  := '';
    sDev  := COMStr;
   { Pripojenie }
    sPort := serOpen( sDev ); // Otvorenie portu
    if sPort = 0 then // overenie otvorenia portu
     begin            // - nepodarilo sa ho otvorit
      if sMsg Then sDbg.Append('Nepodarilo sa otvorit port: '+sDev+'.');
     end else begin   // - podarilo sa ho otvorit
      SerSetParams ( sPort, sSpeed, sBit, sPar, sStop, []);
      if sMsg Then sDbg.Append('Pripojeny na port: '+sDev+' ['+IntToHex(sPort, 8)+'h].');
      cnt := True;
     end;
   Result := cnt;
  end;

 // Odpojenie
 Procedure sDisconnect;
  begin
   if cnt then
    begin
     cnt := False; // stav odpojene
     if sPort <> 0 then serClose (sPort); // odpojenie portu
     if sMsg Then sDbg.Append('Odpojene.');
    end;
  end;

 // Slucka nacitania
 Function sQuery : Boolean;
  Var i, j : Integer;
  Begin
   j := sWrPtr; // zaloha
   if cnt then {ak sme pripojeny}
    begin
     sRdBufP := SerRead(sPort, sRdBuf, 256); // nacitanie udajov
     if sRdBufP>0 then
      Begin            // nacitane data
       For i:=0 to sRdBufP-1 do
        Begin          // - slucka nacitanych dat
         if sRdBuf[i] > #10 then
          begin        // ak niesu ine znaky
           sBuf[sWrPtr] := sRdBuf[i];
           inc(sWrPtr);
           if sWrPtr = 1024 then sWrPtr := 0;
           if sWrPtr = sRdPtr then if sMsg Then sDbg.Append('Preplnenie bufera.');
          end;
        end;
      end;             // nacitanie dat
    end;
   Result := ( sWrPtr <> j ); // data nacitane ak sa pointer posunul
   if Result then sEOB := False;
  End;

 {Nacitanie z bufera}
 Function sRead (SepareChar : Char) : String;
  Var p : Integer;
      ch: Char;
      e : Boolean;
      s : String;
  Begin
   e   := False; // exit
   s   := '';    // nacitany text
   p   := sRdPtr;// pointer (tienovy)
   sTxt:= '';
   {slucka}
   Repeat
    if sWrPtr<>p then // su v bufry nacitane data
     Begin
      ch:=sBuf[p];    // nacitanie znaku
      Inc(p);         // - posuv pointera
      if p = 1024 then p := 0;
      if ch<>SepareChar then
       begin           // ak nieje znak separe
        s:=s+ch;
       end else begin
        sTxt   := s;
        sRdPtr := p;
        e := True;
       end;
     end else Begin // Presiel cely buffer
       e    := True; // ukonc
       sEOB := True; // Koniec bufera
      End;
   Until e;
   Result := sTxt;
  end;
 // nacitaj vsetko
 Function sReadForce : String;
  Var p : Integer;
      ch: Char;
      e : Boolean;
      s : String;
  Begin
   e   := False; // exit
   s   := '';    // nacitany text
   p   := sRdPtr;// pointer (tienovy)
   sTxt:= '';
   {slucka}
   Repeat
    if sWrPtr<>p then // su v bufry nacitane data
     Begin
      ch:=sBuf[p];    // nacitanie znaku
      Inc(p);         // - posuv pointera
      if p = 1024 then p := 0;
      s := s + ch;
     end else begin
      e    := True; // ukonc
      sTxt := s;
     end;
   Until e;
   sRdPtr := p;
   Result := sTxt;
  end;

 {Posli text}
 Procedure sSend (Text : String);
  Begin
   if sPort<>0 then
    Begin
     sRdBufP := Length(Text);
     StrPCopy( sRdBuf, Text );
     SerWrite(sPort, sRdBuf, sRdBufP);
     SerFlush(sPort);
    End Else Begin
     if sMsg Then sDbg.Append('Nemozno odoslat data. Rozhranie nie je pripojene.');
    End;
  End;

 { inicializacia }
Procedure sInit (StrLst : TStrings);
begin
  sDbg   := TStringList.Create;
 // sDbg   := StrLst;
  cnt    := False;
  sPort  := 0;
  sRdPtr := 0;
  sWrPtr := 0;
  sMsg   := False;
  sPortAviable := '';
  sEOB   := True;
  sPortLength:=0;
  //fBlock  :=False;
  //fOnlyOne:=False;
  //fAutoReset:=False;
  // Vyhladanie portov
  //sRefreshPortList;
  sMsg   := True;
end;

// Vytvorenie listu
Procedure sRefreshPortList;
var i : Integer;
Begin
if not cnt then
 begin
  sPortAviable := '';
  sPortLength:=0;
  For i:=1 to 10 do
   Begin
    if sConnect('COM'+IntToStr(i), 115200) Then
     Begin
      sDisconnect;
      sDbg.Append(' Nájdený: COM'+IntToStr(i));
      sPortAviable := 'COM'+IntToStr(i);
      sPortArray[sPortLength]:=sPortAviable;
      Inc (sPortLength);
     end;
   end;
  // linux.. ak existuje adresar
//  if DirectoryExists('/dev') then
//   begin
    // USB
    For i:=0 to 9 do
     Begin
      if sConnect('/dev/ttyUSB'+IntToStr(i), 115200) Then
       Begin
        sDisconnect;
        sDbg.Append(' Nájdený: ttyUSB'+IntToStr(i));
        sPortAviable := '/dev/ttyUSB'+IntToStr(i);
        sPortArray[sPortLength]:=sPortAviable;
        Inc (sPortLength);
       end;
     end;
    // ACM
    For i:=0 to 9 do
     Begin
      if sConnect('/dev/ttyACM'+IntToStr(i), 115200) Then
       Begin
        sDisconnect;
        sDbg.Append(' Nájdený: ttyACM'+IntToStr(i));
        sPortAviable := '/dev/ttyACM'+IntToStr(i);
        sPortArray[sPortLength]:=sPortAviable;
        Inc (sPortLength);
       end;
     end;
    // BT
    For i:=0 to 9 do
     Begin
      if sConnect('/dev/rfcomm'+IntToStr(i), 115200) Then
       Begin
        sDisconnect;
        sDbg.Append(' Nájdený: rfcomm'+IntToStr(i));
        sPortAviable := '/dev/rfcomm'+IntToStr(i);
        sPortArray[sPortLength]:=sPortAviable;
        Inc (sPortLength);
       end;
     end;
    // COM - LINUX
//    For i:=0 to 9 do
//     Begin
//      if sConnect('/dev/ttyS'+IntToStr(i), 115200) Then
//       Begin
//        sDisconnect;
//        sDbg.Append(' Nájdený: ttyS'+IntToStr(i));
//        sPortAviable := '/dev/ttyS'+IntToStr(i);
//        sPortArray[sPortLength]:=sPortAviable;
//        Inc (sPortLength);
//       end;
//     end;
 end;
end;
 { FUNKCIE PRE wAVRBOARD
// Slucka nacitania
Function wAvrBrdQuery : Boolean;
Var i : Integer;
    j : Byte;
Begin
 Result:= False;
  if cnt then {ak sme pripojeny}
   begin
    sRdBufP := SerRead(sPort, sRdBuf, 256); // nacitanie udajov
    if sRdBufP>0 then
     Begin            // nacitane data
      For i:=0 to sRdBufP do
       Begin          // - slucka nacitanych dat
        // rozdelenie podla ovladaca
        if sRdBuf[i]='A' Then sPlayer:=sRdBuf[i];
        if sRdBuf[i]='B' Then sPlayer:=sRdBuf[i];
        if sRdBuf[i]='C' Then sPlayer:=sRdBuf[i];
        if sRdBuf[i]='D' Then sPlayer:=sRdBuf[i];
        if sRdBuf[i]='E' Then sPlayer:=sRdBuf[i];
        if sRdBuf[i]='F' Then sPlayer:=sRdBuf[i];
        // zistenie prislusneho tlacidla
        if  (sRdBuf[i]='1') or (sRdBuf[i]='2') or ((fAutoReset) and (sRdBuf[i]='0'))
         or (sRdBuf[i]='4') or (sRdBuf[i]='8') then
          begin
           // korekcia tlacidla
           j:=1;
           if sRdBuf[i]='2' then j:=2;
           if sRdBuf[i]='4' then j:=3;
           if sRdBuf[i]='8' then j:=4;
           if sRdBuf[i]='0' then j:=0;
           // priradenie tlacidla
           if (not fBlock) and (sPlayer='A') and ((sPlayer1=0) or (not fOnlyOne)) then sPlayer1:=j;
           if (not fBlock) and (sPlayer='B') and ((sPlayer2=0) or (not fOnlyOne)) then sPlayer2:=j;
           if (not fBlock) and (sPlayer='C') and ((sPlayer3=0) or (not fOnlyOne)) then sPlayer3:=j;
           if (not fBlock) and (sPlayer='D') and ((sPlayer4=0) or (not fOnlyOne)) then sPlayer4:=j;
           if (not fBlock) and (sPlayer='E') and ((sPlayer5=0) or (not fOnlyOne)) then sPlayer5:=j;
           if (not fBlock) and (sPlayer='F') and ((sPlayer6=0) or (not fOnlyOne)) then sPlayer6:=j;
           Result := True;
          end;
       end;
     end;
   end;
 End;

// Reset playerov
Procedure wAvrBrdReset;
 Begin
  sPlayer1:=0;
  sPlayer2:=0;
  sPlayer3:=0;
  sPlayer4:=0;
  sPlayer5:=0;
  sPlayer6:=0;
  sPlayer :=' ';
 end; }


end.

