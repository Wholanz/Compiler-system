%{

#include <stdio.h>
#include <string.h>
int yylex();
%}

%union{
	char * type;
}

%start program

%token<type>  ID INT BOOL ARRAY NUM OF IF THEN TRUE FALSE ASSIGN 
%type <type>  var_decl type_exp exp

%%
program	: var_decls ';' stmts
		;
		
var_decls :	var_decls ';' var_decl 
			| var_decl;

var_decl : ID ':' type_exp {$1 = $3;};

type_exp : INT {$$ = "integer";}
		| BOOL {$$ = "boolean";} 
		| ARRAY '[' NUM ']' OF type_exp {$$ = $6;};

stmts : stmts ';' stmt | stmt;

stmt : IF exp THEN stmt {if (strcmp($2, "boolean") != 0) yyerror("condition value has to be boolean type\n");}
		| ID ASSIGN exp {if (strcmp($1, $3) != 0) yyerror("type of lvalue and rvalue must be the same!");};
 
exp : NUM {$$ = $1;}| TRUE {$$ = "booleab";}| FALSE {$$ = "booleab";}| ID {$$ = $1;} 
	 | exp '+' exp {if (strcmp($1, "integer") != 0 || strcmp($3,"integer") != 0) yyerror("operand type mismatch(must be integer)");}
	| exp '|' exp {if (strcmp($1, "integer") != 0 || strcmp($3,"integer") != 0) yyerror("operand type mismatch(must be integer)");}
	| exp '[' exp ']'{if (strcmp($3,"integer") != 0) yyerror("operand type mismatch(must be integer)");}
;


%%

int main(){
	yylex(); 
	return yyparse();
} 
int yyerror(char *s){

	printf("%s\n",s);
	return 0;

}
