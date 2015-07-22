unit umarvin1;
(*{$D-}*)
interface

type
  t_richtung = (r,u,l,o);
  str80 = string[80];

var
  titel : str80;
  verzoegerung : word;

procedure drehe_rechts;
procedure drehe_links;
procedure gehe_vor;

procedure nimm_auf;
procedure lege_hin;

function vorne_frei : boolean;
function rechts_frei : boolean;
function links_frei : boolean;

procedure loesche_marvin;
procedure zeige_marvin;
procedure setze_marvin(x,y: byte; z: t_richtung);

procedure loesche_spf;
procedure zeige_spf;
procedure sichere_spf;
procedure lade_spf(dname : str80);

procedure hinweis(meldung : str80);
procedure fehler(meldung : str80);
procedure beep;
procedure stop;

procedure initialisierung;

procedure handsteuerung(verzoegern : byte);

implementation

uses umarvin2, crt, dos;

const
  NULL = 0;
  LeftKey = $4B00;
  RightKey = $4D00;
  UpKey = $4800;
  DownKey = $5000;
  InsKey = $5200;
  DelKey = $5300;
  ESC = $001B;
  F1 = $3B00;
  F2 = $3C00;
  F3 = $3D00;
  F4 = $3E00;
  F5 = $3F00;
  F6 = $4000;
  F7 = $4100;
  F8 = $4200;
  F9 = $4300;
  F10 = $4400;
(*  AltF1 = $6800;
  AltF2 = $6900;
  AltF3 = $6A00;
  AltF4 = $6B00;
  AltF5 = $6C00;
  AltF6 = $6D00;
  AltF7 = $6E00;
  AltF8 = $6F00;
  AltF9 = $7000;
  AltF10 = $7100;*)
  SpaceKey = $0020;


function GetKey : Word;
{ Returns the value of a key that was pressed - handles extended characters
  (function keys, etc.) by treating all characters as words.
}
var
  Ch : Char;
begin
  Ch := ReadKey;
  if Ord(Ch) = NULL then                { Extended character }
    GetKey := Word(Ord(ReadKey)) shl 8
  else
    GetKey := Ord(upcase(Ch));                  { Normal character }
end; { GetKey }

procedure schreibe_Vor;
var
  re,li,hi : char;
  count, dnum, dli, dhi, dre : word;
begin
  case z_modus of
    2: begin
      li:=links_char;
      hi:=hinten_char;
      re:=rechts_char;
      case topmarv^.richtung of
        r: dnum:=4;
        u: dnum:=3;
        l: dnum:=2;
        o: dnum:=1;
      end;
      dli:=dnum+1;
      if dli>4 then dec(dli,4);
      dhi:=dnum+2;
      if dhi>4 then dec(dhi,4);
      dre:=dnum+3;
      if dre>4 then dec(dre,4);

      if not(li in in_ch[dli]) and not(re in in_ch[dre]) then count:=1;
      if (li in in_ch[dli]) and not(re in in_ch[dre]) and not(hi in in_ch[dhi]) then count:=2;
      if not(li in in_ch[dli]) and (re in in_ch[dre]) and not(hi in in_ch[dhi]) then count:=3;
      if (li in in_ch[dli]) and (re in in_ch[dre]) and not(hi in in_ch[dhi]) then count:=4;
      if (li in in_ch[dli]) and not(re in in_ch[dre]) and (hi in in_ch[dhi]) then count:=5;
      if not(li in in_ch[dli]) and (re in in_ch[dre]) and (hi in in_ch[dhi]) then count:=6;
      if (li in in_ch[dli]) and (re in in_ch[dre]) and (hi in in_ch[dhi]) then count:=7;

      spf.feld[topmarv^.xpoint][topmarv^.ypoint]:=wall_frame[dnum][count];
    end;
    3: spf.feld[topmarv^.xpoint][topmarv^.ypoint]:=spf.dfeld[topmarv^.xpoint][topmarv^.ypoint];
  end;
  gehe_vor;
end;

procedure setze_koords;
var
  done : boolean;
  ch : char;
begin
  spf.xpoint:=topmarv^.xpoint;
  spf.ypoint:=topmarv^.ypoint;
  spf.richtung:=topmarv^.richtung;
  done:=false;
  repeat
  begin
    hinweis('Koordinaten bernommen!>');
    hinweis('Anfangs Objekt eingeben! (Paletten = 1..9, Container = A..F, Keins = 0) ');
    setcursor(oldcursor);
    ch:=readkey;
    setcursor(nocursor);
    if (upcase(ch) in inv_char) or (ch='0') then
    begin
      spf.inventar:=upcase(ch);
    end else beep;
    hinweis('');
    done:=true;
  end;
  until done;
  spf.infob;
