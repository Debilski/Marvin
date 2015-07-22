unit umarvin2;
(*{$D-}*)
interface

uses umarvin1,crt;

type
  frame_chars = array[1..8] of char;
  wall_chars = array[1..4] of array[1..7] of char;
  dir_chars = array[1..4] of char;
  in_chars = array[1..4] of set of char;

const
  wall_frame : wall_chars =
    ('≥Ÿ¿¡¥√≈',
     'ƒøŸ¥¬¡≈',
     '≥⁄ø¬√¥≈',
     'ƒ¿⁄√¡¬≈');
  wall_ch : set of char = ['≥','ƒ','⁄','ø','Ÿ','¿','¬','¥','¡','√','≈'];

  in_ch : in_chars =
        (['≥','⁄','ø','¬','¥','√','≈'],(*oben*)
         ['ƒ','⁄','¿','¬','¡','√','≈'],(*links*)
         ['≥','Ÿ','¿','¥','¡','√','≈'],(*unten*)
         ['ƒ','ø','Ÿ','¬','¥','¡','≈']);(*rechts*)

  spf_frame : frame_chars = '…Õª∫∫»Õº';
  dir_marvin : dir_chars = (chr(16),chr(31),chr(17),chr(30));
  inv_char : set of char = ['A'..'F','1'..'9'];
  inv_cont : set of char = ['A'..'F'];
  inv_num : set of char = ['1'..'9'];
  inv_nimm : set of char = ['0'..'8'];

  dot = chr(250);
  frei : set of char = [chr(32),dot];

  j_n : set of char = ['J','j','N','n'];
  richt_set : set of char = ['O','o','L','l','R','r','U','u'];

  nocursor=$2000;

  WhiteOnRed = White + (Red shl 4);
  WhiteOnBlue = White + (Blue shl 4);
  YellowOnBlack = Yellow + (Black shl 4);
  WhiteOnBlack = White + (Black shl 4);
  RedOnBlack = Red + (Black shl 4);
  LightGreenOnBlack = LightGreen + (Black shl 4);
  CyanOnBlack = Cyan + (Black shl 4);

type
  str40 = string[39];
  spf_array = array[1..40] of string[19];
  marv_ptr = ^marvin;
  spf_ptr = ^spielfeld;

  marvin = object
    next : marv_ptr;
    xpoint,
    ypoint : byte;
    inventar : char;
    richtung : t_richtung;
    visible : boolean;
    number : word;
    function direction : char;
    procedure show;
    procedure hide;
    procedure on_off;
    procedure go_left;
    procedure go_right;
    procedure go_down;
    procedure go_up;
    constructor init;
  end;

  spielfeld = object
    maxx,maxy,
    hix,lox,hiy,loy : byte;
    titel : str40;
    spf_name : string[12];
    xpoint,
    ypoint : word;
    inventar : char;
    richtung : t_richtung;
    farbe : word;
    feld, dfeld : spf_array;
    procedure frames;
    procedure reset;
    procedure fill;
    procedure status1;
    procedure status2;
    procedure menu1;
    procedure menu2;
    procedure infoa;
    procedure infob;
    procedure writename;
    procedure save;
    procedure load(dname : str80);
    constructor init;
    destructor done;
  end;

  programm = object
    prg_name : string[12];
    mode_name : string[8];
    mode : boolean;
    act : string;
    run : boolean;
    changed : boolean;
    procedure save;
    procedure load;
    procedure new;
    procedure teach(action : char);
    procedure play;
    constructor init;
  end;

var
  spf : spielfeld;
  topmarv : marv_ptr;
  prg : programm;
  oldcursor : word;
  z_modus : word;
  zeichnen : boolean;
  oldmode : word;
  mogeln : boolean;
  altmode : boolean;

