%{
#include <stdio.h>
int charNum = 0;
int wordNum = 0;
int lineNum = 0;

%}

word [a-zA-Z0-9]+
line \n
%%
{word} {wordNum++; charNum += yyleng;}
{line} {lineNum++;}
%%
int main(){
	yylex();
	printf("Character number: %d\n", charNum);
    printf("Word number: %d\n", wordNum);
    printf("Line number: %d\n", lineNum);
	return 0;
}


