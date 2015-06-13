--------------------------------------------------------
--  Richard Delgado
Ñ-  Bases de Datos 2
Ñ-  ECCI UCR 
Julio Calderón
--------------------------------------------------------

--------------------------------------------------------
--  DDL for Type GEOMETRY
--------------------------------------------------------

  CREATE OR REPLACE TYPE "GEOMETRY" as object (
  
    label varchar2(20),
    
    member function display return varchar2,
    
    member function area return real
    
) not INSTANTIABLE not final
    
    
/
CREATE OR REPLACE TYPE BODY "GEOMETRY" as

member function display return varchar2 as
  begin
    return label;
  end display;

member function area return real as
  begin
    return null;
  end area;

end;

/
--------------------------------------------------------
--  DDL for Type GEOMETRY_LIST
--------------------------------------------------------

  CREATE OR REPLACE TYPE "GEOMETRY_LIST" as table of geometry

/
--------------------------------------------------------
--  DDL for Type LINE_TYPE
--------------------------------------------------------

  CREATE OR REPLACE TYPE "LINE_TYPE" as table of varchar2(100)

/
--------------------------------------------------------
--  DDL for Type PLOT
--------------------------------------------------------

  CREATE OR REPLACE TYPE "PLOT" as object (

  max_x int,
  max_y int,
  screen line_type,

  constructor function plot(self in out nocopy plot, max_x int, max_y int) return self as result,
  
  member function transform(x point) return point,
  
  member procedure add_element(x point, symbol char := '*'),
  
  member procedure add_element(r rectangle, symbol char := '-'),

  member procedure reset,
 
  member procedure display

)
/
CREATE OR REPLACE TYPE BODY "PLOT" as

  constructor function plot(self in out nocopy plot, max_x int, max_y int) return self as result is
     tmp varchar2(100);
     tmp2 varchar2(100);
     j int;
     i int;
  begin
     self.max_x := max_x;
     self.max_y := max_y;
     
     for j in 1..max_x loop
        tmp := tmp || '--|';
        tmp2 := tmp2 || '  '||mod(j,10);
     end loop;
     
     tmp := ' |'||tmp;
     tmp2 := '  '||tmp2;
     
     self.screen := line_type();
     self.screen.extend((2*max_y)+2);
     
     self.screen(1) := tmp2;
     self.screen(2) := tmp;
     
     j := 3;
     i := 1;
     while (i <= max_y) loop
        self.screen(j+1)   :=  mod(i,10)||'-' ||rpad(' ', length(tmp)-3)||'|';
        self.screen(j) :=  ' |' ||rpad(' ', length(tmp)-3)||'|';
        
        j := j + 2;
        i := i + 1;
     end loop;
        
     return;
  end plot;
  
  member function transform(x point) return point is
     pos_x int := (x.x * 3) + 2;
     pos_y int := (x.y * 2) + 2;
  begin
     return (point(pos_x,pos_y));
  end transform;
 
  member procedure add_element(x point, symbol char := '*') is
     a point := transform(x);
     tmp varchar2(100);
  begin
     tmp := self.screen(a.y);
     
     tmp := substr(tmp,1,a.x-1)||symbol||substr(tmp,a.x+1);
     
     self.screen(a.y) := tmp;
  end add_element;
  
  
  member procedure add_element(r rectangle, symbol char := '-') is     
     v_s1 char := '+';
     v_s2 char := '|';
     v_tmp varchar2(100);
     v_tmp1 varchar2(100);
     v_tmp2 varchar2(100);
     
     v_p point;
     v_u point;
     v_o point;
     v_l point;
     v_r point;
     
     v_initpos int;
     v_chars   int;
  begin
     if symbol != '-' then
        v_s1 := symbol;
        v_s2 := symbol;
     end if;
  
     v_p := point(r.upper_left.x + r.width, r.upper_left.y);
     v_l := transform(r.upper_left);
     v_r := transform(v_p);
     
    
     v_tmp1 := v_s1||rpad(symbol,abs(v_r.x-v_l.x)-1,symbol)||v_s1; 
     v_tmp2 := v_s2||rpad(' ',abs(v_r.x-v_l.x)-1,' ')||v_s2;
     
     /* writes the first edge */
     v_tmp := screen(v_r.y);
     v_tmp := transparent_replace(v_tmp,v_tmp1,v_l.x);
     screen(v_r.y) := v_tmp;
     
     v_o := transform(r.lower_right); 
     for i in v_o.y+1..v_r.y-1 loop
        v_tmp := screen(i);
        v_tmp := transparent_replace(v_tmp, v_tmp2, v_l.x);
        screen(i) := v_tmp;
     end loop; 
     
     
     /*writes the last edge */
     v_tmp := screen(v_o.y);
     v_tmp := transparent_replace(v_tmp,v_tmp1,v_l.x);
     screen(v_o.y) := v_tmp;
     
  end add_element;
  
  
  member procedure reset is
     tmp plot := plot(self.max_x,self.max_y);
  begin
     self := tmp;
  end reset;
 
  member procedure display as
    tmp varchar2(100);
  begin
    for i in reverse 1..screen.count loop
      dbms_output.put_line(screen(i));
    end loop;

  end display;

