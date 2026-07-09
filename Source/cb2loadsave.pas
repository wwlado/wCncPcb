unit cb2LoadSave;
//
// Kniznica ulozenia dbAtomov a komponentov TForm
//
// Visnovsky 28.11.2024
//

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, cb2Atom, cb2Graphics, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls, Spin, Buttons;

// Procedury
Procedure dbSave (fName : String);
Procedure dbLoad (fName : String); Overload;
Procedure dbLoad (fName : String; dbAtom : TAtomDatabase); Overload;
Procedure SaveSettings (Sender : TObject);
Procedure LoadSettings(Sender : TObject);
Procedure SaveLNG (Sender : TObject);
Procedure LoadLNG (Sender : TObject);

// premenne
Var sComponentType, sComponentParam : Integer;
// Konstanty
Const  tMetaData   = 255;              // Typ - o datovej strukture
       CfgFile     = 'wCncPcb2.cfg';   // Typ - suboru
       LngFile     = 'wCncPcb2.lng';   // Typ - suboru

implementation
 Uses MineForm;


 // Premenne
 Var LineStr   : String;                // Riadok - Text
     LinePtr   : Integer;               // Riadok - pointer
     LineLen   : Integer;               // Riadok - dlzka

// Procedury na obsluhu riadku
// - Nacitanie riadku
Procedure ReadLine (Txt: String);
 Begin
  LineStr := Txt;
  LinePtr := 1;
  LineLen := Length(Txt);
 end;
// - Rozlozenie riadku
Function GetText : String;
var NoDone : Boolean;
 begin
  Result := '';
  NoDone := True;
  While ((LinePtr <= LineLen) and NoDone) do
   Begin
    if (LineStr[LinePtr] = '|') Then NoDone := False
                                else Result := Result+LineStr[LinePtr];
    inc(LinePtr);
   end;
 end;
// Vytvorenie retazca
Function DataToLine (Typ, Layer, X, Y, ToX, ToY, R, G : Integer; Name : String) : String;
 Begin
  Result :=          IntToStr(Typ)  + '|' + IntToStr(Layer) + '|';
  Result := Result + IntToStr(X)    + '|' + IntToStr(Y)     + '|';
  Result := Result + IntToStr(ToX)  + '|' + IntToStr(ToY)   + '|';
  Result := Result + IntToStr(R)    + '|' + IntToStr(G)     + '|' + Name + '|';
 end;
Function AtomToLine (Atm : pAtom) : String;
 Begin
  Result :=          IntToStr(Atm^.Typ)  + '|' + IntToStr(Atm^.Layer) + '|';
  Result := Result + IntToStr(Atm^.X)    + '|' + IntToStr(Atm^.Y)     + '|';
  Result := Result + IntToStr(Atm^.ToX)  + '|' + IntToStr(Atm^.ToY)   + '|';
  Result := Result + IntToStr(Atm^.R)    + '|' + IntToStr(Atm^.Group)     + '|' + Atm^.Name + '|';
 end;

// Ulozenie databazy
Procedure dbSave (fName : String);
 Var f : TStrings;
 Begin
  f := TStringList.Create;
  f.Append('Type |Layer|  X  |  Y  | ToX | ToY |  R  | Name|');
  // Vlozenie hlavicky
  f.Append(DataToLine( tMetaData, 0, iWidth, iHeight, iOffsetX, iOffsetY, sComponentType, sComponentParam, ExtractFileName(fName) ));
  // Vlozenie udajov z databazy
  aFirst;
  Repeat
   if Atom<>Nil Then              // Ak atom existuje
    Begin
     f.Append(AtomToLine( Atom ));// - uloz
    end;
  Until Not aNext;
  f.SaveToFile(fName);  // Ulozit databazu
  f.Free;
 end;
