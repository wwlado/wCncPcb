unit wNumStr;

// --------------------------------------------------------------- //
// Ill software (c) 2011 Lipany. Modul konverzie Cislo <-> Retazec //
// ----------------------------------------------------------------//

interface

uses
Classes, SysUtils;

//
// Popis procedur a funkcii
//

Var wnsResult : Boolean; // Vystup pri konverzii StrToNum. True - ak prebehla v poriadku 
    wnsNumber : QWord; 	 // Vystup pri konverzii StrToNum.
//
// Prekonvertovanie retazca na cislo. Vystup je prekonvertovane cislo
// - wnsResult ukazuje ci konverzia prebehla spravne  
// - wnsNumber zaloha vystupu konverzie.
// prefixi:
// - 193 - desiatkova sustava
// - 19D - desiatkova sustava
// - 10B - dvojkova sustava
// - 17O - osmickova sustava
// - 1FH - sestnastkova sustava
// - $1E - sestnastkova sustava  
// CisloInt:= wStrToNum ( CisloStr );
	function wStrToNum  ( S : String ) : QWord;   
// if wStrToNumB ( CisloStr ) Then x:=wnsNumber;
	function wStrToNumB ( S : String ) : Boolean;
//
// Prekonvertovanie cisla na retazec. Vystup je prekonvertovany retazec
// vystup je retazec v Hexe	
// HexStr:= wNumToHex ( CisloInt ); // vystup napr. 2f4h
    function wNumToHex ( Nu : QWord ) : String;
// vystup je retazec v Hexe. Dopisuje nuly v 2,4,8,16,32 cifrach    
// HexStr:= wNumToTabHex ( CisloInt ); // vystup napr. 02F4h
	function wNumToTabHex ( Nu : QWord ) : String;
// vystup je v desiatkovej sustave	
    function wNumToStr ( Nu : QWord ) : String;

// Vnutorne procedury
//
// priradenie znaku k cislu a opacne '0' <-> 0,...,'F' <-> 15,...
	function wnsCharEnc( Chr : Char ) : Byte;
	function wnsCharDec( Byt : Byte ) : Char;
// konverzia retazca na cilo. Zakladna funkcia
// Str    - retazec
// IndexB - zaciatok cisla v retazci
// IndexE - koniec cisla v retazci
// Sustava- Sustava
// CisloInt:= wnsConvSW ('$F23', 2, 4, 16); od druheho znaku po stvrty v 16 sustave	
	function wnsConvSW ( Str : String; IndexB, IndexE : Byte; Sustava : Byte ) : QWord;
// konverzia cislo na retazec
// Num 	  - cislo
// Sustava- Sustava
// CisloStr:= wnsConvWS ( 134, 2); prekonvertuje cislo 132 do 2 sustavy	
	function wnsConvWS ( Num : QWord; Sustava : Byte ) : String;

implementation

//
// Enkodovanie, dekodovanie znaku
//

function wnsCharEnc( Chr : Char ) : Byte;
begin
 Case Chr of
  // Dec
  '0' : wnsCharEnc:=0;
  '1' : wnsCharEnc:=1;
  '2' : wnsCharEnc:=2;
  '3' : wnsCharEnc:=3;
  '4' : wnsCharEnc:=4;
  '5' : wnsCharEnc:=5;
  '6' : wnsCharEnc:=6;
  '7' : wnsCharEnc:=7;
  '8' : wnsCharEnc:=8;
  '9' : wnsCharEnc:=9;
  // Hex
  'A' : wnsCharEnc:=10;
  'B' : wnsCharEnc:=11;
  'C' : wnsCharEnc:=12;
  'D' : wnsCharEnc:=13;
  'E' : wnsCharEnc:=14;
  'F' : wnsCharEnc:=15;
  // Ine
  'G' : wnsCharEnc:=16;
  'H' : wnsCharEnc:=17;
  'I' : wnsCharEnc:=18;
  'J' : wnsCharEnc:=19;
  'K' : wnsCharEnc:=20;
  'L' : wnsCharEnc:=21;
  'M' : wnsCharEnc:=22;
  'N' : wnsCharEnc:=23;
  'O' : wnsCharEnc:=24;
  'P' : wnsCharEnc:=25;
  'Q' : wnsCharEnc:=26;
  'R' : wnsCharEnc:=27;
  'S' : wnsCharEnc:=28;
  'T' : wnsCharEnc:=29;
  'U' : wnsCharEnc:=30;
  'V' : wnsCharEnc:=31;
  'W' : wnsCharEnc:=32;
  'X' : wnsCharEnc:=33;
  'Y' : wnsCharEnc:=34;
  'Z' : wnsCharEnc:=35;
  else  wnsCharEnc:=0;
  end;
end;

