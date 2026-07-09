unit wStrUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

var strData : Array [0..20] of string;   // Vysledko pri procedurach Department
    strItem : Array [0..20] of string;   // Vysledok pri procedurach DepartmentXML
    strName : String;                    // --//--
    strIsEnd: Boolean;                   // --//-- Vlajka: Najdene spatne lomitko
    strDataCount : Byte;
    strPosition  : Integer;  // pri procedure strAfter/Before / strChangeText
    strBracketLeftPos  : Integer;
    strBracketRightPos : Integer;

// Vseobecne procedury ------------------------------------- Vseobecne procedury
Function strCharCount(InStr : String; SearchChar : Char) : Integer; Overload;     // Vrati pocet znakov v retazci
Function strCharCount(InStr : String; SearchChar, SearchChar2 : Char) : Integer; Overload;     // Vrati pocet znakov v retazci
Function strChangeSlash(inStr: String; PathChar : Char) : String;                 // vymeni lomitka za PathChar
Function strRepairSlash(inStr: String; PathChar : Char) : String;                        // odstrani viacere lomitka za sebou
// Zmazat znak na pozicii
Function strDelCharInPos (inStr : String; Pos : Integer) : String;
// Vloazit znak na pozicii
Function strInsCharInPos (inStr : String; Pos : Integer; InsChar : Char) : String;
Function strInsCharInPosAndAppedZero (inStr : String; Pos : Integer; InsChar : Char) : String;

// Procedura na zmazanie medzier ---------------------------- Vycistenie retazca
Function strDelSpace(InStr : String) : String;                                    // odstrani vsetky medzery z textu
Function strDelFirstSpace(InStr : String) : String;                               // odstrani medzeru po prvy znak
Function strDelFirstSpaceAndComment(InStr : String; SepareChar : Char) : String;  // odstrani medzeru po prvy znak a komentar za znakom
Function strCompareEndOfText (InText, cmpText : String) : Boolean;                // Zisti, ci je rovnaky koniec textu
Function strGetBetweenText (InText : String; BeginChar, EndChar : Char) : String; // Vytiahne text z pomedzi dvoch znakov
Function strGetTextToChars (InText : String; Char1, Char2 : Char) : String;       // retazec po znak napr po medzeru, alebo po >
//
// Procedury rozlozenia retazca ----------------------------- Rozlozenie retazca
Procedure strDepartmentText (InText : String; sepChar1, sepChar2, sepChar3 : Char);// naplni strData rozdelenych podla separatorov
// Zistenie ci retazec zacina na znak BeginChar.
// - rozdeli retazce, podla separacneho znaku sepChar a vysledok vlozi do strData
Function strIfBeginCharADT (InText : String; BeginChar, SepChar : Char) : Boolean; // Rozdelenie retazca ak je prvy pozadovany prvy znak

//
// Adresar a subor --------------------------------------------- Adresar a subor
// Zlozenie cesty a prevedie lomitka - ak treba doda medzi retazce lomitka
// FullFileName:=CompositeFileName('C:\','teplomer\karburator','subor.txt', '/'); prevedie na LINUX/Internet
Function CompositeFileName(BaseDir, InsertDir, FileName: String; PathChar:char ) : String; // Zlozenie cesty suobru
// Prevod absolutnej adresy do relativnej
// C:\files\separe.exe C:\exe\sys.exe => "..\exe\sys.exe"
Function ConvertFileNameToRelative (OpenFile, SearchFile: String; StartDot: Boolean; SepareChar : Char) : String;
// Vymeni bazovy adresar
Function ChangeBaseDirectory (OpenFile, FileDir, ToDir: String; SepareChar : Char) : String;
// Zamen text v retazci
//
Function strChangeText (Text, srchStr, insStr : String; UCase : Boolean) : String;