// Nacitanie databazy
Procedure dbLoad (fName : String); Overload;
 Var f : TStrings;
     Ok: Boolean;
     aX,aToX,aY,aToy, aR : Integer;
     aTyp, aLayer, i, aG : Integer;
     btxt                : String; // text podla starej verzie
     bIsNum              : Boolean;

 Begin
  If FileExists(fName) Then
   Begin
    f:=TStringList.Create;
    aAllDelete;
    f.LoadFromFile(fName);
    if f.Count>1 Then
     For i:=1 to f.Count-1 do
      Begin
       // Nacitanie riadku
       ReadLine( f.Strings[i] );
       Ok := True;
       // Dekodovanie hodnot
       if TryStrToInt(GetText,aTyp)   = False Then Ok:=False;
       if TryStrToInt(GetText,aLayer) = False Then Ok:=False;
       if TryStrToInt(GetText,aX)     = False Then Ok:=False;
       if TryStrToInt(GetText,aY)     = False Then Ok:=False;
       if TryStrToInt(GetText,aToX)   = False Then Ok:=False;
       if TryStrToInt(GetText,aToY)   = False Then Ok:=False;
       if TryStrToInt(GetText,aR)     = False Then Ok:=False;
        bTxt  := GetText;
        bIsNum:= TryStrToInt(bTxt,aG);
       if bIsNum                      = False Then aG:=0; // kompaktibilita s predoslou verziou
       // Delenie
       // - Metadata
       if Ok and (aTyp = tMetaData ) Then
        Begin
         iWidth  := aX;
         iHeight := aY;
         Form1.setWidthChange(iWidth, iHeight);
         iOffsetX:= aToX;
         iOffsetY:= aToY;
         Form1.setOffsetChange(iOffsetX, iOffsetY);
         sComponentType := aR;
         sComponentParam:= aG;
        End;
       // - Udaje
       if Ok and (aTyp <> tMetaData ) Then
        Begin
         If bIsNum Then aAppend( aTyp, aLayer, aX, aY, aToX, aToY, aR, aG, GetText )
                   Else aAppend( aTyp, aLayer, aX, aY, aToX, aToY, aR,  0, bTxt ); // kompaktibilita so starou verziou
        End;
      end;
    f.Free;
   end;
 end;
// Nacitanoie databazy do objektu
Procedure dbLoad (fName : String; dbAtom : TAtomDatabase); Overload;
 Var f : TStrings;
     Ok: Boolean;
     aX,aToX,aY,aToy, aR : Integer;
     aTyp, aLayer, i, aG : Integer;
     btxt                : String; // text podla starej verzie
     bIsNum              : Boolean;

 Begin
  If FileExists(fName) Then
   Begin
    f:=TStringList.Create;
    f.LoadFromFile(fName);
    if f.Count>1 Then
     For i:=1 to f.Count-1 do
      Begin
       // Nacitanie riadku
       ReadLine( f.Strings[i] );
       Ok := True;
       // Dekodovanie hodnot
       if TryStrToInt(GetText,aTyp)   = False Then Ok:=False;
       if TryStrToInt(GetText,aLayer) = False Then Ok:=False;
       if TryStrToInt(GetText,aX)     = False Then Ok:=False;
       if TryStrToInt(GetText,aY)     = False Then Ok:=False;
       if TryStrToInt(GetText,aToX)   = False Then Ok:=False;
       if TryStrToInt(GetText,aToY)   = False Then Ok:=False;
       if TryStrToInt(GetText,aR)     = False Then Ok:=False;
        bTxt  := GetText;
        bIsNum:= TryStrToInt(bTxt,aG);
       if bIsNum                      = False Then aG:=0; // kompaktibilita s predoslou verziou
       // Delenie
       // - Metadata
       //if Ok and (aTyp = tMetaData ) Then
       // Begin
         //iWidth  := aX;
         //iHeight := aY;
         //iOffsetX:= aToX;
         //iOffsetY:= aToY;
       // End;
       // - Udaje
       if Ok {and (aTyp <> tMetaData )} Then
        Begin
         If bIsNum Then dbAtom.Append( aTyp, aLayer, aX, aY, aToX, aToY, aR, aG, GetText )
                   Else dbAtom.Append( aTyp, aLayer, aX, aY, aToX, aToY, aR,  0, bTxt ); // kompaktibilita so starou verziou
        End;
      end;
    f.Free;
   end;
 end;


