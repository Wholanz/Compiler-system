%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "macro.h"
#include "yyout.h"

extern YYSTYPE	yylval;
int Keytable_size = 0;

%}

letter	[_a-zA-Z]
alnum	[_a-zA-Z0-9]
dec		[0-9]
hex		[0-9a-fA-F]
oct		[0-7]

%%
"{"		{
			int c;
		
			while ((c = input()))
			{
				if (c == '}')
				{
					break;
				}
				else if (c == '\n')
				{
					line_no ++;
				}
			}

			if (c == EOF)
				parse_error("Unexpected EOF.","");
		}

[1-9]+{dec}*		{
						yylval.num = stoi(yytext, 10);						
						return cINTEGER;
					}
					
0{oct}*				{
						yylval.num = stoi(yytext, 8);						
						return cINTEGER;
					}
					
0(x|X){hex}+		{
						yylval.num = stoi(yytext, 16);
						return cINTEGER;
					}

{dec}+(\.{dec}+)?([E|e][+\-]?{dec}+)?	{
						strncpy(yylval.p_char, yytext, NAME_LEN);						
						return cREAL;
					}
					
'([^']|\")'			{
						strncpy(yylval.p_char, yytext, NAME_LEN);						
						return cCHAR;
					}
					
\'(\\.|[^\'])(\\.|[^\'])+\'		{
						strncpy(yylval.p_char, yytext, NAME_LEN);						
						return cSTRING;
					}				
"("					{ return oLP; }
")"					{ return oRP; }
"["					{ return oLB; }
"]"					{ return oRB; }
"+"					{ return oPLUS; }
"-"					{ return oMINUS; }
"*"					{ return oMUL; }
"/"					{ return oDIV; }
":="				{ return oASSIGN; }
"="					{ return oEQUAL; }
"<"					{ return oLT; }
">"					{ return oGT; }
"<="				{ return oLE; }
">="				{ return oGE; }
"<>"				{ return oUNEQU; }
","					{ return oCOMMA; }
";"					{ return oSEMI; }
":"					{ return oCOLON; }
"'"					{ return oQUOTE; }
".."				{ return oDOTDOT; }
"."					{ return oDOT; }
"^"					{ return oARROW; }
{letter}{alnum}*	{
						strncpy(yylval.p_char, yytext, NAME_LEN);
						return is_keyword(yytext);
					}
"\n"				{
						line_no++;
						line_pos = 0;
						line_buf[line_pos] = 0;
					}
.					{
					}
%%

int yywrap() 
{
	return 1;
}
//系统关键字表
KEYENTRY Keytable[] = {
{"abs",		SYS_FUNCT,	fABS, TYPE_INTEGER, TYPE_INTEGER },
{"and",		kAND,		KEYWORD, 0, 0 },
{"array",	kARRAY, 	KEYWORD, 0, 0 },
{"begin",	kBEGIN, 	KEYWORD, 0, 0 },
{"boolean", SYS_TYPE,	tBOOLEAN, 0, 0 },
{"case",	kCASE, 		KEYWORD, 0, 0 },
{"char",	SYS_TYPE,	tCHAR,	0, 0 },
{"chr",		SYS_FUNCT, 	fCHR, TYPE_CHAR, TYPE_CHAR },
{"const",	kCONST,		KEYWORD, 0, 0 },
{"div", 	kDIV,		KEYWORD, 0, 0 },
{"do",		kDO, 		KEYWORD, 0, 0 },
{"downto",	kDOWNTO,	KEYWORD, 0, 0 },
{"else",	kELSE,		KEYWORD, 0, 0 },
{"end", 	kEND, 		KEYWORD, 0, 0 },
{"false",	SYS_CON,	cFALSE, 0, 0 },
{"for",		kFOR,		KEYWORD, 0, 0 },
{"function", kFUNCTION, KEYWORD, 0, 0 },
{"goto",	kGOTO,	KEYWORD, 0, 0 },
{"if",		kIF, 		KEYWORD, 0, 0 },
{"in", 		kIN,		KEYWORD, 0, 0 },
{"integer", SYS_TYPE,	tINTEGER,	0, 0 },
{"label",	kLABEL,		KEYWORD, 0, 0 },
{"maxint", 	SYS_CON,	cMAXINT, 0, 0 },
{"mod",		kMOD,		KEYWORD, 0, 0 },
{"not", 	kNOT,		KEYWORD, 0, 0 },
{"odd",		SYS_FUNCT,	fODD, TYPE_INTEGER, TYPE_BOOLEAN },
{"of",		kOF,		KEYWORD, 0, 0 },
{"or",		kOR,		KEYWORD, 0, 0 },
{"ord",		SYS_FUNCT,	fORD, TYPE_INTEGER, TYPE_INTEGER },
{"packed",	kPACKED,	KEYWORD, 0, 0 },
{"pred",	SYS_FUNCT,	fPRED, TYPE_INTEGER, TYPE_INTEGER },
{"procedure", 	kPROCEDURE,	KEYWORD, 0, 0 },
{"program", 	kPROGRAM, KEYWORD, 0, 0 },
{"read",	pREAD,	pREAD, 0, 0 },
{"readln", 	pREAD,	pREADLN, 0, 0 },
{"real",	SYS_TYPE,	KEYWORD, 0, 0 },
{"record", 	kRECORD,	KEYWORD, 0, 0 },
{"repeat",	kREPEAT,	KEYWORD, 0, 0 },
{"set", 	kSET, 		KEYWORD, 0, 0 },
{"sqr",		SYS_FUNCT,	fSQR,	TYPE_INTEGER, TYPE_INTEGER },
{"sqrt",	SYS_FUNCT,	fSQRT,	TYPE_INTEGER, TYPE_INTEGER },
{"succ",	SYS_FUNCT,	fSUCC,	TYPE_INTEGER, TYPE_INTEGER },
{"then",	kTHEN,		KEYWORD, 0, 0 },
{"to",		kTO,		KEYWORD, 0, 0 },
{"true",	SYS_CON,	cTRUE,	0, 0 },
{"type",	kTYPE,		KEYWORD, 0, 0 },
{"until",	kUNTIL,		KEYWORD, 0, 0 },
{"var",		kVAR,		KEYWORD, 0, 0 },
{"while",	kWHILE,		KEYWORD, 0, 0 },
{"with",	kWITH, 		KEYWORD, 0, 0 },
{"write",	SYS_PROC,	pWRITE, 0, 0 },
{"writeln",	SYS_PROC,	pWRITELN, 0, 0 },
{"----",	LAST_ENTRY,	KEYWORD, 0, 0 },

{"string", SYS_TYPE, KEYWORD, 0, 0},

};