end;

procedure setze_objekt;
var
  ch, set_ch : char;
  done : boolean;
begin
  done:=false;
  if vorne_frei then
  begin
    repeat
    begin
      hinweis('Objekt eingeben! (Paletten = 1..9, Container = A..F, L”schen = 0) ');
      setcursor(oldcursor);
      ch:=readkey;
      setcursor(nocursor);
      if (upcase(ch) in inv_char) or (ch='0') then
      begin
        topmarv^.inventar:=upcase(ch);
        lege_hin;
      end else beep;
      hinweis('');
      done:=true;
    end;
    until done;
  end else beep;
end;

procedure setze_farbe;
var
  done : boolean;
  s : string;
  w, i, oldattr : word;
  ch : char;
begin
  if mogeln then fehler('Im Mogelmodus ist die Farbwahl nicht m”glich!>')
  else begin
    ch:=' ';
    w:=0;
    done:=false;
    repeat
    begin
      hinweis('Bitte Farbengenerierungscode eingeben: ');
      setcursor(oldcursor);
      readln(s);
      setcursor(nocursor);
      for i:=1 to length(s) do
        w:=ord(s[i])+w;
      w:=w mod 128;
      if (w mod 17)=0 then inc(w);
      if (s='') or (w=lightgreenonblack) then w:=yellowonblack;
      if (s='') or (w=CyanOnBlack) then w:=CyanOnBlack;
      hinweis('Ihre Farbwahl: ');
      oldattr:=textattr;
      textattr:=w;
      write('Test');
      textattr:=oldattr;
      if ask_if('                    Farbe behalten?') then
      begin
        spf.farbe:=w;
        spf.fill;
      end;
      done:=true;
    end;
    until done;
  end;
end;

procedure shoot;
var
  i,j,x,y : word;
  ri : t_richtung;
begin
  j:=verzoegerung;
  verzoegerung:=5;
  x:=spf.xpoint;
  y:=spf.ypoint;
  ri:=spf.richtung;
  spf.xpoint:=topmarv^.xpoint;
  spf.ypoint:=topmarv^.ypoint;
  spf.richtung:=topmarv^.richtung;
  newmarv;
  while vorne_frei do gehe_vor;
  for i := 1000 downto 100 do
  begin
    sound(i);
    delay(10);
    nosound;
    delay(5);
  end;
  nosound;
  delmarv;
  spf.xpoint:=x;
  spf.ypoint:=y;
  spf.richtung:=ri;
  spf.infob;
  verzoegerung:=j;
end;

function hinten_frei : boolean;
var
  temp_richtung : t_richtung;
begin
  temp_richtung:=topmarv^.richtung;
  topmarv^.richtung:=back;
  hinten_frei:=vorne_frei;
  topmarv^.richtung:=temp_richtung;
end;

procedure gehe_Zurueck;
begin
  if hinten_frei then
  begin
    with topmarv^ do
    begin
      hide;
      case richtung of
        l: inc(xpoint);
        o: inc(ypoint);
        r: dec(xpoint);
        u: dec(ypoint);
      end;
      show;
    end;
    prg.teach('z');
    spf.infob;
    delay(verzoegerung*100);
  end else beep;
end;

procedure aendere_spf;
var
  key : word;
  d,done : boolean;
begin
  done:=false;
  zeichnen:=true;
  z_modus:=1;
  spf.status2;
  spf.menu2;
  spf.infoa;
  spf.infob;
  repeat
    clearinputbuffer;
    key := getKey;
    case key of
      LeftKey: topmarv^.go_left;
      RightKey: topmarv^.go_right;
      DownKey: topmarv^.go_down;
      UpKey: topmarv^.go_up;
      InsKey: newmarv;
      DelKey: delmarv;
      ESC: halt(1);
      F1: stop;
      F2: setze_koords;
      F3: begin setze_marvin(0,0,o); spf.fill; end;
      F4: setze_objekt;
      F5: setze_farbe;
      F7: sichere_spf;
      F8: lade_spf('');
      F9: loesche_spf;
      F10: Done := true;
      ord('L'): drehe_Links;
      ord('R'): drehe_Rechts;
      ord('V'): schreibe_Vor;
      ord('Z'): ch_modus;
    else
      Beep;
    end;
  until Done;
  zeichnen:=false;
  spf.status1;
  spf.menu1;
  spf.infoa;
  spf.infob;