// ------------------------------------------------------------------- Ulozenie nastaveni
// ulozenie nastaveni
Procedure SaveSettings (Sender : TObject);
Var f : TStrings;
    i : Integer;

  Procedure SaveObject (Sender : TObject);
  var l : Integer;
  Begin
   if Sender is TFloatSpinEdit then // TFolatSpinEdit
     Begin
      f.Append(' { '+(Sender as TFloatSpinEdit).Name+' }');
      f.Append((Sender as TFloatSpinEdit).Text);
     end;
   if Sender is TSpinEdit then // TSpinEdit
     Begin
      f.Append(' { '+(Sender as TSpinEdit).Name+' }');
      f.Append((Sender as TSpinEdit).Text);
     end;
   if Sender is TEdit then // TEdit
     Begin
      f.Append(' { '+(Sender as TEdit).Name+' }');
      f.Append((Sender as TEdit).Text);
     end;
   if Sender is TComboBox then // TComboBox
     Begin
      f.Append(' { '+(Sender as TComboBox).Name+' }');
      f.Append((Sender as TComboBox).Text);
     end;
   if Sender is TCheckBox then   // CheckBox
    Begin
     f.Append(' { '+(Sender as TCheckBox).Name+' }');
     if (Sender as TCheckBox).Checked Then f.Append('On')
                                      Else f.Append('Off');
    end;
   if (Sender is TMenuItem) and // TMenuItem
      ((Sender as TMenuItem).AutoCheck=True) then
    Begin
     f.Append(' { '+(Sender as TMenuItem).Name+' }');
     if (Sender as TMenuItem).Checked Then f.Append('On')
                                      Else f.Append('Off');
    end;
   if Sender is TMemo then   // Memo
    Begin
     f.Append(' { '+(Sender as TMemo).Name+' }');
     f.Append('__CLEAR__');
     For l:=0 to ((Sender as TMemo).Lines.Count-1) do
      f.Append((Sender as TMemo).Lines.Strings[l]);
    end;
 end;

Begin
 f:=TStringList.Create;
 f.Append('{ Configure file for application wCncPcb }');
  for i:=0 to (Sender as TForm).ComponentCount-1 do
  Begin
   SaveObject((Sender as TForm).Components[i]);
  end;
 f.SaveToFile(CfgFile);
 f.Free;
 // Mema
 //InitMemo.Lines.SaveToFile('BeforeGCode.cfg');
 //FinishMemo.Lines.SaveToFile('AfterGCode.cfg');
end;
// nacitanie
Procedure LoadSettings(Sender : TObject);
Var f    : TStrings;
    i    : Integer;
    ad, s: String;

 Function DecodeComponent (Txt : String): String;
  var j,k,l : Integer;
  Begin
   Result:='';
   j:=Length(Txt);
   l:=Pos('}',Txt);
   k:=Pos('{',Txt);
   if (j>5) and (l>4) and (k>0) Then
    Begin
     if (copy(Txt, k, 2)='{ ') and (copy(Txt, l-1, 2)=' }') Then Result:=Copy(Txt, k+2, l-k-3);
    End;
  end;

 Procedure SetComponent (CompName, Parameter : String);
  Var i : Integer;
  Begin
   for i:=0 to (Sender as TForm).ComponentCount-1 do
   Begin
    // FloatSpinEdit
    If (Sender as TForm).Components[i] is TFloatSpinEdit Then
     Begin
      if ((Sender as TForm).Components[i] as TFloatSpinEdit).Name=CompName Then
       ((Sender as TForm).Components[i] as TFloatSpinEdit).Text:=Parameter;
     end;
    // SpinEdit
    If (Sender as TForm).Components[i] is TSpinEdit Then
     Begin
      if ((Sender as TForm).Components[i] as TSpinEdit).Name=CompName Then
       ((Sender as TForm).Components[i] as TSpinEdit).Text:=Parameter;
     end;
    // Edit
    If (Sender as TForm).Components[i] is TEdit Then
     Begin
      if ((Sender as TForm).Components[i] as TEdit).Name=CompName Then
       ((Sender as TForm).Components[i] as TEdit).Text:=Parameter;
     end;
    // ComboBox
    If (Sender as TForm).Components[i] is TComboBox Then
     Begin
      if ((Sender as TForm).Components[i] as TComboBox).Name=CompName Then
       ((Sender as TForm).Components[i] as TComboBox).Text:=Parameter;
     end;
    // CheckBox
    If (Sender as TForm).Components[i] is TCheckBox Then
     Begin
      if ((Sender as TForm).Components[i] as TCheckBox).Name=CompName Then
       ((Sender as TForm).Components[i] as TCheckBox).Checked:=(UpperCase(Parameter)='ON');
     end;
    // Menu item
    If (Sender as TForm).Components[i] is TMenuItem Then
     Begin
      if (((Sender as TForm).Components[i] as TMenuItem).Name=CompName) and
         (((Sender as TForm).Components[i] as TMenuItem).AutoCheck=True) Then
       ((Sender as TForm).Components[i] as TMenuItem).Checked:=(UpperCase(Parameter)='ON');
     end;
    // MEMO
    If (Sender as TForm).Components[i] is TMemo Then
     Begin
      if ((Sender as TForm).Components[i] as TMemo).Name=CompName Then
       begin
        If (UpperCase(Parameter)='__CLEAR__') Then ((Sender as TForm).Components[i] as TMemo).Lines.Clear
         else ((Sender as TForm).Components[i] as TMemo).Lines.Append(Parameter);
       end;
     end;
   end;
  End;