end;

/
--------------------------------------------------------
--  DDL for Type POINT
--------------------------------------------------------

  CREATE OR REPLACE TYPE "POINT" under geometry (
   x real,
   y real,
   
   overriding member function display return varchar2,
   
   member function distance(z point) return real,
   
   member procedure normalize(x2 point, uleft out point, lright out point),
   
   constructor function point(self in out nocopy point,
          x real, y real) return self as result
   
)
/
CREATE OR REPLACE TYPE BODY "POINT" as

overriding member function display return varchar2 as
     tmp varchar2(20) := null;
  begin
     if self.label is not null then
        tmp := label||':';
     end if;   
     return tmp || '(' || self.x || ',' || self.y || ')'; -- (x,y)
  end display;

member function distance(z point) return real as
  begin
    return sqrt (power(self.x - z.x, 2) + 
                 power(self.y - z.y, 2));
  end distance;
  
member procedure normalize(x2 point, 
                             uleft out point,
                             lright out point) is
     v_ul point := point(0,0);
     v_lr point := point(0,0); 
  begin
     v_ul.x := get_min(self.x, x2.x);
     v_ul.y := get_max(self.y, x2.y);
     
     v_lr.x := get_max(self.x, x2.x);
     v_lr.y := get_min(self.y, x2.y); 
     
     uleft := v_ul;
     lright := v_lr;
  end normalize; 
  
  
constructor function point(self in out nocopy point,
          x real, y real) return self as result is
  begin
     self.label := null;
     self.x := x;
     self.y := y;
     return;
  end point;

end;

/
--------------------------------------------------------
--  DDL for Type RECTANGLE
--------------------------------------------------------

  CREATE OR REPLACE TYPE "RECTANGLE" under geometry (

/*

     |    El modelo de rect‡ngulo se construye
   4 -    a partir de dos puntos (UL,LR) = Upper Left, Lower Right      
     |
   3 -     UL-------+     
     |     |        |
   2 -     |        |
     |     |        |
   1 -     +-------LR
     |
     ---|--|--|--|--|--|--|--|-->
     0  1  2  3  4  5  6  7  8

*/
  
    upper_left point,
    lower_right point,
    
    overriding member function display return varchar2,
    
    member function height return real,
    member function width return real,
    
    overriding member function area return real,
    
    constructor function rectangle (self in out nocopy rectangle,
             upper_left point,
             lower_right point) return self as result,
             
    constructor function rectangle (self in out nocopy rectangle,
             label varchar2,
             upper_left point,
             lower_right point) return self as result,         
    
    /* retorna verdadero si el punto x1 esta dentro del rect‡ngulo
       actual, incluyendo el borde */
    member function inside(x1 point) return boolean,
    
    /* retorna el rectangulo que describe la interseccion entre
       self y r2.  Si no hay intersecci—n devuelve
       un rectangulo [(0,0),(0,0)] */
    member function overlap(r2 rectangle) return rectangle
    
)
/
CREATE OR REPLACE TYPE BODY "RECTANGLE" as

overriding member function display return varchar2 as
  begin
    if self.label is null then
       return '[' || upper_left.display ||','||lower_right.display ||']'; -- [(x1,y1),(x2,y2)]
    else
       return self.label ||':[' || upper_left.display ||','||lower_right.display ||']';
    end if;   
  end display;

member function height return real as
  begin
    return upper_left.y - lower_right.y;
  end height;

member function width return real as
  begin
    return lower_right.x - upper_left.x;
  end width;

overriding member function area return real as
  begin
    return self.width*self.height;
  end area;
  
  