end;

function ask_end: boolean;
begin
  if ask_if('Programm Marvin beenden?') then ask_end:=true else
    ask_end:=false;
end;

procedure auto;
var
  key : word;
  d,done : boolean;
  s : string;
  i : longint;
begin
  done:=false;
  zeichnen:=false;
  repeat
    clearinputbuffer;
    key := getKey;
    case key of
      LeftKey: if altmode then topmarv^.go_left else drehe_Links;
      RightKey: if altmode then topmarv^.go_right else drehe_Rechts;
      DownKey: if altmode then topmarv^.go_down else if mogeln then gehe_Zurueck;
      UpKey: if altmode then topmarv^.go_up else gehe_Vor;
      InsKey: newmarv;
      DelKey: delmarv;
      ESC: halt(1);
      F1: topmarv^.on_off;
      F2: prg.save;
      F3: prg.load;
      F4: prg.new;
      F5: prg.teach('#');
      F6: prg.play;
      F7: spf.save;
      F8: spf.load('');
      F9: aendere_spf;
      F10: Done := ask_end;
      ord('L'): drehe_Links;
      ord('R'): drehe_Rechts;
      ord('V'): gehe_Vor;
      ord('H'): lege_Hin;
      ord('A'): nimm_Auf;
      ord('E'): Done := ask_end;
      ord('/') : cheat;
      SpaceKey: shoot;
    else
      Beep;
    end;
  until Done;
  spf.done;
end;

procedure drehe_rechts;
begin
  with topmarv^ do
  begin
    richtung:=right;
    show;
  end;
  prg.teach('r');
  writexy(60,8,richt_char(topmarv^.richtung));
  delay(verzoegerung*100);
end;

procedure drehe_links;
begin
  with topmarv^ do
  begin
    richtung:=left;
    show;
  end;
  prg.teach('l');
  writexy(60,8,richt_char(topmarv^.richtung));
  delay(verzoegerung*100);
end;

procedure gehe_vor;
begin
  if vorne_frei then
  begin
    with topmarv^ do
    begin
      hide;
      case richtung of
        l: dec(xpoint);
        o: dec(ypoint);
        r: inc(xpoint);
        u: inc(ypoint);
      end;
      show;
    end;
    prg.teach('v');
    spf.infob;
    delay(verzoegerung*100);
  end else beep;
end;

