%{
#include <stdio.h>
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

int i;

%}
comment ("/*"(.|\n)*"*/")|("//".*)
%%
{comment} {
			for(i = 0; i < yyleng; i++){
				if(yytext[i] <= 'z' && yytext[i] >= 'a'){
					yytext[i] += 'A' - 'a';
					}
				}
			printf("%s", yytext);	
			}

%%
main(){
	yylex();
	return 0;

}
