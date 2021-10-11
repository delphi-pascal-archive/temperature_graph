unit Ucourbe1;

{ Analyse
  -------
 Avant de d'afficher le graphique, on le décale(scroll) de "pas" pixels
 vers la droite, puis on initialise les pixels à droite, et enfin on trace
 la nouvelle valeur du graphique.

 De manière à pouvoir reconstituer l'affichage du graphique s'il
 est recouvert par une autre fenêtre ou bien si on redimensionne
 la fenêtre, le graphique est créé sans Bmp1 au lieu de simplement
 utiliser le canvas de la paintbox Pb1.

 Noter que le décalage du bitmap1 s'effectue par un simple copyrect
 sur son propre canvas.

 En cas de redimensionnement, un bitmap Bmp2 mémorise BMP1 et le redessine
 au bon endroit en fonction du redimensionnement.

 En cas de changement d'échelle (petit grand moyen le graphique est effacé
 car on n'a pas mémorisé les mesures arrivant de manière aléatoire
 dans un tableau de valeurs.

}
interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Spin, ComCtrls, Buttons;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Timer1: TTimer;
    PB2: TPaintBox;
    Pb1: TPaintBox;
    Panel3: TPanel;
    Pb3: TPaintBox;
    Label1: TLabel;
    Label3: TLabel;
    Label2: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Button3: TButton;
    Button1: TButton;
    CheckBox1: TCheckBox;
    RadioGroup1: TRadioGroup;
    UpDown1: TUpDown;
    Edit1: TEdit;
    Edit2: TEdit;
    UpDown2: TUpDown;
    RadioGroup2: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure PB2Paint(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Pb1Paint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Panel3Click(Sender: TObject);
    procedure Pb3Paint(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure UpDown2Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
  private
    { Déclarations private }
    Procedure Lignesh(xdebut : integer);
    procedure paintboxes;
    procedure initpaintbox;
    procedure decale(n : integer);
    procedure initcolors;
  public
    { Déclarations public }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

var
  ctrtimer : integer;  { compteur appel timer }
  ctr1 : integer;  { compteur de minutes }
  Ctr2 : integer;  { compteur d'heures }
  ccfond   : Tcolor;
  cctrait1 : Tcolor;
  cctrait2 : Tcolor;
  pas : integer;   { pas d'avancement de la courbe }

  couleur : array[0..63] of Tcolor;
  oldh : integer;
  evolution : integer;  { règle le sens d'évolution de la température }
  bmp1 : Tbitmap;
  firstime : boolean;

  { gestion de Pb1 graduations }
  U         : integer;    { unité principale: 2 ou 1 }
  Intervalle: integer;    { vaut 64  0..63  de +40° à -24° }
  Margehaut : integer;    { en haut de la courbe : 8 }
  Margebas  : integer;    { en bas de la courbe  : 20 }
  TraitH1   : integer;    { pas du trait horizontal principal }

  { gestion des graduations de  Pb2 }
  { Unite  Hauteur et margehaut identiques à pb1 }
  X1ciel      : integer;    { gauche arc en ciel }
  X2ciel      : integer;    { droite arc en ciel }
  aligndroite2 : integer;  { position des chiffres cadrés à droite }

  { gestion des graduations de PB3 }
  aligndroite3 : integer;
  Xthermo     : integer;    { position du thermomètre }


procedure TForm1.FormCreate(Sender: TObject);
var
  HH, MN, SS, MS : word;
begin
  ctrtimer := 0;
  firstime := true;
  Bmp1 := Tbitmap.create;
  bmp1.width := pb1.width;
  Bmp1.height := pb1.height;
  Decodetime(now, HH, Mn, ss, ms);
  ctr1 := 0;
  Ctr2 := HH;
  oldh := 24;
  pas := updown2.position;
  evolution := 2;
  randomize;
  initcolors;
  ccfond   := clblack;
  cctrait1 := clwhite;
  cctrait2 := clsilver;
end;

Procedure Tform1.initcolors;
{ création de 64 couleurs de l'arc en ciel valeurs de 0..63 }
Var
  i : integer;
  rr, bb, gg : integer;
  ctr : integer;
Begin
  ctr := 0;
  for i := 0 to 15 do
  begin  {Red To Yellow}
    rr := 255;
    bb := 0;
    gg := (255 * i) div 15;
    couleur[ctr] := rgb(rr, gg, bb);
    inc(ctr);
  end;  { 16 }
  for i := 0 to 15 do
  begin
    { Yellow To Green}
    gg := 255;
    bb := 0;
    rr := 255 - (128*i) div 15;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;  { 24 }
  For i := 0 to 7  do
  begin
    { Green To Cyan}
    rr := 0;
    gg := 255;
    bb := (255 * i) div 7;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;  { 40 }
  For i := 0 to 15 do
  begin
    { Cyan To Blue}
    rr := 0;
    bb := 255;
    gg := 255 - (255 * i) div 15;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;  { 56 }
  For i := 0 TO 7 do
  begin
    { Blue To Magenta}
    gg := 0;
    bb := 255;
    rr := (255 * i) div 7;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;  { 64 }
end;

{ initialise les paintbox
  c'est la taille de la courbe (petite ou grande) qui détermine
  la hauteur y compris celle du panel.
  C'est la largeur du panel1 qui  détermine la largeur }

Procedure Tform1.initpaintbox;
begin
  U := Radiogroup1.itemindex +1 ;
  Intervalle:= 64 ;
  Margehaut := 8;      { en haut de la courbe  }
  Margebas  := 12;     { en bas de la courbe  }
  TraitH1   := 10* U;  { pas du trait horizontal principal }
  { gestion des graduations de  Pb2 }

  Pb2.top    := 8;
  Pb2.left   := 8;
  Pb2.width  := 36;
  Pb2.height := margehaut+margebas+intervalle*U;
  Panel1.height := Pb2.height + 16;
  X1ciel    := 0;    { gauche arc en ciel }
  X2ciel    := 7;    { droite arc en ciel }
  aligndroite2 := 25;  { position des chiffres }


  Pb3.top    := Pb2.top;
  Pb3.left   := Panel1.width - 38;
  Pb3.width  := 36;
  Pb3.height := Pb2.height;
  xthermo  := 29;
  aligndroite3 := 20;

  Pb1.top    := Pb2.top;
  Pb1.left   := Pb2.left+Pb2.width+1;
  pb1.width  := Panel1.width - Pb1.left - Pb3.width;
  pb1.height := Pb2.height;

  bmp1.free;
  Bmp1 := Tbitmap.create;
  bmp1.width  := pb1.width;
  bmp1.height := pb1.height;
  With bmp1.canvas do
  begin
    brush.color := ccfond;
    fillrect(rect(0,0,bmp1.width, bmp1.height));
    Font.name := 'Arial';
    Font.color := cctrait1;
    Font.size := 8;
  end;
  lignesh(0);
end;

Procedure Tform1.lignesh(xdebut : integer);  // trace lignes Horizontales
var                             // de Xdebut au bord droit de la paintbox
  i : integer;
begin
  with bmp1.canvas do
  begin
    pen.width := 1;
    For i := 0 to 6 do  { lignes horizontales }
    begin
      IF i = 4 then pen.color:= cctrait1 else pen.color := cctrait2;
      moveto(xdebut, margehaut+traith1*i);
      lineto(pb1.width, margehaut+traith1*i);
    end;
  end;
end;

{ décale pb1 de n pixels vers la gauche }
Procedure TForm1.decale(n : integer);
var
  r1, r2 : Trect;  { rectangles }
begin
  r1 := rect(0,0,pb1.width, pb1.height);     // fenètre à décaler
  scrolldc(bmp1.canvas.handle, -n, 0, r1, r1, 0, nil); // décalage
  r2 := rect(pb1.width-n, 0, pb1.width, pb1.height);   // initialise à noir
  bmp1.canvas.brush.color := clblack;
  bmp1.canvas.Fillrect(r2);
  lignesh(pb1.width-n);       // dessine lignes horiziontales
end;

{ dessine pb2 et pb3 }
procedure Tform1.paintboxes;
var
  i : integer;
  T : integer;
  s : string;
begin
  T := 40;
  For i := 0 to intervalle - 1 do  { 0..63 }
  begin
    With Pb2.canvas do
    begin
      Brush.color := Couleur[i];  { arc en ciel }
      Fillrect(rect(x1ciel, margehaut-1+i*U, x2ciel, margehaut+(i+1)*U));
      Brush.color := clbtnface;
      pen.color := clblack;
      IF ((u = 1) AND (i mod 20 = 0)) OR
         ((u > 1) AND (i mod 10 = 0)) Then
      begin
        moveto(aligndroite2+2, margehaut+ U*i);
        lineto(Pb2.width, margehaut+ U*i);
        s := inttostr(T);
        textout(aligndroite2-textwidth(s), U*i, s);
      end
      else
      begin
        IF (u > 1) OR ((u = 1) AND (i mod 10 = 0)) then
        begin
          moveto(aligndroite2+5, margehaut+ U*i);
          lineto(Pb2.width  , margehaut+ U*i);  { petites graduations }
        end
      end;
    end;
    With Pb3.canvas do
    begin
      brush.color := clbtnface;
      pen.width := 1;
      pen.color := clblack;
      IF ((u = 1) AND (i mod 20 = 0)) OR
         ((u > 1) AND (i mod 10 = 0)) Then
      begin
        moveto(aligndroite3+2, margehaut+ U*i);
        lineto(Pb2.width, margehaut+ U*i);
        s := inttostr(T);
        textout(aligndroite3-textwidth(s), U*i, s);
        T := T - 10;
      end
      else
      begin
        IF (u > 1) OR ((u = 1) AND (i mod 10 = 0)) then
        begin
          moveto(aligndroite3+5, margehaut+ U*i);
          lineto(Pb2.width-3   , margehaut+ U*i);  { petites graduations }
        end;
      end;
      pen.color := clred;
      brush.color := clred;
      ellipse(Xthermo-4, MargeHaut+intervalle*U,
              Xthermo+4, Margehaut+Intervalle*U + 8);
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  deg : integer;   { température }
  h : integer;
  s : string;
begin
  { lentement : décalage 1 pixel à chaque fois }
  IF checkbox1.checked then
  begin
    Inc(ctrtimer);
    IF ctrtimer mod pas <> 0 then
    begin
      decale(1);
      pb1.canvas.draw(0,0,bmp1);
     exit;
    end;
    decale(1);
  end
  else
  begin
  { rapidment décale de n pixels }
    decale(pas);
  end;
  IF ctr1 > 60 then  { gestion des heures minutes }
  begin
    ctr1 := 0;
    inc(ctr2);
    IF ctr2 > 24 then ctr2 := 1;
  end;
  with bmp1.canvas do
  begin
    IF ctr1 = 0 then  { graduation verticale en heures }
    begin
      pen.width := 1;
      pen.color := cctrait2;
      moveto(pb1.width-1, 0);
      lineto(pb1.width- 1, pb1.height);
      s := inttostr(ctr2)+' h';
      Textout(pb1.width - textwidth(s)-1, pb1.height-12, s);
    end;
    h := oldh + evolution - random(5);
    if (h < 0) or (h > 62)  then h := oldh;
    Panel3.font.color := couleur[h];
    deg := 40 - h;
    Panel3.Caption := inttostr(deg)+' °';
    Pen.color := couleur[h];
    Pen.width := 2;
    IF Radiogroup2.itemindex = 1 then
    begin
      If pas = 1 then pen.width := 1;
      moveto(pb1.width- pas, margehaut+ h * U);
      lineto(pb1.width- pas, margehaut+ 63 * U);
    end
    else
    begin
      moveto(pb1.width-2 - pas , margehaut+ oldh * U);
      lineto(pb1.width-2       , margehaut+ h * U);
    end;
    oldh := h;
  end;
  inc(ctr1);
  pb1.canvas.draw(0,0,bmp1);
  with pb3.canvas do     { thermomètre }
  begin
    pen.width := 2;
    pen.color := clWhite;
    moveto(xthermo,8);
    lineto(xthermo,8+ h*U);
    pen.color := clred;
    moveto(xthermo, margehaut+ h*U);
    lineto(xthermo, margehaut+ intervalle*U);
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  IF Timer1.enabled = true then
  begin
    Timer1.enabled := False;
    Button1.caption := 'Start';
  end
  else
  begin
    Timer1.enabled := true;
    Button1.caption := 'Stop';
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Timer1.enabled := false;
end;


procedure TForm1.FormResize(Sender: TObject);
begin
  timer1.enabled := false;
  Panel1.left    := 16;
  Panel1.width   := clientwidth - panel1.left - 16;
  Pb1.repaint;
  Timer1.enabled := true;
end;

procedure TForm1.PB2Paint(Sender: TObject);
begin
  paintboxes;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
   close;
end;

procedure TForm1.Pb1Paint(Sender: TObject);
var
  bmp2 : Tbitmap;
  r1, r2 : Trect;
begin
  IF firstime then
  begin
    initpaintbox;
    firstime := false;
  end
  else
  begin
    bmp2 := Tbitmap.create;
   try
    Bmp2.assign(bmp1);
    initpaintbox;
    { diminution de taille }
    IF bmp2.width > bmp1.width then
    begin
      r2 := rect(bmp2.width-bmp1.width, 0, bmp2.width, bmp2.height);
      r1 := rect(0, 0, bmp1.width, bmp1.height);
    end
    else
    begin
      r2 := rect(0, 0, bmp2.width, bmp2.height);
      r1 := rect(bmp1.width-bmp2.width, 0, bmp1.width, bmp1.height);
    end;
    bmp1.canvas.copyrect(r1, bmp2.canvas, r2);
   finally
    bmp2.free;
   end;
  end; 
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  bmp1.free;
end;

procedure TForm1.Panel3Click(Sender: TObject);
begin
  IF panel3.color = clblack then
  begin
    panel3.color := clbtnface;
    ccfond   := panel3.color;
    cctrait1 := clblack;
    cctrait2 := clsilver;
    panel1.font.color := cctrait1;
  end
  else
  IF panel3.color = clbtnface then
  begin
    panel3.color := $00E8E8E8;
    ccfond   := panel3.color;
    cctrait1 := clblack;
    cctrait2 := clsilver;
    panel1.font.color := cctrait1;
  end
  else
   begin
    panel3.color := clblack;
    ccfond   := Panel3.color;;
    cctrait1 := clwhite;
    cctrait2 := clsilver;
    panel1.font.color := cctrait1;
  end;
  Pb1.repaint;
end;

procedure TForm1.UpDown1Click(Sender: TObject; Button: TUDBtnType);
begin
  Timer1.interval := (10 -  updown1.position) * 20;
end;

procedure TForm1.UpDown2Click(Sender: TObject; Button: TUDBtnType);
begin
  pas := updown2.position;
end;

procedure TForm1.Pb3Paint(Sender: TObject);
begin
  paintboxes;
end;

procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
  Timer1.enabled := false;
  Initpaintbox;
  Timer1.enabled := true;
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
begin
  Evolution := 2;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  evolution := 3;
end;

procedure TForm1.SpeedButton3Click(Sender: TObject);
begin
  evolution := 1;
end;

end.
