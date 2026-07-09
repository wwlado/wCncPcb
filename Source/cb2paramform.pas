unit cb2ParamForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  Buttons, cb2Atom, cb2Graphics;

type

  { TForm3 }

  TForm3 = class(TForm)
    btnApply: TBitBtn;
    btnStorno: TBitBtn;
    btnOK: TBitBtn;
    cbType: TComboBox;
    cbLayer: TComboBox;
    chDbg: TCheckBox;
    eText: TEdit;
    fseX: TFloatSpinEdit;
    fseY: TFloatSpinEdit;
    fseToX: TFloatSpinEdit;
    fseToY: TFloatSpinEdit;
    fseR: TFloatSpinEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    seG: TSpinEdit;
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnStornoClick(Sender: TObject);
    procedure chDbgChange(Sender: TObject);
  private

  public
    Procedure EditAtom (a : pAtom);
  end;

var
  Form3: TForm3;
  sAtom: pAtom;
  aMem : tAtom;

implementation
uses mineForm;
{$R *.lfm}

{ TForm3 }
// otvor subor
Procedure TForm3.EditAtom (a : pAtom);
Begin
 aMem.Typ:=255;
 sAtom:=Nil;
 if a<>nil Then
 Begin
  sAtom:=A;
  aMem:=A^;
  Case a^.Typ of
   tHole:     cbType.ItemIndex:=0;
   tCircle:   cbType.ItemIndex:=1;
   tWay:      cbType.ItemIndex:=2;
   tText:     cbType.ItemIndex:=3;
   tRectangle:cbType.ItemIndex:=4;
   tComponent:cbType.ItemIndex:=5;
   tBegin:    cbType.ItemIndex:=6;
   tPosHan:   cbType.ItemIndex:=7;
  end;
  Case a^.Layer of
   tCopper:   cbLayer.ItemIndex:=0;
   tBackCp:   cbLayer.ItemIndex:=1;
   tCut:      cbLayer.ItemIndex:=2;
   tMarker:   cbLayer.ItemIndex:=3;
   tContour:  cbLayer.ItemIndex:=4;
   tBegin:    cbLayer.ItemIndex:=5;
   tPosHan:   cbLayer.ItemIndex:=6;
  end;
  fseX.Value  :=iNumToSpin(A^.X);
  fseY.Value  :=iNumToSpin(A^.Y);
  fseToX.Value:=iNumToSpin(A^.ToX);
  fseToY.Value:=iNumToSpin(A^.ToY);
  fseR.Value  :=iNumToSpin(A^.R);
  seG.Value   := A^.Group;
  eText.Text  := A^.Name;
  //
  Form3.Visible:=True;
 end;
End;

// OK
procedure TForm3.btnOKClick(Sender: TObject);
begin
 if sAtom<>nil Then
 Begin
  if chDbg.Checked Then
  Case cbType.ItemIndex of
   0: sAtom^.Typ:=   tHole;
   1: sAtom^.Typ:=   tCircle;
   2: sAtom^.Typ:=   tWay;
   3: sAtom^.Typ:=   tText;
   4: sAtom^.Typ:=   tRectangle;
   5: sAtom^.Typ:=   tComponent;
   6: sAtom^.Typ:=   tBegin;
   7: sAtom^.Typ:=   tPosHan;
  end;
  if chDbg.Checked Then
  Case cbLayer.ItemIndex of
   0: sAtom^.Layer:=   tCopper;
   1: sAtom^.Layer:=   tBackCp;
   2: sAtom^.Layer:=   tCut;
   3: sAtom^.Layer:=   tMarker;
   4: sAtom^.Layer:=   tContour;
   5: sAtom^.Layer:=   tBegin;
   6: sAtom^.Layer:=   tPosHan;
  end;
  sAtom^.X    := SpinToInum(fseX.Value);
  sAtom^.Y    := SpinToInum(fseY.Value);
  sAtom^.ToX  := SpinToInum(fseToX.Value);
  sAtom^.ToY  := SpinToInum(fseToY.Value);
  sAtom^.R    := SpinToInum(fseR.Value);
  sAtom^.Group:= seG.Value;
  sAtom^.Name := eText.Text;
  //
  //Form1.gRebuild;
  Form1.gReconstruct;
  Form3.Close;
 end;
End;

// Pouzit
procedure TForm3.btnApplyClick(Sender: TObject);
begin
 if sAtom<>nil Then
 Begin
  if chDbg.Checked Then
  Case cbType.ItemIndex of
   0: sAtom^.Typ:=   tHole;
   1: sAtom^.Typ:=   tCircle;
   2: sAtom^.Typ:=   tWay;
   3: sAtom^.Typ:=   tText;
   4: sAtom^.Typ:=   tRectangle;
   5: sAtom^.Typ:=   tComponent;
   6: sAtom^.Typ:=   tBegin;
   7: sAtom^.Typ:=   tPosHan;
  end;
  if chDbg.Checked Then
  Case cbLayer.ItemIndex of
   0: sAtom^.Layer:=   tCopper;
   1: sAtom^.Layer:=   tBackCp;
   2: sAtom^.Layer:=   tCut;
   3: sAtom^.Layer:=   tMarker;
   4: sAtom^.Layer:=   tContour;
   5: sAtom^.Layer:=   tBegin;
   6: sAtom^.Layer:=   tPosHan;
  end;
  sAtom^.X    := SpinToInum(fseX.Value);
  sAtom^.Y    := SpinToInum(fseY.Value);
  sAtom^.ToX  := SpinToInum(fseToX.Value);
  sAtom^.Toy  := SpinToInum(fseToY.Value);
  sAtom^.R    := SpinToInum(fseR.Value);
  sAtom^.Group:= seG.Value;
  sAtom^.Name := eText.Text;
  //
  Form1.gRebuild;
  //Form1.gReconstruct;
 end;
End;

// Storno
procedure TForm3.btnStornoClick(Sender: TObject);
begin
 if aMem.Typ<255 Then sAtom^:=aMem;
 Form3.Close;
end;

// Debug
procedure TForm3.chDbgChange(Sender: TObject);
begin
 cbType.Enabled :=chDbg.Checked;
 cbLayer.Enabled:=chDbg.Checked;
end;



end.