function wnsCharDec( Byt : Byte ) : Char;
begin
 Case Byt of
  // Dec
  0  : wnsCharDec:='0';
  1  : wnsCharDec:='1';
  2  : wnsCharDec:='2';
  3  : wnsCharDec:='3';
  4  : wnsCharDec:='4';
  5  : wnsCharDec:='5';
  6  : wnsCharDec:='6';
  7  : wnsCharDec:='7';
  8  : wnsCharDec:='8';
  9  : wnsCharDec:='9';
  // Hex
  10 : wnsCharDec:='A';
  11 : wnsCharDec:='B';
  12 : wnsCharDec:='C';
  13 : wnsCharDec:='D';
  14 : wnsCharDec:='E';
  15 : wnsCharDec:='F';
  // Ine
  16 : wnsCharDec:='G';
  17 : wnsCharDec:='H';
  18 : wnsCharDec:='I';
  19 : wnsCharDec:='J';
  20 : wnsCharDec:='K';
  21 : wnsCharDec:='L';
  22 : wnsCharDec:='M';
  23 : wnsCharDec:='N';
  24 : wnsCharDec:='O';
  25 : wnsCharDec:='P';
  26 : wnsCharDec:='Q';
  27 : wnsCharDec:='R';
  28 : wnsCharDec:='S';
  29 : wnsCharDec:='T';
  30 : wnsCharDec:='U';
  31 : wnsCharDec:='V';
  32 : wnsCharDec:='W';
  33 : wnsCharDec:='X';
  34 : wnsCharDec:='Y';
  35 : wnsCharDec:='Z';
  else wnsCharDec:=' ';
  end;
end;

//
// Konverzia
//

function wnsConvSW ( Str : String; IndexB, IndexE : Byte; Sustava : Byte ) : QWord;
var i : Byte;
    j : QWord;
begin
 wnsConvSW:=0;
 j		  :=1;
 For i:=IndexE DownTo IndexB Do
  begin
   wnsConvSW:= wnsConvSW+(j*wnsCharEnc(Str[i]));
   j		:= j*Sustava;
  end;
end;

function wnsConvWS ( Num : QWord; Sustava : Byte ) : String;
var i : QWord;
begin
 wnsConvWS:='';
 Repeat
  begin
   i        := Num Mod (Sustava);
   wnsConvWS:= wnsCharDec(i)+wnsConvWS;
   Num      := Num - (i);
   Num		:= Num div Sustava;
  end;
 Until Num=0; 
end;

//
// Externe procedury
//

function wStrToNum ( S : String ) : QWord;
var l : Integer;
Begin
 s:= UpperCase (s);
 l:= Length (s);
 wnsNumber:= 0;
 wnsResult:= False;
 if l>0 Then							//  dlzka je vatsia ako nula
 if (s[1]>='0') and (s[1]<='9') Then	//  prvy znak je cislo
  Begin
   if (s[l]>='0') and (s[l]<='9') Then
    begin wnsNumber:= wnsConvSW( s, 1, l, 10); wnsResult:= True; end;
   if s[l]='H' Then 
    begin wnsNumber:= wnsConvSW( s, 1, l-1, 16); wnsResult:= True; end;
   if s[l]='O' Then 
    begin wnsNumber:= wnsConvSW( s, 1, l-1, 8); wnsResult:= True; end;
   if s[l]='B' Then 
    begin wnsNumber:= wnsConvSW( s, 1, l-1, 2); wnsResult:= True; end;
   if s[l]='D' Then 
    begin wnsNumber:= wnsConvSW( s, 1, l-1, 10); wnsResult:= True; end;
  end; {Dlzka je vatsia ako nula}
  wStrToNum:= wnsNumber;
end;

function wStrToNumB ( S : String ) : Boolean; 
var l : Integer;
Begin
 s:= UpperCase (s);
 l:= Length (s);
 wnsNumber:= 0;
 wnsResult:= False;
 if l>0 Then							//  dlzka je vatsia ako nula
  begin
   if (s[1]>='0') and (s[1]<='9') Then	//  prvy znak je cislo
    Begin
     if (s[l]>='0') and (s[l]<='9') Then
      begin wnsNumber:= wnsConvSW( s, 1, l, 10); wnsResult:= True; end;
     if s[l]='H' Then 
      begin wnsNumber:= wnsConvSW( s, 1, l-1, 16); wnsResult:= True; end;
     if s[l]='O' Then 
      begin wnsNumber:= wnsConvSW( s, 1, l-1, 8); wnsResult:= True; end;
     if s[l]='B' Then 
      begin wnsNumber:= wnsConvSW( s, 1, l-1, 2); wnsResult:= True; end;
     if s[l]='D' Then 
      begin wnsNumber:= wnsConvSW( s, 1, l-1, 10); wnsResult:= True; end;
	end; {Zacina cislom}
     if s[1]='$' then 
      begin wnsNumber:= wnsConvSW( s, 2, l, 16); wnsResult:= True; end;
  end; {Dlzka je vatsia ako nula} 
  wStrToNumB:= wnsResult;
end;


function wNumToHex ( Nu : QWord ) : String;
begin
 wNumToHex := wnsConvWS( Nu, 16 )+'h';
end;

function wNumToStr ( Nu : QWord ) : String;
begin
 wNumToStr := wnsConvWS( Nu, 10 );
end;

function wNumToTabHex ( Nu : QWord ) : String;
var i : Integer;
begin
 wNumToTabHex := wnsConvWS( Nu, 16 )+'h';
 i:= Length( wNumToTabHex );
 While not ((i=3) or (i=5) or (i=9) or (i=17) or (i=33)) do 
  begin
   wNumToTabHex := '0'+wNumToTabHex;
   i:= Length( wNumToTabHex );
  end;
end;


end.
