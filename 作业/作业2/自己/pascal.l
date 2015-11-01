%{
#include <stdio.h>
#include <ctype.h>
%}
digit [0-9]
nat {digit}+
signedNat [+-]?nat
integer {signedNat}
real {signedNat}("."{nat})?(E{signedNat})?
char "'"."'"
string "'".*"'" 
id [a-zA-Z_]+[0-9a-zA-Z_]*

%%

"(" {return(LP);}
")" {return(RP);}
"[" {return(LB);}
"]" {return(RB);}
"." {return(DOT);}
";" {return(COMMA);}
"," {return(COLON);}
"*" {return(MUL);}
"/" {return(DIV);}
"+" {return(PLUS);}
"-" {return(MINUS);}
":" {return(SEMI);}
{id}  	{return(ID);}
">=" 	{return(GE);}
">" 	{return(GT);}
"<=" 	{return(LE);}
"<" 	{return(LT);}
"=" 	{return(EQUAL);}
":=" 	{return(ASSIGN);}
"false" {return(SYS_CON);}
"maxint" 	{return(SYS_CON);}
"true"	 	{return(SYS_CON);}
"abs" 		{return(SYS_FUNCT);}
"chr" 		{return(SYS_FUNCT);}
"odd" 		{return(SYS_FUNCT);}
"ord" 		{return(SYS_FUNCT);}
"pred" 		{return(SYS_FUNCT);}
"sqr" 		{return(SYS_FUNCT);}
"sqrt" 		{return(SYS_FUNCT);}
"succ" 		{return(SYS_FUNCT);}
"write"		{return(SYS_PROC);}
"writeln" 	{return(SYS_PROC);}
"boolean"	{return(SYS_TYPE);}
"char" 		{return(SYS_TYPE);}
"integer" 	{return(SYS_TYPE);}
"real" 		{return(SYS_TYPE);}
"program"	{return(PROGRAM);}
"const"		{return(CONST);}
"name"		{return(NAME);}
"type"		{return(TYPE);}
"array"		{return(ARRAY);}

"var"	{return(VAR);}
"function"	{return(FUNCTION);}
"procedure"	{return(PROCEDURE);}
"begin"	{return(BEGIN);}
"end"	{return(END);}
"read"	{return(READ);}
"if"	{return(IF);}
"then"	{return(THEN);}
"else"	{return(ELSE);}
"repeat"	{return(REPEAT);}
"while"	{return(WHILE);}
"for"	{return(FOR);}
"to"	{return(TO);}
"downto"	{return(DOWNTO);}
"case"	{return(CASE);}
"of"	{return(OF);}
"end"	{return(END);}
"goto"	{return(GOTO);}
"not"	{return(NOT);}
{integer} {return(INTEGER);}
{real} 	{return(REAL);}
{string} {return(STRING);}
{char}   {return(CHAR);}
"and"    {return(AND);}
"do"	 {return(DO);}
"mod"    {return(MOD);}
"or"     {return(OR);}
"<>"	 {return(UNEQUAL);}
"until"  {return(UNTIL);}





%%

main(){
	yylex();
	return 0;
}