// Hlada, ci sa v jednom retazci nachadza druhy retazec
// BigStr='/cnc/d.gcode' srchStr='CNC' -> True
Function strIfIn (BigStr, srchStr : String; UCase : Boolean) : Boolean;
// Zistenie, ci je retazec pred poziciou
Function strIfBefore (BigStr, srchStr : String; Pos: Integer; UCase : Boolean) : Boolean;
// Zistenie, ci je retazec za poziciou
Function strIfAfter (BigStr, srchStr : String; Pos: Integer; UCase : Boolean) : Boolean;
// Napocita pocet retazcov IncStr - pripocitava a DecStr - odpocitava hodnotu. pocita po poziciu Pos
Function strBeforeCountIn (BigStr, incStr, decStr : String; Pos: Integer; UCase : Boolean) : Integer;
// Napocita pocet retazcov IncStr - pripocitava a DecStr - odpocitava hodnotu. pocita od pozicie Pos
Function strAfterCountIn (BigStr, incStr, decStr : String; Pos: Integer; UCase : Boolean) : Integer;
// Zisti pocet retazcov v rozmedzi
Function strCountIn (BigStr, incStr, decStr : String; BeginPos, EndPos : Integer; UCase : Boolean) : Integer;

// Pre HTML procedury - hladanie zatvoriek
// - pozicia medzi zatvorkami
Function strIsBetweenBracket (Var s : String; Pos : Integer; LeftChar, RightChar : Char ): Boolean;
// - najdenie zatvorky z lavej strany
Function strPosLeftBracket (Var s : String; Pos : Integer; BracketChar : Char ): Integer;
// - najdenie zatvorky z pravej strany
Function strPosRightBracket (Var s : String; Pos : Integer; BracketChar : Char ): Integer;
// Hladanie retazca z lavej strany <..>
Function strGetLeftBracketWord (Var s : String; Pos : Integer; LeftChar, RightChar : Char ) : String;
// Hladanie retazca z pravej strany <..>
Function strGetRightBracketWord (Var s : String; Pos : Integer; LeftChar, RightChar : Char ) : String;
// Vymazanie oznaceneho textu - predoslov funkciou
Function strDelBetweenBracket (Var s : String) : Boolean;

// Zoznam suborov
// - vytvorenie zoznamu suborov
// strLoadFileList(Lines, Dir, '*.*', True, False, False);
//  - Hlada: Subory Adresare a odstrani priponu
Function strLoadFileList (strList : TStrings; Directory, SearchFilter : string; swFile, swDirectory, swExt : Boolean ) : Boolean;

// Funkcie XML
// Dekodovat retazec

implementation // ==============================================================

// Vseobecne procedury ------------------------------------- Vseobecne procedury
// Vrati pocet znakov v retazci
Function strCharCount(InStr : String; SearchChar : Char) : Integer; Overload;
Var i,j : Integer;
Begin
 j      := Length(InStr);
 Result := 0;
 for i:=1 to j do
  Begin
   if InStr[i]=SearchChar Then Result:=Result+1;
  end;
end;
// s dvoma parametrami
Function strCharCount(InStr : String; SearchChar, SearchChar2 : Char) : Integer; Overload;     // Vrati pocet znakov v retazci
Var i,j : Integer;
Begin
 j      := Length(InStr);
 Result := 0;
 for i:=1 to j do
  Begin
   if (InStr[i]=SearchChar) or (InStr[i]=SearchChar2) Then Result:=Result+1;
  end;
