unit cb2view;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  ExtDlgs, ComCtrls;

type

  { TForm2 }

  TForm2 = class(TForm)
    Image1: TImage;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenPictureDialog1: TOpenPictureDialog;
    StatusBar1: TStatusBar;
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure OpenPicture(img: TBitmap);
  private

  public

  end;

var
  Form2: TForm2;

implementation
 uses MineForm;

{$R *.lfm}

{ TForm2 }

// otvor subor
procedure TForm2.MenuItem1Click(Sender: TObject);
begin
  if openPictureDialog1.Execute Then
   if FileExists(OpenPictureDialog1.FileName) then Image1.Picture.LoadFromFile(OpenPictureDialog1.FileName);
end;

// stale na vrchu
procedure TForm2.MenuItem2Click(Sender: TObject);
begin
  if MenuItem2.Checked then Form2.FormStyle:=fsStayOnTop
                       else Form2.FormStyle:=fsNormal;
  if MenuItem2.Checked then MenuItem2.ImageIndex:=148
                       else MenuItem2.ImageIndex:=152;
end;

// nacitat obrazok
procedure TForm2.OpenPicture(img: TBitmap);
Begin
  Image1.Picture.Bitmap.Width   :=img.Width;
  Image1.Picture.Bitmap.Height  :=img.Height;
  if (img.Width<Form1.Width) and
     (img.Height<Form1.Height) then
   begin
    Image1.Stretch :=False;
    Image1.AutoSize:=True;
    Form2.ClientWidth :=image1.Picture.Width;
    Form2.ClientHeight:=image1.Picture.Height+StatusBar1.Height;
   end;
  image1.Picture.Bitmap.Canvas.Draw(0,0,img);
  Form2.Visible:=True;
  Image1.Repaint;
  Form2.Repaint;
  Image1.Stretch :=True;
  Image1.AutoSize:=False;
end;

end.