procedure nimm_auf;
begin
  with topmarv^ do
  begin
    case richtung of
      l: begin
        if spf.feld[xpoint-1][ypoint] in inv_char then
        begin
          if (spf.feld[xpoint-1][ypoint] in inv_cont) and (inventar='0') then
          begin
            inventar:=spf.feld[xpoint-1][ypoint];
            spf.feld[xpoint-1][ypoint]:=spf.dfeld[xpoint-1][ypoint];
            writechar(xpoint+spf.lox-1,ypoint+spf.loy,1,spf.feld[xpoint-1][ypoint],spf.farbe);
          end else
          if (spf.feld[xpoint-1][ypoint] in inv_num) and (inventar in inv_nimm) then
          begin
            inventar:=chr(ord(inventar)+1);
            spf.feld[xpoint-1][ypoint]:=chr(ord(spf.feld[xpoint-1][ypoint])-1);
            if spf.feld[xpoint-1][ypoint]='0' then spf.feld[xpoint-1][ypoint]:=spf.dfeld[xpoint-1][ypoint];
            writechar(xpoint+spf.lox-1,ypoint+spf.loy,1,spf.feld[xpoint-1][ypoint],spf.farbe);
          end;
        end;
      end;
      o: begin
        if spf.feld[xpoint][ypoint-1] in inv_char then
        begin
          if (spf.feld[xpoint][ypoint-1] in inv_cont) and (inventar='0') then
          begin
            inventar:=spf.feld[xpoint][ypoint-1];
            spf.feld[xpoint][ypoint-1]:=spf.dfeld[xpoint][ypoint-1];
            writechar(xpoint+spf.lox,ypoint+spf.loy-1,1,spf.feld[xpoint][ypoint-1],spf.farbe);
          end else
          if (spf.feld[xpoint][ypoint-1] in inv_num) and (inventar in inv_nimm) then
          begin
            inventar:=chr(ord(inventar)+1);
            spf.feld[xpoint][ypoint-1]:=chr(ord(spf.feld[xpoint][ypoint-1])-1);
            if spf.feld[xpoint][ypoint-1]='0' then spf.feld[xpoint][ypoint-1]:=spf.dfeld[xpoint][ypoint-1];
            writechar(xpoint+spf.lox,ypoint+spf.loy-1,1,spf.feld[xpoint][ypoint-1],spf.farbe);
          end;
        end;
      end;
      r: begin
        if spf.feld[xpoint+1][ypoint] in inv_char then
        begin
          if (spf.feld[xpoint+1][ypoint] in inv_cont) and (inventar='0') then
          begin
            inventar:=spf.feld[xpoint+1][ypoint];
            spf.feld[xpoint+1][ypoint]:=spf.dfeld[xpoint+1][ypoint];
            writechar(xpoint+spf.lox+1,ypoint+spf.loy,1,spf.feld[xpoint+1][ypoint],spf.farbe);
          end else
          if (spf.feld[xpoint+1][ypoint] in inv_num) and (inventar in inv_nimm) then
          begin
            inventar:=chr(ord(inventar)+1);
            spf.feld[xpoint+1][ypoint]:=chr(ord(spf.feld[xpoint+1][ypoint])-1);
            if spf.feld[xpoint+1][ypoint]='0' then spf.feld[xpoint+1][ypoint]:=spf.dfeld[xpoint+1][ypoint];
            writechar(xpoint+spf.lox+1,ypoint+spf.loy,1,spf.feld[xpoint+1][ypoint],spf.farbe);
          end;
        end;
      end;
      u: begin
        if spf.feld[xpoint][ypoint+1] in inv_char then
        begin
          if (spf.feld[xpoint][ypoint+1] in inv_cont) and (inventar='0') then
          begin
            inventar:=spf.feld[xpoint][ypoint+1];
            spf.feld[xpoint][ypoint+1]:=spf.dfeld[xpoint][ypoint+1];
            writechar(xpoint+spf.lox,ypoint+spf.loy+1,1,spf.feld[xpoint][ypoint+1],spf.farbe);
          end else
          if (spf.feld[xpoint][ypoint+1] in inv_num) and (inventar in inv_nimm) then
          begin
            inventar:=chr(ord(inventar)+1);
            spf.feld[xpoint][ypoint+1]:=chr(ord(spf.feld[xpoint][ypoint+1])-1);
            if spf.feld[xpoint][ypoint+1]='0' then spf.feld[xpoint][ypoint+1]:=spf.dfeld[xpoint][ypoint+1];
            writechar(xpoint+spf.lox,ypoint+spf.loy+1,1,spf.feld[xpoint][ypoint+1],spf.farbe);
          end;
        end;
      end;
    end;
    writexy(60,10,inventar);
    prg.teach('a');
  end;
end;