procedure WriteXY(x, y : integer; s : string);
procedure SetCursor(NewCursor : Word);
function GetCursor : Word;
procedure writechar(X, Y, Count: Byte; Ch: Char; Attr: Byte);
procedure newmarv;
procedure delmarv;
function left : t_richtung;
function right : t_richtung;
function back : t_richtung;
function richt_char(richt : t_richtung): char;
function char_richt(cha : char): t_richtung;
function vorne_char : char;
function links_char : char;
function rechts_char : char;
function hinten_char : char;
procedure ch_modus;
function ask_if(frage : str80) : boolean;
procedure clearinputbuffer;
procedure cheat;

implementation

uses dos;

const
  frameattr = 12;
  titleattr = 205;

type
  spf_record = record
    xpoint,
    ypoint : byte;
    richtung : char;
    inventar : char;
    s14 : string[14];
    farbe : byte;
    feld : spf_array;
  end;

var
  spf_var : spf_record;
  spf_file : file of spf_record;

procedure SetCursor(NewCursor : Word);
{ Sets the value of the scan lines of the cursor }
var
  Reg : Registers;
begin
  with Reg do
  begin
    AH := 1;
    BH := 0;
    CX := newcursor;
    Intr($10, Reg);
  end; { with }
end; { SetCursor }

function GetCursor : Word;
{ Returns the value of the scan lines of the cursor }
var
  Reg : Registers;
begin
  with Reg do
  begin
    AH := 3;
    BH := 0;
    Intr($10, Reg);
    GetCursor := CX;
  end; { Reg }
end; { GetCursor }


procedure WriteXY(x, y : integer; s : string);
begin
  if (x>=1) and (x<=80) and (y>=1) and (y<=25) then
  begin
    GoToXY(x, y);
    Write(s);
  end;
end;

procedure WriteStr(X, Y: Byte; S: String; Attr: Byte);
var
  oldattr: byte;
begin
  oldattr:=textattr;
  textattr:=attr;
  gotoxy(x,y);
  write(s);
  textattr:=oldattr;
end;

procedure WriteChar(X, Y, Count: Byte; Ch: Char; Attr: Byte);
var
  oldattr: byte;
  i,j : integer;
begin
  oldattr:=textattr;
  textattr:=attr;
  gotoxy(x,y);
  for i:=1 to count do
    write(ch);
  textattr:=oldattr;
end;

procedure spielfeld.frames;
var
  W, H, Y, Z: Word;
  S : string;
begin
  W := hix - lox + 1;
  H := hiy - loy + 1;
  WriteChar(lox, loy, 1, spf_Frame[1], FrameAttr);
  WriteChar(lox+1, loy, W - 2, spf_Frame[2], FrameAttr);
  WriteChar(hix, loy, 1, spf_Frame[3], FrameAttr);
  for Y := 2 to H - 1 do
  begin
    WriteChar(lox, Y, 1, spf_Frame[4], FrameAttr);
    WriteChar(hix, Y, 1, spf_Frame[5], FrameAttr);
  end;
  WriteChar(lox, hiy, 1, spf_Frame[6], FrameAttr);
  WriteChar(lox+1, hiy, W - 2, spf_Frame[7], FrameAttr);
  WriteChar(hix, hiy, 1, spf_Frame[8], FrameAttr);
  writestr(lox,loy,'0',frameattr);
  for y:=1 to w div 5 do
  begin
    z:=y*5;
    str(z,s);
    writestr(lox+Z,loy,s,frameattr);
  end;
  for y:=1 to h div 5 do
  begin
    z:=y*5;
    str(z:2,s);
    writestr(1,Z+loy,s,frameattr);
  end;
  if length(titel) > W - 2 then Titel[0] := Chr(W - 2);
  WriteStr((W - Length(Titel)) shr 1 + lox, 1, Titel, TitleAttr);
end;

procedure spielfeld.fill;
var
  i,j:word;
begin
  textattr:=farbe;
  for i:=1 to maxx do
    for j:=1 to maxy do
      writexy(lox+i,loy+j,feld[i][j]);
  if topmarv<>nil then
    topmarv^.show;
end;