struct {
	char *name;
	int key;
}key_to_name[] = {
	{"SYS_FUNCT",	SYS_FUNCT },
	{"kAND",		kAND },
	{"kARRAY",		kARRAY },
	{"kBEGIN",		kBEGIN },
	{"SYS_TYPE", 	SYS_TYPE },
	{"kCASE",		kCASE },
	{"SYS_TYPE",	SYS_TYPE },
	{"kCONST",		kCONST },
	{"kDIV", 		kDIV },
	{"kDO",			kDO },
	{"kDOWNTO",		kDOWNTO },
	{"kELSE",		kELSE },
	{"kEND", 		kEND },
	{"SYS_CON",		SYS_CON },
	{"kFOR",		kFOR },
	{"kFUNCTION", 	kFUNCTION },
	{"kGOTO",		kGOTO },
	{"kIF",			kIF },
	{"kIN", 		kIN },
	{"kLABEL",		kLABEL },
	{"kMOD",		kMOD },
	{"kNOT", 		kNOT },
	{"kOF",			kOF },
	{"kOR",			kOR },
	{"kPACKED",		kPACKED },
	{"kPROCEDURE", 	kPROCEDURE },
	{"kPROGRAM", 	kPROGRAM },
	{"pREAD",		pREAD },
	{"kRECORD", 	kRECORD },
	{"kREPEAT",		kREPEAT },
	{"kSET", 		kSET },
	{"kTHEN",		kTHEN },
	{"kTO",			kTO },
	{"kTYPE",		kTYPE },
	{"kUNTIL",		kUNTIL },
	{"kVAR",		kVAR },
	{"kWHILE",		kWHILE },
	{"kWITH",		kWITH },
	{"SYS_PROC",	SYS_PROC },
	{"LAST_ENTRY",	LAST_ENTRY }
};

int get_keytable_size()
{
	int i;

	Keytable_size = 0;

	for (i = 0; ; Keytable_size++, i++)
	{
		if (Keytable[i].key == LAST_ENTRY)
			break;
	}

	return 0;
}

int is_keyword(char *text)
{
	int i;
	char *p;
	for (p = text; *p; p++)
		*p = tolower(*p);

	for(i=0;i<Keytable_size;i++)
	{
		if (!strcmp(Keytable[i].name, text))
		{
			if (Keytable[i].key == SYS_FUNCT
				|| Keytable[i].key == SYS_PROC)
			{
				yylval.p_lex = &Keytable[i];
			}
			else if (Keytable[i].key == SYS_CON)
			{
				yylval.num = Keytable[i].attr;
				
			}
			else if (Keytable[i].key == SYS_TYPE)
			{
				strncpy(yylval.p_char, yytext, NAME_LEN);
				
			}
			return Keytable[i].key;
		}
	}
	return yNAME;
}