procedure lege_hin;
begin
  with topmarv^ do
  begin
    if vorne_frei then
    begin
      if not zeichnen then
      case richtung of
        l: begin
          if inventar in inv_cont then
          begin
            spf.feld[xpoint-1][ypoint]:=inventar;
            writechar(xpoint+spf.lox-1,ypoint+spf.loy,1,spf.feld[xpoint-1][ypoint],spf.farbe);
            inventar:='0';
          end else
          if inventar in inv_num then
          begin
            spf.feld[xpoint-1][ypoint]:='1';
            writechar(xpoint+spf.lox-1,ypoint+spf.loy,1,spf.feld[xpoint-1][ypoint],spf.farbe);
            inventar:=chr(ord(inventar)-1);
          end;
        end;
        o: begin
          if inventar in inv_cont then
          begin
            spf.feld[xpoint][ypoint-1]:=inventar;
            writechar(xpoint+spf.lox,ypoint+spf.loy-1,1,spf.feld[xpoint][ypoint-1],spf.farbe);
            inventar:='0';
          end else
          if inventar in inv_num then
          begin
            spf.feld[xpoint][ypoint-1]:='1';
            writechar(xpoint+spf.lox,ypoint+spf.loy-1,1,spf.feld[xpoint][ypoint-1],spf.farbe);
            inventar:=chr(ord(inventar)-1);
          end;
        end;
        r: begin
          if inventar in inv_cont then
          begin
            spf.feld[xpoint+1][ypoint]:=inventar;
            writechar(xpoint+spf.lox+1,ypoint+spf.loy,1,spf.feld[xpoint+1][ypoint],spf.farbe);
            inventar:='0';
          end else
          if inventar in inv_num then
          begin
            spf.feld[xpoint+1][ypoint]:='1';
            writechar(xpoint+spf.lox+1,ypoint+spf.loy,1,spf.feld[xpoint+1][ypoint],spf.farbe);
            inventar:=chr(ord(inventar)-1);
          end;
        end;
        u: begin
          if inventar in inv_cont then
          begin
            spf.feld[xpoint][ypoint+1]:=inventar;
            writechar(xpoint+spf.lox,ypoint+spf.loy+1,1,spf.feld[xpoint][ypoint+1],spf.farbe);
            inventar:='0';
          end else
          if inventar in inv_num then
          begin
            spf.feld[xpoint][ypoint+1]:='1';
            writechar(xpoint+spf.lox,ypoint+spf.loy+1,1,spf.feld[xpoint][ypoint+1],spf.farbe);
            inventar:=chr(ord(inventar)-1);
          end;
        end;
      end else
      case richtung of
        l: begin
          spf.feld[xpoint-1][ypoint]:=inventar;
          if spf.feld[xpoint-1][ypoint]='0' then spf.feld[xpoint-1][ypoint]:=spf.dfeld[xpoint-1][ypoint];
          writechar(xpoint+spf.lox-1,ypoint+spf.loy,1,spf.feld[xpoint-1][ypoint],spf.farbe);
          inventar:='0';
        end;
        o: begin
          spf.feld[xpoint][ypoint-1]:=inventar;
          if spf.feld[xpoint][ypoint-1]='0' then spf.feld[xpoint][ypoint-1]:=spf.dfeld[xpoint][ypoint-1];
          writechar(xpoint+spf.lox,ypoint+spf.loy-1,1,spf.feld[xpoint][ypoint-1],spf.farbe);
          inventar:='0';
        end;
        r: begin
          spf.feld[xpoint+1][ypoint]:=inventar;
          if spf.feld[xpoint+1][ypoint]='0' then spf.feld[xpoint+1][ypoint]:=spf.dfeld[xpoint+1][ypoint];
          writechar(xpoint+spf.lox+1,ypoint+spf.loy,1,spf.feld[xpoint+1][ypoint],spf.farbe);
          inventar:='0';
        end;
        u: begin
          spf.feld[xpoint][ypoint+1]:=inventar;
          if spf.feld[xpoint][ypoint+1]='0' then spf.feld[xpoint][ypoint+1]:=spf.dfeld[xpoint][ypoint+1];
          writechar(xpoint+spf.lox,ypoint+spf.loy+1,1,spf.feld[ypoint+1][xpoint],spf.farbe);
          inventar:='0';
        end;
      end;
    end else if (vorne_char in inv_nimm) and (inventar in inv_num) then
    begin
      case richtung of
        l: begin
          spf.feld[ypoint][xpoint-1]:=chr(ord(spf.feld[ypoint][xpoint-1])+1);
          writechar(xpoint+spf.lox-1,ypoint+spf.loy,1,spf.feld[ypoint][xpoint-1],spf.farbe);
          inventar:=chr(ord(inventar)-1);
        end;
        o: begin
          spf.feld[ypoint-1][xpoint]:=chr(ord(spf.feld[ypoint-1][xpoint])+1);
          writechar(xpoint+spf.lox,ypoint+spf.loy-1,1,spf.feld[ypoint-1][xpoint],spf.farbe);
          inventar:=chr(ord(inventar)-1);
        end;
        r: begin
          spf.feld[ypoint][xpoint+1]:=chr(ord(spf.feld[ypoint][xpoint+1])+1);
          writechar(xpoint+spf.lox+1,ypoint+spf.loy,1,spf.feld[ypoint][xpoint+1],spf.farbe);
          inventar:=chr(ord(inventar)-1);
        end;
        u: begin
          spf.feld[ypoint+1][xpoint]:=chr(ord(spf.feld[ypoint+1][xpoint])+1);
          writechar(xpoint+spf.lox,ypoint+spf.loy+1,1,spf.feld[ypoint+1][xpoint],spf.farbe);
          inventar:=chr(ord(inventar)-1);
        end;
      end;
    end;
    prg.teach('v');
    writexy(60,10,inventar);
  end;
end;

