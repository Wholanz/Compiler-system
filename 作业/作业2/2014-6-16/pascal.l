%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
#include "res.h"
extern void getId(char *);
extern void getAssignID(char *);
extern int isTypeDefineID;
extern int isVarDefineID;
extern int isFuncDefineID;
extern int isProcDefineID;
extern int isForID;
extern int procedure_cnt;
extern int name_list_cnt;
extern int isNameList;
extern int save_cnt;
extern char save[30];
extern char save1[30];
int linenum=1;
%}
digit    [0-9]
number   {digit}+
letter   [a-zA-Z]
variable {letter}+
char	 '.'
string	 '[^']+'
comment	 "(*"([^"*)"]|[\r\n])*"*)"
%%
" "		{;}
{comment}	{;}
"\n"	{linenum++;}
"."		{return DOT;}
".."	{return DOTDOT;}
"("		{
			switch(procedure_cnt){
				case type_define: isNameList=1; break;
				case function_define:	isNameList=1; break;
				case procedure_define:	isNameList=1;  break;
				case function_body: getCallerID((save_cnt==0)?save:save1); break;
				case procedure_body: getCallerID((save_cnt==0)?save:save1); break;
				case mainprogram: getCallerID((save_cnt==0)?save:save1); break;
			}
			return LP;
		}
")"		{isNameList=0; return RP;}
"[" 	{return LB;}
"]"		{return RB;}
","		{return COMMA;}
":"		{
			switch(procedure_cnt){
				case var_define:   isNameList=0; break;
				case function_define:	isNameList=0; break;
				case procedure_define:	isNameList=0; break;
			}
			return COLON;
		}
";"		{
			switch(procedure_cnt){
				case const_define: break;
				case type_define:  isTypeDefineID=1; break;
				case var_define:   isVarDefineID=1;isNameList=1; break;
				case function_define:	isNameList=1; break;
				case procedure_define:	isNameList=1; break;
			}
			return SEMI;
		}
"*"		{return MUL;}
"/"		{return DIV;}
"%"		{return MOD;}
"+"		{return PLUS;}
"-"		{return MINUS;}
"and"	{return MYAND;}
"or"	{return MYOR;}
"not"	{return MYNOT;}
">="	{return GE;}
">"		{return GT;}
"<="	{return LE;}
"<"		{return LT;}
"<>"	{return UNEQUAL;}
":="	{getAssignID((save_cnt==0)?save:save1); return ASSIGN;}
"="		{	
			switch(procedure_cnt){
				case const_define: break;
				case type_define:  isTypeDefineID=0; break;
				case var_define:   isVarDefineID=0; break;  
			}
			return EQUAL;
		}


"program"	{
				procedure_cnt=program_head;
				return PROGRAM;
			}
"const"	{procedure_cnt=const_define; /*printf("OH, CONST\n");*/ return CONST;}
"type"	{procedure_cnt=type_define; return TYPE;}
"integer"|"real"|"boolean"|"char"|"string"	{getType(yytext); /*printf("OH, SYS_TYPE\n");*/ return SYS_TYPE;}
"record"	{return RECORD;}
"var"		{
				switch(procedure_cnt){
					case program_head:
					case const_define:
					case type_define: procedure_cnt=var_define; break;
					case function_define:  isNameList=1; break;
					case procedure_define: isNameList=1; break;
				}
				isNameList=1; 
				name_list_cnt=0;
				return VAR;
			}
"function"	{procedure_cnt=function_define; isFuncDefineID=1; return FUNCTION;}
"procedure"	{procedure_cnt=procedure_define; isProcDefineID=1; return PROCEDURE;}
"array"	{return ARRAY;}

"begin"	{
			switch(procedure_cnt){
				case function_define: procedure_cnt=function_body; break;
				case procedure_define: procedure_cnt=procedure_body; break;
				default: procedure_cnt=mainprogram; break;
			}
			return MYBEGIN;
		}
"end"	{return MYEND;}
"if"	{return MYIF;}
"else"	{return MYELSE;}
"then"	{return MYTHEN;}
"while"	{return MYWHILE;}
"repeat"	{return MYREPEAT;}
"until"		{return MYUNTIL;}
"goto"	{return MYGOTO;}
"to"	{return MYTO;}
"downto"	{return MYDOWNTO;}
"case"	{return MYCASE;}
"of"	{return MYOF;}
"for"	{isForID=1; printf("FOR isForID=%d\n", isForID);return MYFOR;}
"do"	{return MYDO;}
"writeln"|"write"	{printf("OH, SYS_FUNCT\n");return SYS_FUNCT;}
"read"	{printf("READ\n");return READ;}

{char}	{getConst(yytext); return CHAR;} 
"true"|"false"	{getConst(yytext); return BOOLEAN;}
{digit}+	{/*printf("OH, INTERGER is %d\n", atoi(yytext)); */getConst(yytext); return INTEGER;}
{digit}+"."{digit}+	{/*printf("OH, REAL is %f\n", atof(yytext));*/ getConst(yytext); return REAL;}
{string}	{getConst(yytext); return STRING;}

{variable}	{/*printf("OH, ID is %s\n", yytext);*/
				getId(yytext);
				return ID;
			}
%%

int yywrap()
{	
	return 1;
}