constructor function rectangle (self in out nocopy rectangle,
             label varchar2,
             upper_left point,
             lower_right point) return self as result is
    tmp_rec rectangle;
begin
    tmp_rec := rectangle(upper_left,lower_right); -- so we get normalized ul, lr points.
    tmp_rec.label := label;
    self := tmp_rec;
    return;
end rectangle;
             



constructor function rectangle (self in out nocopy rectangle,
             upper_left point,
             lower_right point) return self as result is
 
   v_ul point := point (0,0);
   v_lr point := point (0,0);
   tmp point := upper_left;
begin
   tmp.normalize(lower_right, v_ul, v_lr);
   self.label := null;
   self.upper_left := v_ul;
   self.lower_right := v_lr;
   return;
   
end rectangle;
  

member function inside(x1 point) return boolean as
  begin
    if (x1.x >= upper_left.x and x1.x <= lower_right.x) AND
       (x1.y <= upper_left.y and x1.y >= lower_right.y) then
       return true;
    else
       return false;
    end if;   
  end inside;
  
member function overlap(r2 rectangle) return rectangle is
   v_ul point := point(0,0);
   v_lr point := point(0,0);
   r rectangle := rectangle(v_ul,v_lr);
begin
   v_ul.x := get_max(self.upper_left.x, r2.upper_left.x);
   v_ul.y := get_min(self.upper_left.y, r2.upper_left.y);
   
   v_lr.x := get_min(self.lower_right.x, r2.lower_right.x);
   v_lr.y := get_max(self.lower_right.y, r2.lower_right.y);
   
   if (v_lr.x - v_ul.x) > 0 and
      (v_ul.y - v_lr.y) > 0 then
      r := rectangle(v_ul, v_lr);
   end if;
   return r;
end overlap;

end;

/
--------------------------------------------------------
--  DDL for Type R_TREE
--------------------------------------------------------

  CREATE OR REPLACE TYPE "R_TREE" as object (

   /* agregar aqui las variables de instancia que 
      considere necesarias */
      
   dummy number, -- eliminar este, s—lo es un ejemplo
   
   constructor function r_tree (self in out nocopy r_tree) return self as result,
   
   member procedure index_reset,
   
   member procedure insert_element(apoint point),
   
   member procedure remove_element(apoint point),
   
   member function range_query(query_rect rectangle) return geometry_list,
   
   member function nn_query(query_point point, num_results number := 1) return geometry_list,
   
   member function get_MBR_list return geometry_list
)   

/
--------------------------------------------------------
--  DDL for Function GET_MAX
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "GET_MAX" (a in real, b in real 
       -- mode 0 = max, 1 = min 
) return number as 
begin
  -- mode 0 = max, 1 = min 
  return min_max(a, b, 0);
end get_max;

/
--------------------------------------------------------
--  DDL for Function GET_MIN
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "GET_MIN" (a in real, b in real 
       -- mode 0 = max, 1 = min 
) return number as 
begin
  -- mode 0 = max, 1 = min 
  return min_max(a, b, 1);
end get_min;

/
--------------------------------------------------------
--  DDL for Function MIN_MAX
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "MIN_MAX" (a in real, b in real, 
                                    pmode int := 0 -- mode 0 = max, 1 = min 
) return number as 
  v_min real;
  v_max real;
begin
  if a < b then
     v_min := a;
     v_max := b;
  else
     v_min := b;
     v_max := a; 
  end if;
  
  if pmode = 0 then
     return v_max;
  else
     return v_min;
  end if;   
end min_max;

/
--------------------------------------------------------
--  DDL for Function TRANSPARENT_REPLACE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "TRANSPARENT_REPLACE" 
(string in varchar2, segment in varchar2, startpos in int := 1)  return varchar2 as
   v_head varchar2(2000) := substr(string,1,startpos-1);
   v_tail varchar2(2000) := substr(string,startpos+length(segment));
   
   v_conflict varchar2(2000) := substr(string,startpos,length(segment));
   
   v_result varchar2(2000);
begin
  for i in 1..length(segment) loop
    if substr(v_conflict,i,1) != ' ' then
       v_result := v_result ||  substr(v_conflict,i,1);
    else
       v_result := v_result ||  substr(segment,i,1);
    end if;
  end loop;   
  return v_head||v_result||v_tail;
end transparent_replace;

/
--------------------------------------------------------
--  DDL for Procedure PRINT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "PRINT" (line varchar2)is
begin
   dbms_output.put_line(line);
end;

/