Begin
 if FileExists(CfgFile) Then
  Begin
   f:=TStringList.Create;
   f.LoadFromFile(CfgFile);
   ad:='';
   if f.Count>2 Then
    For i:=0 to f.Count-1 do
     Begin
      s:=DecodeComponent(f.Strings[i]);
      if s='' Then SetComponent(ad, f.Strings[i])
              Else ad:=s;
     end;
   f.Free;
  end;
 // Mema
 //If FileExists('BeforeGCode.cfg') Then InitMemo.Lines.LoadFromFile('BeforeGCode.cfg');
 //If FileExists('AfterGCode.cfg') Then FinishMemo.Lines.LoadFromFile('AfterGCode.cfg');
end;

// ------------------------------------------------------------------- Ulozenie Jazyka
// ulozenie nastaveni
Procedure SaveLNG (Sender : TObject);
Var f : TStrings;
    i : Integer;

  Procedure SaveObject (Sender : TObject);
  var l : Integer;
  Begin
   if Sender is TCheckBox then   // CheckBox
    Begin
     f.Append(' { '+(Sender as TCheckBox).Name+' }');
     f.Append((Sender as TCheckBox).Caption);
    end;
   if (Sender is TMenuItem) Then // TMenuItem
    Begin
     f.Append(' { '+(Sender as TMenuItem).Name+' }');
     f.Append((Sender as TMenuItem).Caption);
    end;
   if (Sender is TLabel) Then // TLabel
    Begin
     f.Append(' { '+(Sender as TLabel).Name+' }');
     f.Append((Sender as TLabel).Caption);
    end;
 end;

Begin
 f:=TStringList.Create;
 f.Append('{ Language file for application wCncPcb }');
  for i:=0 to (Sender as TForm).ComponentCount-1 do
  Begin
   SaveObject((Sender as TForm).Components[i]);
  end;
 f.SaveToFile(LngFile);
 f.Free;
end;
// nacitanie
Procedure LoadLNG(Sender : TObject);
Var f    : TStrings;
    i    : Integer;
    ad, s: String;

 Function DecodeComponent (Txt : String): String;
  var j,k,l : Integer;
  Begin
   Result:='';
   j:=Length(Txt);
   l:=Pos('}',Txt);
   k:=Pos('{',Txt);
   if (j>5) and (l>4) and (k>0) Then
    Begin
     if (copy(Txt, k, 2)='{ ') and (copy(Txt, l-1, 2)=' }') Then Result:=Copy(Txt, k+2, l-k-3);
    End;
  end;

 Procedure SetComponent (CompName, Parameter : String);
  Var i : Integer;
  Begin
   for i:=0 to (Sender as TForm).ComponentCount-1 do
   Begin
    // CheckBox
    If (Sender as TForm).Components[i] is TCheckBox Then
     Begin
      if ((Sender as TForm).Components[i] as TCheckBox).Name=CompName Then
       ((Sender as TForm).Components[i] as TCheckBox).Caption:=Parameter;
     end;
    // Menu item
    If (Sender as TForm).Components[i] is TMenuItem Then
     Begin
      if (((Sender as TForm).Components[i] as TMenuItem).Name=CompName) Then
       ((Sender as TForm).Components[i] as TMenuItem).Caption:=Parameter;
     end;
    // Label
    If (Sender as TForm).Components[i] is TLabel Then
     Begin
      if (((Sender as TForm).Components[i] as TLabel).Name=CompName) Then
       ((Sender as TForm).Components[i] as TLabel).Caption:=Parameter;
     end;
   end;
  End;

Begin
 if FileExists(LNGFile) Then
  Begin
   f:=TStringList.Create;
   f.LoadFromFile(LNGFile);
   ad:='';
   if f.Count>2 Then
    For i:=0 to f.Count-1 do
     Begin
      s:=DecodeComponent(f.Strings[i]);
      if s='' Then SetComponent(ad, f.Strings[i])
              Else ad:=s;
     end;
   f.Free;
  end;
end;


end.