end;
// vymeni vsetky lomitka za PathChar
Function strChangeSlash(inStr: String; PathChar : Char) : String;                 // vymeni lomitka za PathChar
var i : Integer;
begin
  Result:=inStr;
  If (Result<>'') Then
   Begin
    For i:=1 to length(Result) do
     Begin
      If ((Result[i]='/') or (Result[i]='\')) Then Result[i]:=PathChar;
     End;
   End;
end;
// odstrani lomytka - ak su viacere za sebou a zameni ich za PathChar
Function strRepairSlash(inStr: String; PathChar : char) : String;                 // odstrani viacere lomitka za sebou
var i : Integer;
    b : Boolean;
begin
  Result := '';
  b      := False;
  If (InStr<>'') Then
   Begin
    For i:=1 to length(InStr) do
     Begin
      If ((InStr[i]='/') or (InStr[i]='\')) Then
       Begin
        If not b Then Result:=Result+PathChar;
        b := True;
       end else begin
        Result:=Result+InStr[i];
        b := False;
       end;
     End; // slucka
   End;   // podmienka
end;

// Zmazat znak na pozicii
Function strDelCharInPos (inStr : String; Pos : Integer) : String;
Var i : Integer;
 Begin
  Result:='';
  For i:=1 to Length(inStr) do
   Begin
    if Pos<>i Then Result:=Result+inStr[i];
   end;
 end;
// Vloazit znak na pozicii
Function strInsCharInPos (inStr : String; Pos : Integer; InsChar : Char) : String;
Var i : Integer;
 Begin
  Result:='';
  For i:=1 to Length(inStr) do
   Begin
    if Pos=i Then Result:=Result+InsChar;
    Result:=Result+inStr[i];
   end;
 end;
// Float - korekcia
// Vlozi ciarku. ak je ciarka pred retazcom, vlozi tam nuly
Function strInsCharInPosAndAppedZero (inStr : String; Pos : Integer; InsChar : Char) : String;
Var i, l : Integer;
 Begin
  Result:='';
  l:=Length(inStr);
  if pos<=l Then
   Begin
    For i:=0 to (l-pos) do inStr:='0'+inStr;
   end;
  l:=Length(inStr);
  pos:=l-pos;
  For i:=1 to l do
   Begin
    if Pos=i Then Result:=Result+InsChar;
    Result:=Result+inStr[i];
   end;
 end;


// Vycistenie retazca --------------------------------------- Vycistenie retazca
// Procedura na odstranenie medzier
Function strDelSpace(InStr : String) : String;
 Var i,j : Integer;
 Begin
  j      := Length(InStr);
  Result := '';
  for i:=1 to j do
   Begin
    if InStr[i]<>#32 Then Result:=Result+InStr[i];
   end;
 end;

// Procedura na odstranenie medzier zo zaciatku
Function strDelFirstSpace(InStr : String) : String;
 Var i,j : Integer;
       b : Boolean;
 Begin
  j      := Length(InStr);
  b      := False;
  Result := '';
  for i:=1 to j do
   Begin
    if (InStr[i]<>#32) or b Then
     Begin
       Result := Result+InStr[i];
       b      := True;
     End;
   end;
 end;

// Procedura na odstranenie medzier zo zaciatku a poznamky za znakom (v ratane)
Function strDelFirstSpaceAndComment(InStr : String; SepareChar : Char) : String;
 Var i,j : Integer;
     c,b : Boolean;
 Begin
  j      := Length(InStr);
  b      := False;
  c      := True;
  Result := '';
  for i:=1 to j do
   Begin
    if ((InStr[i]<>#32) or b) and c Then
     Begin
       if InStr[i]=SepareChar Then c:=False
        else Begin
         Result := Result+InStr[i];
         b      := True;
        end;
     End;
   end;
 end;

// Porovna koniec textu
Function strCompareEndOfText (InText, cmpText : String) : Boolean;
Var i,j,k : Integer;
Begin
 j      := Length(InText);
 k      := Length(cmpText);
 Result := False;
 If (k<=j) and (j>0) and (k>0) Then
  Begin
   j:= j-k;
   Result:=True;
   // slucka
   For i:=1 to k do
    Begin
     if (cmpText[i]<>inText[j+i]) Then Result:=False;
    End;// koniec - slucky
  End;  // koniec - podmienky ci je vacsi text
end;

// Vytiahni retazec medzi znakmi
Function strGetBetweenText (InText : String; BeginChar, EndChar : Char) : String;
Var i,j : Integer;
      c : Boolean;
Begin
 j      := Length(InText);
 c      := False;
 Result := '';
  // slucka
  For i:=1 to j do
   Begin
    if EndChar   = inText[i] Then c:=False;
    if c Then Result:=Result+inText[i];
    if BeginChar = inText[i] Then c:=True;
   End;// koniec - slucky
end;

// Vrat text, po znaky
Function strGetTextToChars (InText : String; Char1, Char2 : Char) : String;
Var i,j : Integer;
      c : Boolean;
Begin
 j      := Length(InText);
 c      := True;
 Result := '';
  // slucka
  For i:=1 to j do
   Begin
    if c and (InText[i]<>Char1) and (InText[i]<>Char2) Then Result:=Result+InText[i]
                                                       Else c:=False;
   End;// koniec - slucky
end;

// ----------------------------------------------------------- Oddelenie retazca
// Oddel text do strData podla oddelocavov sepCha
Procedure strDepartmentText (InText : String; sepChar1, sepChar2, sepChar3 : Char);
Var i   : Integer;
    s   : String;
Begin
 S            := '';
 strDataCount := 0;
  // slucka
  For i:=1 to Length(InText) do
   Begin
    if (inText[i]=sepChar1) or (inText[i]=sepChar2) or (inText[i]=sepChar3) Then
     Begin
      strData[strDataCount]:=s;
      inc(strDataCount);
      s:='';
     End else Begin
      s:=s+inText[i];
     End;
   End;// koniec - slucky
  // posledny text
 if s<>'' Then
  Begin
   strData[strDataCount]:=s;
   inc(strDataCount);
  end;
end;
// Zistenie ci retazec zacina na znak BeginChar.
// - rozdeli retazce, podla separacneho znaku sepChar a vysledok vlozi do strData
// Retazec: $Param1|Param2|Param3|EndParam -> Rozmozi do strData a pocet do strDataCount
Function strIfBeginCharADT (InText : String; BeginChar, SepChar : Char) : Boolean;
Var i   : Integer;
    s   : String;
Begin
 Result:=False;
 strDataCount:=0;
 If Length(InText)>2 Then
 If InText[1]=BeginChar Then
  Begin
  Result := True;
  S      := '';
  // slucka
  For i:=2 to Length(InText) do
   Begin
    if (inText[i]=sepChar) Then
     Begin
      strData[strDataCount]:=s;
      inc(strDataCount);
      s:='';
     End else Begin
      s:=s+inText[i];
     End;
   End;// koniec - slucky
   // nakoniec
    if s<>'' Then
     Begin
      strData[strDataCount]:=s;
      inc(strDataCount);
     end;
  End; // koniec IF
end;

// Zlozenie cesty a prevedie lomitka
Function CompositeFileName(BaseDir, InsertDir, FileName: String; PathChar:char ) : String;
 var i : Integer;
 Begin
  Result:=BaseDir;
  // napojenie na prvu cestu
  If (Result<>'') and (InsertDir<>'') Then
   Begin
    i:=length(Result);
    if not ((Result[i]='/') or (Result[i]='\')) Then Result:=Result+PathChar;
   End;
  Result:=Result+InsertDir;
  // napojenie suboru
  If (Result<>'') and (FileName<>'') Then
   Begin
    i:=length(Result);
    if not ((Result[i]='/') or (Result[i]='\')) Then Result:=Result+PathChar;
   End;
  Result:=Result+FileName;
  // Prekonvertovanie znakov
  If (Result<>'') Then
   Begin
    For i:=1 to length(Result) do
     Begin
      If ((Result[i]='/') or (Result[i]='\')) Then Result[i]:=PathChar;
     End;
   End;
 end;

// Prevod absolutnej adresy do relativnej
Function ConvertFileNameToRelative (OpenFile, SearchFile: String; StartDot: Boolean; SepareChar : Char) : String;
Var i,j,ofl, sfl : Integer;
    p            : Integer;
    b            : Boolean;
    s,  ofn, sfn : String;
Begin
 s   := '';
 p   := 0;
 b   := True;
 ofn := UpperCase(OpenFile);
 sfn := UpperCase(SearchFile);
 ofl := Length(ofn);
 sfl := Length(sfn);
 j   := ofl;
 if j>sfl Then j:=sfl;
 // odstranenie rovnakej caste retazca
 For i:=1 To j do
  Begin
   if b and (ofn[i] = sfn[i]) Then
    Begin
     if (ofn[i]='/') or (ofn[i]='\') Then p:=i;
    end else b:=false;
  end;
 // kopirovanie koncov retazcov
 ofn  := '';
 if p<ofl Then
  For i:=(p+1) to ofl do
   Begin
    ofn:= ofn + OpenFile[i];
   end;
 sfn  := '';
 if p<sfl Then
  For i:=(p+1) to sfl do
   Begin
    sfn:= sfn + SearchFile[i];
   end;
 // Hladanie rozdielov
  ofl := StrCharCount(ofn, '/', '\');
  if ofl=0 Then
   Begin
    if Startdot then s:='.'+SepareChar
                else s:='';
   end else begin
    For i:=1 to ofl do
     s:=s+'..'+SepareChar;
   end;
  s := s + sfn;
  if openFile='' Then s:=SearchFile;
  Result:=strRepairSlash(s, SepareChar);
end;

// Vymena bazy adresy
Function ChangeBaseDirectory (OpenFile, FileDir, ToDir: String; SepareChar : Char) : String;
Var i,j,ofl, sfl : Integer;
    p            : Integer;
    b            : Boolean;
    ofn, sfn     : String;
Begin
 //s   := '';
 p   := 0;
 b   := True;
 ofn := UpperCase(OpenFile);
 sfn := UpperCase(FileDir);
 ofl := Length(ofn);
 sfl := Length(sfn);
 if (sfn[sfl]<>'/') And (sfn[sfl]<>'\') Then
  Begin
   sfn:=sfn+SepareChar;
   Inc(sfl);
  end;
 j   := ofl;
 if j>sfl Then j:=sfl;
 // odstranenie rovnakej caste retazca
 For i:=1 To j do
  Begin
   if b and ((ofn[i] = sfn[i]) or (((ofn[i] = '/') or (ofn[i] = '\')) and ((sfn[i] = '/') or (sfn[i] = '\')))) Then
    Begin
     if ((ofn[i]='/') or (ofn[i]='\')) Then p:=i;
    end else b:=false;
  end;
 // kopirovanie koncov retazcov
 ofn  := '';
 if p<ofl Then
  For i:=(p+1) to ofl do
   Begin
    ofn:= ofn + OpenFile[i];
   end;
  // spojenie
  Result:=CompositeFileName(ToDir, '', ofn, SepareChar);
end;

// Hlada, ci sa v jednom retazci nachadza druhy retazec
// - Pouzite pri vyhladavani - prazny srchStr -> TRUE (prazny vyhladavaci retazec znamena vsetky vysledky)
Function strIfIn (BigStr, srchStr : String; UCase : Boolean) : Boolean;
 Var a,s     : String;
     i,j,p,l : Integer;
 Begin
  Result := False;
  // nastavenie retazcov
  if UCase Then
   Begin
    a:=UpperCase(srchStr);
    s:=UpperCase(BigStr);
   end else Begin
    a:=srchStr;
    s:=BigStr;
   end;
  // porovnanie velkosti
  l:=Length(a);
  j:=Length(s);
  if l=0 Then Result:=True;
  if (l>0) and (j>0) and (j>=l) Then
   Begin
    p:=1;
    For i:=1 to j do // Slucka
     Begin
      if s[i]=a[p] Then  // ak su rovnake znaky
       Begin
        Inc(p);
        if p>l Then
         Begin
          Result:=True;
          p:=1;
         End;
       end else p:=1;    // ak niesu rovnake znaky
      // Koniec slucky
     end;
   end;
 end;
// Zistenie, ci je retazec pred poziciou
Function strIfBefore (BigStr, srchStr : String; Pos: Integer; UCase : Boolean) : Boolean;
 Var a,s     : String;
     i,j,p,l : Integer;
 Begin
  Result := False;
  strPosition :=0;
  // nastavenie retazcov
  if UCase Then
   Begin
    a:=UpperCase(srchStr);
    s:=UpperCase(BigStr);
   end else Begin
    a:=srchStr;
    s:=BigStr;
   end;
  // porovnanie velkosti
  l:=Length(a);
  j:=Length(s);
  //if l=0 Then Result:=True;  - TRUE pri prazdnom retazci
  if (l>0) and (j>0) and (j>=l) and (Pos>0) and (Pos<=j) Then
   Begin
    p:=1;
    For i:=1 to Pos do // Slucka
     Begin
      if s[i]=a[p] Then  // ak su rovnake znaky
       Begin
        Inc(p);
        if p>l Then
         Begin
          Result:=True;
          strPosition:=i;
          p:=1;
         End;
       end else p:=1;    // ak niesu rovnake znaky
      // Koniec slucky
     end;
   end;
 end;
// Zistenie, ci je retazec za poziciou
Function strIfAfter (BigStr, srchStr : String; Pos: Integer; UCase : Boolean) : Boolean;
 Var a,s     : String;
     i,j,p,l : Integer;
 Begin
  Result := False;
  strPosition:= 0;
  // nastavenie retazcov
  if UCase Then
   Begin
    a:=UpperCase(srchStr);
    s:=UpperCase(BigStr);
   end else Begin
    a:=srchStr;
    s:=BigStr;
   end;
  // porovnanie velkosti
  l:=Length(a);
  j:=Length(s);
  //if l=0 Then Result:=True;  - TRUE pri prazdnom retazci
  if (l>0) and (j>0) and (j>=l) and (Pos>0) and (Pos<=j) Then
   Begin
    p:=1;
    For i:=Pos to j do // Slucka
     Begin
      if s[i]=a[p] Then  // ak su rovnake znaky
       Begin
        Inc(p);
        if p>l Then
         Begin
          Result:=True;
          strPosition:=i;
          p:=1;
         End;
       end else p:=1;    // ak niesu rovnake znaky
      // Koniec slucky
     end;
   end;
 end;
// Zisti pocet retazcov po poziciu
Function strBeforeCountIn (BigStr, incStr, decStr : String; Pos: Integer; UCase : Boolean) : Integer;
 Var ai, ad, s : String;
     i,j       : Integer;
     li, pi    : Integer;
     ld, pd    : Integer;
 Begin
  Result := 0;
  // nastavenie retazcov
  if UCase Then
   Begin
    ai:=UpperCase(incStr);
    ad:=UpperCase(decStr);
    s:=UpperCase(BigStr);
   end else Begin
    ai:=incStr;
    ad:=decStr;
    s :=BigStr;
   end;
  // porovnanie velkosti
  li:=Length(ai);
  ld:=Length(ad);
  j :=Length(s);
  // if (li=0) and (ld=0) Then Result:=True; Pazdny retazec -> True
  if (li>0) and (ld>0) and  (j>0) and (j>=li) and (j>=ld) and (Pos>0) and (Pos<=J) Then
   Begin
    pi:=1;
    pd:=1;
    For i:=1 to Pos do // Slucka
     Begin
      // retazec pripocitania
      if s[i]=ai[pi] Then  // ak su rovnake znaky
       Begin
        Inc(pi);
        if pi>li Then
         Begin
          Inc(Result);
          pi:=1;
         End;
       end else pi:=1;    // ak niesu rovnake znaky
       // retazec odpocitania
       if s[i]=ad[pd] Then  // ak su rovnake znaky
        Begin
         Inc(pd);
         if pd>ld Then
          Begin
           Dec(Result);
           pd:=1;
          End;
        end else pd:=1;    // ak niesu rovnake znaky
      // Koniec slucky
     end;
   end;
 end;
// Zisti pocet retazcov od poziciu
Function strAfterCountIn (BigStr, incStr, decStr : String; Pos: Integer; UCase : Boolean) : Integer;
 Var ai, ad, s : String;
     i,j       : Integer;
     li, pi    : Integer;
     ld, pd    : Integer;
 Begin
  Result := 0;
  // nastavenie retazcov
  if UCase Then
   Begin
    ai:=UpperCase(incStr);
    ad:=UpperCase(decStr);
    s:=UpperCase(BigStr);
   end else Begin
    ai:=incStr;
    ad:=decStr;
    s :=BigStr;
   end;
  // porovnanie velkosti
  li:=Length(ai);
  ld:=Length(ad);
  j :=Length(s);
  // if (li=0) and (ld=0) Then Result:=True; Pazdny retazec -> True
  if (li>0) and (ld>0) and  (j>0) and (j>=li) and (j>=ld) and (Pos>0) and (Pos<=J) Then
   Begin
    pi:=1;
    pd:=1;
    For i:=Pos to j do // Slucka
     Begin
      // retazec pripocitania
      if s[i]=ai[pi] Then  // ak su rovnake znaky
       Begin
        Inc(pi);
        if pi>li Then
         Begin
          Inc(Result);
          pi:=1;
         End;
       end else pi:=1;    // ak niesu rovnake znaky
       // retazec odpocitania
       if s[i]=ad[pd] Then  // ak su rovnake znaky
        Begin
         Inc(pd);
         if pd>ld Then
          Begin
           Dec(Result);
           pd:=1;
          End;
        end else pd:=1;    // ak niesu rovnake znaky
      // Koniec slucky
     end;
   end;
 end;
// Zisti pocet retazcov v rozmedzi
Function strCountIn (BigStr, incStr, decStr : String; BeginPos, EndPos : Integer; UCase : Boolean) : Integer;
 Var ai, ad, s : String;
     i,j       : Integer;
     li, pi    : Integer;
     ld, pd    : Integer;
 Begin
  Result := 0;
  // nastavenie retazcov
  if UCase Then
   Begin
    ai:=UpperCase(incStr);
    ad:=UpperCase(decStr);
    s:=UpperCase(BigStr);
   end else Begin
    ai:=incStr;
    ad:=decStr;
    s :=BigStr;
   end;
  // porovnanie velkosti
  li:=Length(ai);
  ld:=Length(ad);
  j :=Length(s);
  // if (li=0) and (ld=0) Then Result:=True; Pazdny retazec -> True
  if (li>0) and (ld>0) and  (j>0) and (j>=li) and (j>=ld) and (BeginPos<=EndPos) And
     (BeginPos>0) and (BeginPos<=J) and (EndPos>0) and (EndPos<=J) Then
   Begin
    pi:=1;
    pd:=1;
    For i:=BeginPos to EndPos do // Slucka
     Begin
      // retazec pripocitania
      if s[i]=ai[pi] Then  // ak su rovnake znaky
       Begin
        Inc(pi);
        if pi>li Then
         Begin
          Inc(Result);
          pi:=1;
         End;
       end else pi:=1;    // ak niesu rovnake znaky
       // retazec odpocitania
       if s[i]=ad[pd] Then  // ak su rovnake znaky
        Begin
         Inc(pd);
         if pd>ld Then
          Begin
           Dec(Result);
           pd:=1;
          End;
        end else pd:=1;    // ak niesu rovnake znaky
      // Koniec slucky
     end;
   end;
 end;

// Pre HTML
// - Zistenie, ci sme medzi zatvorkami   <>
Function strIsBetweenBracket (Var s : String; Pos : Integer; LeftChar, RightChar : Char ): Boolean;
Var i, l   : Integer;
    bl, br : Boolean;
 Begin
  bl := False;
  br := False;
  l  := Length(s);
  if (Pos<=l) or (Pos>0) then
   Begin
    i:=Pos-1;
    // hladanie spat
    While ((i>0) and (s[i]<>RightChar) and (Not bl)) do
     Begin
      bl:=(s[i]=LeftChar);
      Dec(i);
     end;
    // hladanie vpred
    i:=Pos;
    While ((i<=l) and (s[i]<>LeftChar) and (Not br)) do
     Begin
      br:=(s[i]=RightChar);
      Inc(i);
     end;
    // Celkove porovnanie
    Result := (br and bl);
   end;
 end;
// najdenie zatvorky z lavej strany
Function strPosLeftBracket (Var s : String; Pos : Integer; BracketChar : Char ): Integer;
Var i, l   : Integer;
    b      : Boolean;
 Begin
  Result := 0;
  b  := False;
  l  := Length(s);
  if (Pos<=l) or (Pos>0) then
   Begin
    i:=Pos-1;
    // hladanie spat
    While ((i>0) and (Not b)) do
     Begin
      b:=(s[i]=BracketChar);
      if b Then Result := i;
      Dec(i);
     end;
   end;
  strBracketLeftPos:=Result;
 end;
// najdenie zatvorky z pravej strany
Function strPosRightBracket (Var s : String; Pos : Integer; BracketChar : Char ): Integer;
Var i, l   : Integer;
    b      : Boolean;
 Begin
  Result := 0;
  b  := False;
  l  := Length(s);
  if (Pos<=l) or (Pos>0) then
   Begin
    i:=Pos;
    // hladanie spat
    While ((i<=l) and (Not b)) do
     Begin
      b:=(s[i]=BracketChar);
      if b Then Result := i;
      Inc(i);
     end;
   end;
   strBracketRightPos:=Result;
 end;

// Kombinovane operacie
// Hladanie retazca z lavej strany <..>
Function strGetLeftBracketWord (Var s : String; Pos : Integer; LeftChar, RightChar : Char ) : String;
 Var i : Integer;
 Begin
  Result:='';
  if (strPosLeftBracket (s, Pos              , LeftChar )>0) and
     (strPosRightBracket(s, strBracketLeftPos, RightChar)>0) then
      Begin
       // vytvory retazec
       For i:=strBracketLeftPos to strBracketRightPos do
        Begin
         Result:=Result+s[i];
        end;
      end;
 end;
// Hladanie retazca z lavej strany <..>
Function strGetRightBracketWord (Var s : String; Pos : Integer; LeftChar, RightChar : Char ) : String;
 Var i : Integer;
 Begin
  Result:='';
  if (strPosRightBracket (s, Pos               , RightChar)>0) and
     (strPosLeftBracket  (s, strBracketRightPos, LeftChar )>0) then
      Begin
       // vytvory retazec
       For i:=strBracketLeftPos to strBracketRightPos do
        Begin
         Result:=Result+s[i];
        end;
      end;
 end;
// Vymaz medzi zatvorakmi - navezne na predchadzajuce procedury
Function strDelBetweenBracket (Var s : String) : Boolean;
 begin
  Result:= (strBracketLeftPos>0) and (strBracketRightPos>0) and (strBracketLeftPos<=strBracketRightPos);
  if Result Then Delete(s, strBracketLeftPos, strBracketRightPos-strBracketLeftPos+1);
 end;

// Zamen text v retazci
// - v Texte zmeni srchStr na insStr
Function strChangeText (Text, srchStr, insStr : String; UCase : Boolean) : String;
 Var a,s,q,w : String;
     i,j,p,l : Integer;

 Begin
  Result:=Text;
  q:='';
  w:='';
  strPosition:=0;
  // nastavenie retazcov
  if UCase Then
   Begin
    a:=UpperCase(srchStr);
    s:=UpperCase(Text);
   end else Begin
    a:=srchStr;
    s:=Text;
   end;
  // porovnanie velkosti
  l:=Length(a);
  j:=Length(s);
  if (l>0) and (j>0) and (j>=l) Then
   Begin
    p:=1;
    For i:=1 to j do // Slucka
     Begin
      if s[i]=a[p] Then  // ak su rovnake znaky
       Begin
        w:=w+Text[i];
        Inc(p);
        if p>l Then
         Begin
          w:='';
          p:=1;
          strPosition:=Length(q)+1;
          q:=q+insStr;
         End;
       end else begin // ak niesu rovnake znaky
        p:=1;
        if w<>'' Then q:=q+w;
        q:=q+Text[i];
        w:='';
       end;
      // Koniec slucky
     end;
   end;
  if q<>'' Then Result:=q;
 end;

// Zoznam suborov
// - vytvorenie zoznamu suborov
Function strLoadFileList (strList : TStrings; Directory, SearchFilter : string; swFile, swDirectory, swExt : Boolean ) : Boolean;
Var sr   : TSearchRec;
    ss   : String;
Begin
 ss:=CompositeFileName(Directory, '', SearchFilter, '\');
 strList.Clear;
 // Adresar
 if (FindFirst(ss, faAnyFile, SR)=0) Then {vytvorenie listu}
   Repeat    // Adresare
    If ((sr.Attr and faDirectory) = faDirectory) and
       ((sr.Name<>'.') and (sr.Name<>'..')) and swDirectory Then
     Begin
      //strList.Append(sr.Name);
      if swExt then strList.Append(sr.Name)
               else strList.Append(ChangeFileExt(sr.Name, ''));
     end;
   Until FindNext(sr)<>0;
  FindClose(sr);
  // Subor
  If FindFirst(ss, faAnyFile, SR)=0 Then
   Repeat
    If ((sr.Attr and faDirectory) <> faDirectory) and
       swFile Then
     Begin
      //strList.Append(sr.Name);
      if swExt then strList.Append(sr.Name)
               else strList.Append(ChangeFileExt(sr.Name, ''));
     end;
    Until FindNext(sr)<>0;
  FindClose(sr);
  Result:=(strList.Count>0);
End;

// XML procedury
// - Nacitanie XML riadku
function strDepartmentXML (Str : String) : Boolean;
var I : Integer;
 Begin

 end;

// koniec kniznice ===
end.

