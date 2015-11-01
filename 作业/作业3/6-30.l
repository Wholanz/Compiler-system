%{
#include <stdio.h>
#include "6-30.h"

char * str;

%}

id [_a-zA-Z]+[a-zA-Z0-9_]*
digit [0-9]+
nat  digit+
signednNat (+|-)nat 

%%

"int" {return INT;}
"bool" {return BOOL;}
"array" {return ARRAY;}
{nat}	{return NUM;}
"of"	{return OF;}
"if"	{return IF;}
"then"	{return THEN;}
"true"  {return TRUE;}
"false" {return FALSE;}
":="	{return ASSIGN;}
{id} {return ID;}
%%
int yywrap(){
return 1;
}