procedure spielfeld.reset;
var
  i,j : word;
begin
  fillchar(feld,sizeof(feld),' ');
  for i:=1 to (maxx div 5) do
    for j:=1 to maxy do
      feld[i*5][j]:=dot;
  for i:=1 to (maxy div 5) do
    for j:=1 to maxx do
      feld[j][i*5]:=dot;
  farbe:=yellowonblack;
end;

procedure spielfeld.status1;
var
  i : word;
const
  sttext : array[1..10] of string[8] = ('      ','Prg Si','Prg La','PrgNeu','Teach ',
                                     'AutoAn','Spf Si','Spf La','Spfénd','Quit');
begin
  gotoxy(1,25);
  for i:=1 to 10 do
  begin
    textattr:=whiteonred;
    if i=1 then write(1) else
    write(i : 2);
    textattr:=whiteonblue;
    write(sttext[i]);
  end;
  clreol;
end;

procedure spielfeld.status2;
var
  i : word;
const
  sttext : array[1..10] of string[8] = ('      ','AnfPos','GeheZu','Objekt','Farbe ',
                                     '      ','Spf Si','Spf La','SpfNeu','ZurÅck');
begin
  gotoxy(1,25);
  for i:=1 to 10 do
  begin
    textattr:=whiteonred;
    if i=1 then write(1) else
    write(i : 2);
    textattr:=whiteonblue;
    write(sttext[i]);
  end;
  clreol;
end;

procedure spielfeld.menu1;
var
  i,j : word;
const
  mtext : array[1..6] of string[12] = ('Linksdrehen','Rechtsdrehen','Vorgehen','Aufnehmen','Hinlegen','Ende');
begin
  gotoxy(2,24);
  for i:=1 to 6 do
  begin
    textattr:=redonblack;
    write(mtext[i][1]);
    textattr:=whiteonblack;
    for j:=2 to length(mtext[i]) do
      write(mtext[i][j]);
    write(' ');
  end;
  clreol;
end;

procedure spielfeld.menu2;
var
  i,j : word;
const
  mtext : array[1..4] of string[12] = ('Linksdrehen','Rechtsdrehen','Vorgehen','Zeichenstift');
begin
  gotoxy(2,24);
  for i:=1 to 4 do
  begin
    textattr:=redonblack;
    write(mtext[i][1]);
    textattr:=whiteonblack;
    for j:=2 to length(mtext[i]) do
      write(mtext[i][j]);
    write(' ');
  end;
  clreol;
end;

procedure spielfeld.infoa;
begin
  textattr:=whiteonblack;
  writexy(46,3,'Programm    :');
  writexy(46,4,'Modus       :');
  writexy(46,6,'x           :');
  writexy(46,7,'y           :');
  writexy(46,8,'Richtung    :');
  writexy(46,10,'Vorrat      :');
  writexy(46,12,'AnfPos      :');
  writexy(46,14,'Marvin      :');
  if zeichnen then writexy(46,16,'Stift       :')
    else writexy(46,16,'             ');
end;

procedure spielfeld.infob;
begin
  textattr:=yellowonblack;
  writexy(60,3,prg.prg_name);
  clreol;
  writexy(60,4,prg.mode_name);
  gotoxy(60,6);
  write(topmarv^.xpoint);
  clreol;
  gotoxy(60,7);
  write(topmarv^.ypoint);
  clreol;
  writexy(60,8,richt_char(topmarv^.richtung));
  writexy(60,10,topmarv^.inventar);
  gotoxy(60,12);
  write(xpoint,' | ',ypoint,' | ',richt_char(richtung),' | ',inventar);
  clreol;
  gotoxy(60,14);
  if topmarv<>nil then
  begin
    write(topmarv^.number);
    if topmarv^.visible then
    write(' (sichtbar)') else write(' (unsichtbar)');
  end else write('Kein Marvin!');
  clreol;
  gotoxy(60,16);
  if zeichnen then
  case z_modus of
    2 : write('Zeichnen');
    3 : write('Radieren');
  end;
  clreol;