function vorne_frei : boolean;
begin
  with topmarv^ do
  begin
    if (not zeichnen) and (not mogeln) then
    case richtung of
      l: begin
        if xpoint > 1 then
          vorne_frei:= spf.feld[xpoint-1][ypoint] in frei
        else vorne_frei:=false;
      end;
      o: begin
        if ypoint > 1 then
          vorne_frei:= spf.feld[xpoint][ypoint-1] in frei
        else vorne_frei:=false;
      end;
      r: begin
        if xpoint < spf.maxx then
          vorne_frei:= spf.feld[xpoint+1][ypoint] in frei
        else vorne_frei:=false;
      end;
      u: begin
        if ypoint < spf.maxy  then
          vorne_frei:= spf.feld[xpoint][ypoint+1] in frei
        else vorne_frei:=false;
      end;
    end
    else case richtung of
      l: vorne_frei:=xpoint > 1;
      o: vorne_frei:=ypoint > 1;
      r: vorne_frei:=xpoint < spf.maxx;
      u: vorne_frei:=ypoint < spf.maxy;
    end;
  end;
end;

function rechts_frei : boolean;
var
  temp_richtung : t_richtung;
begin
  temp_richtung:=topmarv^.richtung;
  topmarv^.richtung:=right;
  rechts_frei:=vorne_frei;
  topmarv^.richtung:=temp_richtung;
end;

function links_frei : boolean;
var
  temp_richtung : t_richtung;
begin
  temp_richtung:=topmarv^.richtung;
  topmarv^.richtung:=left;
  links_frei:=vorne_frei;
  topmarv^.richtung:=temp_richtung;
end;

procedure loesche_marvin;
begin
  topmarv^.hide;
end;

procedure zeige_marvin;
begin
  topmarv^.show;
end;

procedure setze_marvin(x,y: byte; z: t_richtung);
var
  q : boolean;
  ch : char;
  s : string;
  c : integer;
begin
  q:=((x=0) and (y=0));
  while not ((x<spf.maxx) and (x>0)) do
  begin
    fehler('X-Wert : ');
    setcursor(oldcursor);
    readln(s);
    setcursor(nocursor);
    val(s,x,c);
    if c<>0 then x:=0;
    hinweis('');
  end;
  while not ((y<spf.maxy) and (y>0)) do
  begin
    fehler('Y-Wert : ');
    setcursor(oldcursor);
    readln(s);
    setcursor(nocursor);
    val(s,y,c);
    if c<>0 then y:=0;
    hinweis('');
  end;
  if q then
  begin
    ch:=' ';
    while not (ch in richt_set) do
    begin
      fehler('Richtung (r,u,l,o): ');
      setcursor(oldcursor);
      ch:=readkey;
      setcursor(nocursor);
      hinweis('');
    end;
    z:=char_richt(ch);
  end;
  with topmarv^ do
  begin
    xpoint:=x;
    ypoint:=y;
    richtung:=z;
  end;
  spf.infob;
end;

procedure loesche_spf;
begin
  if ask_if('Spielfeld L”schen?') then begin
    spf.reset;
    spf.fill;
  end;
end;

procedure zeige_spf;
begin
  spf.fill;
end;

procedure sichere_spf;
begin
  spf.save;
end;

procedure lade_spf(dname : str80);
begin
  spf.load(dname);
end;

procedure hinweis(meldung : str80);
var
  i : word;
  s : boolean;
begin
  i:=1;
  textattr:=whiteonblack;
  while meldung[1]=' ' do
  begin
    delete(meldung,1,1);
    inc(i);
  end;
  s:=meldung[length(meldung)]='>';
  if s then delete(meldung,length(meldung),1);
  writexy(i,23,meldung);
  clreol;
  if s then stop;
end;

procedure fehler(meldung : str80);
begin
  beep;
  hinweis(meldung);
end;

procedure beep;
begin
  sound(300); delay(200); nosound;
end;

procedure stop;
var
  ch : char;
begin
  clearinputbuffer;
  ch:=readkey;
end;

procedure initialisierung;
begin
  clrscr;
  oldmode:=lastmode;
  textmode(3);
  setcursor(nocursor);
  zeichnen:=false;
  spf.status1;
  spf.menu1;
  spf.infoa;
  spf.frames;
  spf.fill;
  spf.writename;
  if topmarv=nil then newmarv else spf.infob;
end;

procedure handsteuerung(verzoegern : byte);
begin
  verzoegerung:=verzoegern;
  initialisierung;
  auto;
end;

begin
  verzoegerung:=0;
end.