end;

procedure spielfeld.writename;
var
  s : string;
  i,j : word;
begin
  j := 12-length(spf_name);
  s:=spf_name;
  for i:=1 to j do
    insert(spf_frame[7],s,1);
  textattr:=frameattr;
  writexy(30,22,s);
end;

procedure spielfeld.save;
const
  copy : array[6..20] of char = ('(','c',')','D','e','b','i','l','s','k','i','A','r','t','s');
var
  i,j : word;
  name,s,path : str80;
  ch : char;
begin
  hinweis('Name des zu sichernden Spielfeldes: ('+spf_name+') ');
  setcursor(oldcursor);
  readln(name);
  setcursor(nocursor);
  if name='' then name:=spf_name;
  if pos('.spf',name) > 0 then else name:=name+'.spf';
  for i:=1 to length(name) do
    delete(name,pos(' ',name),1);
  path:=name;
  while pos('\',name) > 0
    do delete(name,1,1);
  i:=pos(name,path);
  delete(path,i,length(path)-i+1);
  if length(name) > 12 then delete(name,8,length(name)-12);
  s:=fsearch(name,path);
  spf_var.xpoint:=(48+xpoint);
  spf_var.ypoint:=(48+ypoint);
  spf_var.richtung:=richt_char(richtung);
  spf_var.inventar:=inventar;
  if (farbe<>lightgreenonblack) and (farbe<>cyanonblack) then spf_var.farbe:=farbe
    else spf_var.farbe:=yellowonblack;
  spf_var.feld:=feld;
  if s = '' then
  begin
    assign(spf_file,path+name);
    rewrite(spf_file);
    write(spf_file,spf_var);
{    write(spf_file,chr(48+ypoint));
    write(spf_file,richt_char(richtung));
    write(spf_file,inventar);
    if (farbe<>lightgreenonblack) and (farbe<>cyanonblack) then ch:=chr(farbe)
      else ch:=chr(yellowonblack);
    write(spf_file,ch);
    for i:=6 to 20 do write(spf_file,copy[i]);
    for i:=1 to maxx do
      for j:=1 to maxy do
        write(spf_file,feld[i][j]);}
    close(spf_file);
    spf_name:=name;
  end else
    if ask_if('Datei schon vorhanden. öberschreiben?') then
    begin
      assign(spf_file,path+name);
      rewrite(spf_file);
      write(spf_file,spf_var);
      close(spf_file);
      spf_name:=name;
    end;
  hinweis('');
  spf.writename;
end;

procedure spielfeld.load(dname : str80);
var
  i,j : word;
  name,s,path : str80;
  ch : char;
begin
  if dname='' then
  begin
    hinweis('Name des zu ladenden Spielfeldes: ('+spf.spf_name+') ');
    setcursor(oldcursor);
    readln(name);
    setcursor(nocursor);
  end else
    name:=dname;
  if name='' then name:=spf.spf_name;
  if pos('.spf',name) > 0 then else name:=name+'.spf';
  path:=name;
  while pos('\',name) > 0
    do delete(name,1,1);
  i:=pos(name,path);
  delete(path,i,length(path)-i+1);
  s:=fsearch(name,path);
  if s <> '' then
  begin
    assign(spf_file,s);
    system.reset(spf_file);
    read(spf_file,spf_var);
{    read(spf_file,ch);
    xpoint:=ord(ch)-48;
    read(spf_file,ch);
    ypoint:=ord(ch)-48;
    read(spf_file,ch);
    richtung:=char_richt(ch);
    read(spf_file,inventar);
    read(spf_file,ch);
    if (ch=chr(0)) or (ch=chr(lightgreenonblack)) or (ch=chr(cyanonblack)) then spf.farbe:=yellowonblack
      else spf.farbe:=ord(ch);
    if mogeln then farbe:=lightgreenonblack;
    if altmode then farbe:=cyanonblack;
    for i:=6 to 20 do read(spf_file,ch);
    for i:=1 to maxx do
      for j:=1 to maxy do
        read(spf_file,spf.feld[i][j]);}
    xpoint:=spf_var.xpoint-48;
    ypoint:=spf_var.ypoint-48;
    richtung:=char_richt(spf_var.richtung);
    inventar:=spf_var.inventar;
    if (spf_var.farbe mod 17 = 0) or (spf_var.farbe=lightgreenonblack) or (spf_var.farbe=cyanonblack) then farbe:=yellowonblack
      else farbe:=spf_var.farbe;
    if mogeln then farbe:=lightgreenonblack;
    if altmode then farbe:=cyanonblack;
    feld:=spf_var.feld;
    fill;
    topmarv^.hide;
    topmarv^.inventar:=inventar;
    setze_marvin(xpoint,ypoint,richtung);
    topmarv^.show;
    close(spf_file);
    spf_name:=name;
  end else
  begin
    hinweis('Datei nicht vorhanden.>');
  end;
  hinweis('');
  spf.writename;
end;

constructor spielfeld.init;
begin
  topmarv:=nil;
  oldcursor:=getcursor;
  maxx:=40;
  maxy:=20;
  xpoint:=1;
  ypoint:=1;
  lox:=2;
  hix:=lox+maxx+1;
  loy:=1;
  hiy:=loy+maxy+1;
  richtung:=r;
  inventar:='0';
  mogeln:=false;
  altmode:=false;
  farbe:=yellowonblack;
  spf_name:='noname.spf';
  titel:='Marvin';
  reset;
  dfeld:=feld;
end;

destructor spielfeld.done;
var
  i,j : word;
const
  mtext : array[1..5] of string[16] = ('Beenden','Schlussmachen','Aufhîren','Marvin Umbringen','Einschlafen');
begin
  textattr:=whiteonblack;
  writexy(46,3,'Version     :');
  gotoxy(46,4);
  clreol;
  writexy(46,5,'Autor       :');
  writexy(46,6,'             ');
  gotoxy(46,7);
  clreol;
  writexy(46,8,'(C)         :');
  writexy(46,10,'Produzent   :');
  writexy(46,12,'Idee von    :');
  writexy(46,14,'Marvins Name:');
  writexy(46,16,'Marvin      :');

  textattr:=yellowonblack;
  writexy(60,3,'1.0 (Testphase)');
  writexy(60,5,'Rike-Benjamin');
  writexy(60,6,'Schuppner');
  writexy(60,8,'1999');
  writexy(60,10,'Imbezil Productions');
  writexy(60,12,'Niki, der Superrobi');
  gotoxy(60,14);
  write('H2G2');
  clreol;
  writexy(60,16,'ist Toll!');
  gotoxy(2,24);
  for i:=1 to 4 do
  begin
    textattr:=redonblack;
    write(mtext[i][1]);
    textattr:=whiteonblack;
    for j:=2 to length(mtext[i]) do
      write(mtext[i][j]);
    write(' ');
  end;
  clreol;
  gotoxy(1,25);
  for i:=1 to 10 do
  begin
    textattr:=whiteonred;
    if i=1 then write(1) else
    write(i : 2);
    textattr:=whiteonblue;
    write('Ende  ');
  end;
  clreol;
  hinweis('Das Spiel Marvin wurde mit freundlicher UnterstÅtzung von H.Pinther hergestellt>');
  setcursor(oldcursor);
  textmode(CO40);
  textattr:=yellowonblack;
  writeln('Bitte besorgen Sie sich auch:');
  writeln;
  writeln('                              "Marvin 2"');
  writeln;
  writeln('Er ist zurÅck, und er kennt keine Gnade!');
  writeln;
  writeln('Marvin 2 - Das Actionspiel');
  writeln;
  writeln('Imbezil Productions, ltd.');
  stop;
  textmode(oldmode);
end;

function marvin.direction : char;
begin
  if visible then
  case richtung of
    r : direction:=dir_marvin[1];
    u : direction:=dir_marvin[2];
    l : direction:=dir_marvin[3];
    o : direction:=dir_marvin[4];
  end else
  direction:=spf.feld[xpoint][ypoint];
end;

procedure marvin.show;
begin
  writechar(xpoint+spf.lox,ypoint+spf.loy,1,direction,spf.farbe);
end;

procedure marvin.hide;
begin
  writechar(xpoint+spf.lox,ypoint+spf.loy,1,spf.feld[xpoint][ypoint],spf.farbe);
end;

procedure marvin.on_off;
begin
  visible:=not visible;
  prg.teach('@');
  show;
  spf.infob;
end;

procedure marvin.go_left;
begin
  if xpoint > 1 then
  begin
    hide;
    dec(xpoint);
    show;
    prg.teach('L');
    spf.infob;
  end else beep;
end;

procedure marvin.go_right;
begin
  if xpoint < spf.maxx then
  begin
    hide;
    inc(xpoint);
    show;
    prg.teach('R');
    spf.infob;
  end else beep;
end;

procedure marvin.go_down;
begin
  if ypoint < spf.maxy  then
  begin
    hide;
    inc(ypoint);
    show;
    prg.teach('D');
    spf.infob;
  end else beep;
end;

procedure marvin.go_up;
begin
  if ypoint > 1 then
  begin
    hide;
    dec(ypoint);
    show;
    prg.teach('U');
    spf.infob;
  end else beep;
end;

constructor marvin.init;
begin
  next:=topmarv;
  xpoint:=spf.xpoint;
  ypoint:=spf.ypoint;
  inventar:=spf.inventar;
  richtung:=spf.richtung;
  visible:=true;
  if topmarv<>nil then
    number:=topmarv^.number+1
  else
    number:=1;
end;

procedure newmarv;
var
  m1 : marv_ptr;
begin
  if topmarv<>nil then
    topmarv^.hide;
  new(m1,init);
  topmarv:=m1;
  topmarv^.show;
  spf.infob;
end;

procedure delmarv;
var
  m1 : marv_ptr;
begin
  if topmarv<>nil then
  begin
    topmarv^.hide;
    m1:=topmarv;
    with m1^ do
      topmarv:=next;
    dispose(m1);
    if topmarv<>nil then
    begin
      topmarv^.show;
      spf.infob;
    end else begin
      fehler('Kein Marvin mehr! Taste initialisiert neuen Marvin!>');
      hinweis('');
      newmarv;
    end;
  end;
end;

function left : t_richtung;
begin
  case topmarv^.richtung of
    r : left:=o;
    u : left:=r;
    l : left:=u;
    o : left:=l;
  end;
end;

function right : t_richtung;
begin
  case topmarv^.richtung of
    r : right:=u;
    u : right:=l;
    l : right:=o;
    o : right:=r;
  end;
end;

function back : t_richtung;
begin
  case topmarv^.richtung of
    r : back:=l;
    u : back:=o;
    l : back:=r;
    o : back:=u;
  end;
end;

function richt_char(richt : t_richtung): char;
begin
  case richt of
    l: richt_char:='l';
    o: richt_char:='o';
    r: richt_char:='r';
    u: richt_char:='u';
  end;
end;

function char_richt(cha : char): t_richtung;
begin
  case cha of
    'l': char_richt:=l;
    'o': char_richt:=o;
    'r': char_richt:=r;
    'u': char_richt:=u;
  end;
end;

function vorne_char : char;
begin
  vorne_char:='!';
  with topmarv^ do
  begin
    case richtung of
      l: begin
        if xpoint > 1 then
          vorne_char:= spf.feld[ypoint][xpoint-1]
      end;
      o: begin
        if ypoint > 1 then
          vorne_char:= spf.feld[ypoint-1][xpoint]
      end;
      r: begin
        if xpoint < spf.maxx then
          vorne_char:= spf.feld[ypoint][xpoint+1]
      end;
      u: begin
        if ypoint < spf.maxy  then
          vorne_char:= spf.feld[ypoint+1][xpoint]
      end;
    end;
  end;
end;

function links_char : char;
var
  temp_richtung : t_richtung;
begin
  temp_richtung:=topmarv^.richtung;
  topmarv^.richtung:=left;
  links_char:=vorne_char;
  topmarv^.richtung:=temp_richtung;
end;

function rechts_char : char;
var
  temp_richtung : t_richtung;
begin
  temp_richtung:=topmarv^.richtung;
  topmarv^.richtung:=right;
  rechts_char:=vorne_char;
  topmarv^.richtung:=temp_richtung;
end;

function hinten_char : char;
var
  temp_richtung : t_richtung;
begin
  temp_richtung:=topmarv^.richtung;
  topmarv^.richtung:=back;
  hinten_char:=vorne_char;
  topmarv^.richtung:=temp_richtung;
end;

procedure ch_modus;
const
  mode : array[1..3] of string[8] = ('        ','Zeichnen','Radieren');
begin
  if not zeichnen then z_modus:=0;
  case z_modus of
    1 : z_modus:=2;
    2 : z_modus:=3;
    3 : z_modus:=1;
    else z_modus:=1;
  end;
  writexy(60,16,mode[z_modus]);
end;

procedure programm.save;
var
  i : word;
  name,s,path : str80;
  prg_file : text;
begin
  hinweis('Aktuelles Programm sichern in: ('+prg_name+') ');
  setcursor(oldcursor);
  readln(name);
  setcursor(nocursor);
  if name='' then name:=prg_name;
  if pos('.prg',name) > 0 then else name:=name+'.prg';
  for i:=1 to length(name) do
    delete(name,pos(' ',name),1);
  path:=name;
  while pos('\',name) > 0
    do delete(name,1,1);
  i:=pos(name,path);
  delete(path,i,length(path)-i+1);
  if length(name) > 12 then delete(name,8,length(name)-12);
  s:=fsearch(name,path);
  if s = '' then
  begin
    assign(prg_file,path+name);
    rewrite(prg_file);
    write(prg_file,act);
    close(prg_file);
    prg_name:=name;
    changed:=false;
  end else
    if ask_if('Datei schon vorhanden. öberschreiben?') then
    begin
      assign(prg_file,s);
      rewrite(prg_file);
      write(prg_file,act);
      close(prg_file);
      prg_name:=name;
      changed:=false;
    end;
  hinweis('');
  spf.infob;
end;

procedure programm.load;
var
  i,j : word;
  name,s,path : str80;
  prg_file : text;
  ch : char;
begin
  if changed then
    if ask_if('Aktuelles Programm noch nicht gespeichert! Sichern?') then save;
  hinweis('Name des zu ladenden Spielfeldes: ('+prg_name+') ');
  setcursor(oldcursor);
  readln(name);
  setcursor(nocursor);
  if name='' then name:=prg_name;
  if pos('.prg',name) > 0 then else name:=name+'.prg';
  for i:=1 to length(name) do
    delete(name,pos(' ',name),1);
  path:=name;
  while pos('\',name) > 0
    do delete(name,1,1);
  i:=pos(name,path);
  delete(path,i,length(path)-i+1);
  s:=fsearch(name,path);
  if s <> '' then
  begin
    assign(prg_file,s);
    reset(prg_file);
    act:='';
    while not eof(prg_file) do
    begin
      read(prg_file,ch);
      act:=act+ch;
    end;
    close(prg_file);
    prg_name:=name;
  end else
    hinweis('Datei nicht vorhanden.>');
  hinweis('');
  spf.infob;
end;

procedure programm.new;
begin
  if mode then
    if ask_if('Programm lîschen und neues Programm beginnen?') then
      act:=(chr($0A)+chr(topmarv^.xpoint)+chr(topmarv^.ypoint)+chr(ord(topmarv^.richtung)));
end;

procedure programm.teach(action : char);
begin
  if action='#' then
  begin
    if (not mode) and (act<>'') then
      if ask_if('Programm noch nicht gespeichert! Speichern?') then save;
    mode:=not mode;
    if mode then
    begin
      act:=(chr($0A)+chr(topmarv^.xpoint)+chr(topmarv^.ypoint)+chr(ord(topmarv^.richtung)));
      if not topmarv^.visible then act:=act+'@';
      changed:=true;
    end;
  end else
  if action='-' then
  begin
    mode:=false;
    act:='';
    run:=false;
  end else
  if action='+' then
  begin
    mode:=true;
    act:='';
  end else
  begin
    if (not run) and mode then
    begin
      act:=act + action;
      changed:=true;
    end;
  end;
  if run then mode_name:='Programm'
    else if mode then mode_name:='Teach-In'
      else mode_name:='Manuell ';
  textattr:=yellowonblack;
  writexy(60,4,mode_name);
end;

procedure programm.play;
var
  i, v : word;
  richt : t_richtung;
  s : string[8];
  vi,siba : boolean;
begin
  if length(act)>=4 then
  begin
    run:=true;
    v:=ord(act[1]);
    vi:=true;
    siba:=topmarv^.visible;
    topmarv^.visible:=true;
    case (ord(act[4]) mod 4) of
      0 : richt:=r;
      1 : richt:=u;
      2 : richt:=l;
      3 : richt:=o;
    end;
    topmarv^.hide;
    setze_marvin(ord(act[2]),ord(act[3]),richt);
    topmarv^.show;
    for i:=5 to length(act) do
    begin
      case act[i] of
        'L' : topmarv^.go_left;
        'R' : topmarv^.go_right;
        'D' : topmarv^.go_down;
        'U' : topmarv^.go_up;
        '@' : topmarv^.on_off;
        'r' : drehe_rechts;
        'l' : drehe_links;
        'v' : gehe_vor;
        'a' : nimm_auf;
        'h' : lege_hin;
      end;
      if not topmarv^.visible and vi then
      begin
        hinweis('Unsichtbar!');
        delay(1500);
        hinweis('');
        delay(500);
        hinweis('Unsichtbar!');
        delay(1500);
      end;
      vi:=topmarv^.visible;
      if topmarv^.visible then
      begin
        str(i-4,s);
        hinweis('..Programm lÑuft.. Schritt '+s+'!');
        delay(v*100);
      end;
    end;
    topmarv^.visible:=siba;
    run:=false;
  end else hinweis('Kein Programm geladen!>');
  hinweis('');
end;

constructor programm.init;
begin
  prg_name:='noname.prg';
  mode:=false;
  act:='';
  run:=false;
  changed:=false;
  mode_name:='Manuell ';
end;

function ask_if(frage : str80) : boolean;
var
  ch : char;
begin
  hinweis(frage);
  ch:=' ';
  while not (ch in j_n) do
  begin
    beep;
    ch:=readkey;
  end;
  case upcase(ch) of
    'J' : ask_if:=true;
    'N' : ask_if:=false;
  end;
  hinweis('');
end;

procedure ClearInputBuffer;
var
  Ch : Char;
begin
  while KeyPressed do
    Ch := ReadKey;
end;

procedure cheat;
var
  password : string;
begin
  hinweis('Passwort: ');
  setcursor(oldcursor);
  readln(password);
  setcursor(nocursor);
  if password='gohome' then
  begin
    mogeln:=true;
    altmode:=false;
    spf.farbe:=lightgreenonblack;
    spf.fill;
  end else if password='imbecity' then
  begin
    mogeln:=false;
    altmode:=false;
    spf.farbe:=yellowonblack;
    spf.fill;
  end else if password='robi' then
  begin
    altmode:=true;
    mogeln:=false;
    spf.farbe:=cyanonblack;
    spf.fill;
  end;
  hinweis('');
end;

begin
  prg.init;
  spf.init;
end.