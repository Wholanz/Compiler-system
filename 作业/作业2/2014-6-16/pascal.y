%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "res.h"
extern int linenum;
extern int save_cnt;
extern int isTypeDefineID;
extern int isVarDefineID;
//extern int isNameList;
extern int procedure_cnt;
extern FILE *yyin;
extern struct ConstTable ctable[100];//常量表
//extern struct VarTable vtable[100];//变量表:已弃用
extern struct TypeTable ttable[100];//类型定义表
extern struct LabelTable ltable[100];//label定义表

extern int const_cnt;//记录const的数量，配合常量表使用
int var_cnt=0;//记录var的数量，配合变量表使用
int type_cnt=0;//记录type的数量，配合类型定义表使用
int label_cnt=0;//记录label的数量，配合label表使用
extern int etable_cnt;//记录EnumTable的数量，配合EnumTable表使用
extern int name_list_cnt;//记录在一个name_list项中，有多少并列的name

struct TreeNode *args_list_pt=NULL;
struct TreeNode *exp_list_pt=NULL;
struct TreeNode *stmt_list_pt=NULL;
struct TreeNode *case_expr_list_pt=NULL;
struct TreeNode *para_list_pt=NULL;
extern struct HashTables* cur_procedure_vt;
extern struct TreeNode* tree_root;


#ifndef False
#define False 0
#endif
#ifndef True
#define True 1
#endif
void yyerror(char *);
void CopyToConstTable(struct Node* n1, struct Node* n2);
void CopyToLabelTable(int label, struct TreeNode* tn);
void CopyToVarTable(int var_copy_to_caller, idType t);
void CopyToEnumTable(char *tablename);
struct Node* FindConstValue(char *con);
idType FindIdType(char *id);
int FindIdValue(char *id);//may not be used
idType FindInTypeTable(char * name);
struct TreeNode* FindLabel(int label);
extern int CalculateHashNumber(char* varname);
void simpleOperandCopy(struct Node* oper, struct Node* res);
void simpleOperation(struct Node* oper1, struct Node* oper2, char operation, struct Node* res);
void getReturnValue(struct Node* return_value, char *name);/*这个函数不能使用，返回值没有计算出来*/
%}
%union 
{ 
	struct Node* nnode;
	struct ExpNode* enode;
	struct TreeNode* tnode;
}
%token ID DOT DOTDOT LP RP LB RB COMMA COLON SEMI MUL DIV MOD PLUS MINUS MYAND MYOR MYNOT GE GT LE LT EQUAL UNEQUAL ASSIGN OF PROGRAM 
%token CONST TYPE SYS_TYPE INTEGER REAL CHAR STRING BOOLEAN VAR FUNCTION PROCEDURE ARRAY RECORD SYS_FUNCT SYS_PROC READ
%token MYBEGIN MYEND MYIF MYELSE MYTHEN MYWHILE MYREPEAT MYUNTIL MYGOTO MYTO MYDOWNTO MYCASE MYOF MYFOR MYDO MYWRITELN

%left MUL DIV PLUS MINUS 
%type <nnode> const_value
%type <tnode> expression expr term factor args_list expression_list compound_stmt stmt_list stmt non_label_stmt 
%type <tnode> assign_stmt proc_stmt if_stmt repeat_stmt for_stmt while_stmt case_stmt goto_stmt 
%type <tnode> else_clause case_expr_list case_expr  ID name_list var_para_list val_para_list  SYS_FUNCT  READ
%type <tnode> function_decl procedure_decl parameters para_decl_list para_type_list procedure_head function_head routine_body
%type <enode> type_definition type_decl simple_type_decl array_type_decl record_type_decl

%%
program:	program_head routine DOT {
				printf("PROGRAM line=%d\n\n", linenum); 
				//enumTableTraversal();
				//treeTraversal(tree_root);
				writeTree(tree_root);
				//DefineRelationTraversal();
				//hashTableTraversal();
			}
			| program_head routine DOT error{ yyerror("haha");

			}
		;
program_head:	PROGRAM ID SEMI 
			{	printf("PROGRAM_HEAD: program %s;\n", (save_cnt==0)?save:save1); 

				initHashTables(); 
				//printf("cur_procedure_vt->proce_name=%s\n", cur_procedure_vt->proce_name);
			}
			|   PROGRAM ID error SEMI {yyerror("program head define error1");}
			|   PROGRAM error ID SEMI {yyerror("program head define error2");}
			|   error PROGRAM error ID SEMI {yyerror("program head define error3");}
		;
routine:	routine_head routine_body {;}
		;
routine_body:	compound_stmt  {$$=$1;/*treeTraversal($$);*/}
			;
routine_head:	const_part  type_part  var_part  routine_part 
			|	type_part  var_part  routine_part  
			|	const_part  var_part  routine_part  
			|	const_part  type_part  routine_part  
			|	const_part  routine_part  
			|	type_part  routine_part
			|	var_part  routine_part
			|	const_part  type_part  var_part 
			|	type_part  var_part 
			|	const_part  var_part 
			|	const_part  type_part
			|	const_part
			|	type_part
			|	var_part
			;
const_part:	CONST  const_expr_list  {printf("CONST_PART: const exp_list\n"); constTableTraversal();}
		;
const_expr_list:	const_expr_list  ID  EQUAL  const_value  SEMI
					{	char *tmpc=(char *)malloc(sizeof(char)*strlen((save_cnt==0)?save:save1));
						strcpy(tmpc,(save_cnt==0)?save:save1);
						switch($4->type){
							case integer: printf("CONST_EXPR_LIST: %s = %d;\n", tmpc, $4->intValue); break;
							case real: printf("CONST_EXPR_LIST: %s = %f;\n", tmpc, $4->realValue); break;
							case character: printf("CONST_EXPR_LIST: %s = %c;\n", tmpc, $4->charValue); break;
							case string: printf("CONST_EXPR_LIST: %s = %s;\n", tmpc, $4->strValue); break;
						}
						int i;
						for(i=0;i<const_cnt;i++){
							if(!strcmp(ctable[i].name, tmpc)){
								yyerror("const redeclared");
								break;
							}
						}
						if(i>=const_cnt){
							//ctable[const_cnt].name=(char *)malloc(sizeof(char)*strlen(tmpc));
							strcpy(ctable[const_cnt].name, tmpc);
							ctable[const_cnt].value=(struct Node *)malloc(sizeof(struct Node));		
							CopyToConstTable(ctable[const_cnt].value, $4);
							const_cnt++;
						}
					}
			|  ID  EQUAL  const_value  SEMI  
					{	char *tmpc=(char *)malloc(sizeof(char)*strlen((save_cnt==0)?save:save1));
						strcpy(tmpc,(save_cnt==0)?save:save1);
						switch($3->type){
							case integer: printf("CONST_EXPR_LIST: %s = %d;\n", tmpc, $3->intValue); break;
							case real: printf("CONST_EXPR_LIST: %s = %f;\n", tmpc, $3->realValue); break;
							case character: printf("CONST_EXPR_LIST: %s = %c;\n", tmpc, $3->charValue); break;
							case string: printf("CONST_EXPR_LIST: %s = %s;\n", tmpc, $3->strValue); break;
						}
						int i;
						for(i=0;i<const_cnt;i++){
							if(!strcmp(ctable[i].name, tmpc)){
								yyerror("const redeclared");
								break;
							}
						}
						if(i>=const_cnt){
							//ctable[const_cnt].name=(char *)malloc(sizeof(char)*strlen(tmpc));
							strcpy(ctable[const_cnt].name, tmpc);
							ctable[const_cnt].value=(struct Node *)malloc(sizeof(struct Node));		
							CopyToConstTable(ctable[const_cnt].value, $3);
							//printf("\n%s\n",ctable[const_cnt].value->strValue);
							const_cnt++;
						}
					}
			;
const_value:	INTEGER	{$$=(struct Node *)malloc(sizeof(struct Node)); 
						$$->type=integer; 
						$$->intValue=atoi(cvalue); 
						$$->realValue=(float)$$->intValue;//
						$$->boolValue=($$->intValue==0)? 0: 1;
						printf("CONST_VALUE: %d\n", $$->intValue); }
			|  REAL  	{$$=(struct Node *)malloc(sizeof(struct Node)); 
						$$->type=real; 
						$$->realValue=atof(cvalue); 
						$$->intValue=(int)$$->realValue; 
						printf("CONST_VALUE: %f\n", $$->realValue);}
			|  CHAR  	{$$=(struct Node *)malloc(sizeof(struct Node)); 
						$$->charValue=cvalue[1]; $$->type=character; 
						printf("CONST_VALUE: %c\n", $$->charValue);}
			|  STRING  	{$$=(struct Node *)malloc(sizeof(struct Node)); 
						$$->strValue=(char *)malloc(sizeof(char)*strlen(cvalue)); 
						strcpy($$->strValue, cvalue+1); 
						$$->strValue[strlen($$->strValue)-1]=0; 
						$$->type=string; 
						printf("CONST_VALUE: %s\n", $$->strValue);}
			|  BOOLEAN  {$$=(struct Node *)malloc(sizeof(struct Node)); 
						$$->type=boolean;
						if(!strcmp(cvalue, "true")){$$->boolValue=1; $$->intValue=1;}
						else if(!strcmp(cvalue, "false")){$$->boolValue=0; $$->intValue=0;}
						printf("CONST_VALUE: %c\n", $$->charValue);}
			;
type_part:	TYPE type_decl_list		{printf("TYPE_PART\n"); enumTableTraversal();}
		;
type_decl_list:	type_decl_list  type_definition  {printf("TYPE_DECL_LIST\n");}
			|  type_definition	{printf("TYPE_DECL_LIST\n");}
			;
type_definition: ID  EQUAL  type_decl  SEMI	{	//$$=(struct ExpNode *)malloc(sizeof(struct ExpNode)); 
												printf("TYPE_DEFINATION: procedure_cnt=%d, %s = typedecl;\n", procedure_cnt, type_define_save);
												//$$->type=$3->type;
												strcpy(ttable[type_cnt].name, type_define_save);
												ttable[type_cnt].type=$3->type;
												type_cnt++;
												if($3->type==enumeration){
													printf("will CopyToEnumTable\n");
													CopyToEnumTable(type_define_save);//from name_list to enum_table
												}
											}
				;
type_decl:	simple_type_decl	{$$=(struct ExpNode *)malloc(sizeof(struct ExpNode)); 
								//printf("TYPE_DECL: simple_type_decl, type=%d\n", $1->type); 
								$$->type=$1->type; }
			|  array_type_decl  {$$=(struct ExpNode *)malloc(sizeof(struct ExpNode)); $$->type=$1->type;}
			|  record_type_decl	{$$=(struct ExpNode *)malloc(sizeof(struct ExpNode)); $$->type=$1->type;}
			;
simple_type_decl:	SYS_TYPE  {//printf("sys_type: %s\n", sys_type); 
								$$=(struct ExpNode *)malloc(sizeof(struct ExpNode));
								if(!strcmp(sys_type,"integer")){ $$->type=integer;}
								else if(!strcmp(sys_type,"real")){$$->type=real;}
								else if(!strcmp(sys_type,"char")){ $$->type=character;}
								else if(!strcmp(sys_type,"string")){$$->type=string;}
								else if(!strcmp(sys_type,"boolean")){$$->type=boolean;}
							}
				|  ID	{	$$=(struct ExpNode *)malloc(sizeof(struct ExpNode));
							idType tt=FindInTypeTable((save_cnt==0)?save:save1);
							if(tt>=0) $$->type=tt;
						}
				|  LP  name_list  RP  {
							//printf("simple_type_decl: ( namelist )\n");
							$$=(struct ExpNode *)malloc(sizeof(struct ExpNode));
                			$$->type=enumeration;
                			//wait until type_definition, where current name_list will be added to enum_table
                			//printf("name_list_cnt=%d\n\n", name_list_cnt);
						}
                |  const_value  DOTDOT  const_value  {
                			printf("%d .. %d\n", $1->intValue, $3->intValue);
                			$$=(struct ExpNode *)malloc(sizeof(struct ExpNode));
                			$$->type=subrange;
                			if($1->type==integer && $3->type==integer){
	                			$$->upper=$3->intValue;
	                			$$->lower=$1->intValue;
	                		}else {
	                			yyerror("subrange define error");
	                		}
                		}
                |  MINUS  const_value  DOTDOT  const_value {
                			printf("-%d .. %d\n", $2->intValue, $4->intValue);
                			$$=(struct ExpNode *)malloc(sizeof(struct ExpNode));
                			$$->type=subrange;
                			if($2->type==integer && $4->type==integer){
	                			$$->upper=$4->intValue;
	                			$$->lower=-$2->intValue;
	                		}else {
	                			yyerror("subrange define error");
	                		}
                		}
                |  MINUS  const_value  DOTDOT  MINUS  const_value {
                			printf("-%d .. -%d\n", $2->intValue, $5->intValue);
                			$$=(struct ExpNode *)malloc(sizeof(struct ExpNode));
                			$$->type=subrange;
                			if($2->type==integer && $5->type==integer){
	                			$$->upper=-$5->intValue;
	                			$$->lower=-$2->intValue;
	                		}else {
	                			yyerror("subrange define error");
	                		}
                		}
                |  ID  DOTDOT  ID{
                			printf("%s .. %s\n", (save_cnt==1)?save:save1, (save_cnt==0)?save:save1);
                			char id1[30], id2[30];
                			strcpy(id1, (save_cnt==1)?save:save1);
                			strcpy(id2, (save_cnt==0)?save:save1);
                			$$=(struct ExpNode *)malloc(sizeof(struct ExpNode));
                			$$->type=subrange;
                			struct Node* n1=FindConstValue(id1);
	                		struct Node* n2=FindConstValue(id2);
	                		if(n1->type==integer && n2->type==integer){
	                			$$->upper=n2->intValue;
	                			$$->lower=n1->intValue;
	                		}else{
	                			yyerror("subrange define error");
	                		}
                			
                		}
				;
name_list:	ID  COMMA  name_list{	/*record each ID into nlist[], done in getID(yytext)*/
					//$1=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					//$1->node_type=anid;
					//strcpy($1->id_name, ???);

					//$1->next_sibling=$3;
					///$$=$1;
				}
		|  ID	{	/*record each ID into nlist[], done in getID(yytext)*/ 
					//$1=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					//$1->node_type=anid;
					//$1->left_child=NULL; $1->right_child=NULL;
					//$1->next_sibling=NULL;
					//$$=$1;
				}
		;

array_type_decl:	ARRAY  LB  simple_type_decl  RB  OF  type_decl 
				{$$=(struct ExpNode *)malloc(sizeof(struct ExpNode)); 
				printf("ARRAY_TYPE_DECL: array [simple_type_decl] of type_decl\n");
				$$->type=array;}
				;
record_type_decl:	RECORD  field_decl_list  MYEND  {
						$$=(struct ExpNode *)malloc(sizeof(struct ExpNode)); 
						printf("RECORD_TYPE_DECL: record field_decl_list end\n"); 
						$$->type=record;
					}
				;
field_decl_list:	field_decl_list  field_decl  {printf("field_decl_list: field_decl\n");}
				|  field_decl  {printf("field_decl_list: field_decl\n");}
				;
field_decl:	name_list  COLON  type_decl  SEMI  {
					//printf("field_decl: name_list : type_decl;\n");
					/*In this scope, isNameList remains 0, no ID added to nlist[]*/
					/*In case of conditions unnoticed, clear nlist[]*/
					name_list_cnt=0;
				}
			;

var_part:	VAR  var_decl_list  { /*hashTableTraversal();*/ }
			;
var_decl_list:	var_decl_list  var_decl  
			|  var_decl  
			;
var_decl:	name_list  COLON  type_decl  SEMI {
					CopyToVarTable(0, $3->type);
				}
		;


routine_part: routine_part  function_decl  
		|  routine_part  procedure_decl
        |  function_decl  {printf("routine_part: function_decl\n");}
        |  procedure_decl
        ;
function_decl: function_head  SEMI  compound_stmt  SEMI 
				{
					printf("one function\n"); 
					$$=(struct TreeNode *)malloc(sizeof(struct TreeNode));
					$$->node_type=function;
					strcpy($$->funct_proce_name, $1->funct_proce_name);
					$$->funct_proce_return=(struct Node*)malloc(sizeof(struct Node));
					$$->funct_proce_return->type=$1->funct_proce_return->type;
					//getReturnValue($$->funct_proce_return, $$->funct_proce_name);
					/*这个函数不能使用，返回值没有计算出来*/

					$$->left_child=$1;
					$$->right_child=$3;
					$$->next_sibling=NULL;

					//deleteHashTable();
					//hashTableTraversal();
					completeDefineRelation($$);
				}
			;

function_head: FUNCTION  ID  parameters  COLON  simple_type_decl
						{	printf("procedure_head: FUNCTION %s (params): type\n", fvalue);
							//addHashTable(fvalue);//hashtable must be constructed before parameters are constructed
							addReturnValue(fvalue, $5->type);
							addDefineRelation(fvalue);
							$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
							$$->node_type=functhead;
							strcpy($$->funct_proce_name, fvalue);
							$$->funct_proce_return=(struct Node*)malloc(sizeof(struct Node));
							$$->funct_proce_return->type=$5->type;//simple_type_decl
							free($5);//free simple_type_decl
							$$->left_child=$3;//[optional] parameters
							$$->right_child=NULL; $$->next_sibling=NULL;
						}
			|  FUNCTION  ID  COLON  simple_type_decl
						{	printf("procedure_head: FUNCTION %s: type\n", fvalue);
							//addHashTable(fvalue);
							addReturnValue(fvalue, $4->type);
							addDefineRelation(fvalue);
							$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
							$$->node_type=functhead;
							strcpy($$->funct_proce_name, fvalue);
							$$->funct_proce_return=(struct Node*)malloc(sizeof(struct Node));
							$$->funct_proce_return->type=$4->type;//simple_type_decl
							free($4);//free simple_type_decl
							$$->left_child=NULL; $$->right_child=NULL; $$->next_sibling=NULL;
						}
			;
compound_stmt:	MYBEGIN  stmt_list  MYEND  {//这里的如何实现function返回值的文法？
									$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=root;
									$$->next_sibling=NULL;
									$$->left_child=$2; $$->right_child=NULL;
									tree_root=$$;
									//treeTraversal(tree_root);
									//printf("\n\nContent in compound_stmt tree:\n");
									//treeTraversal(tree_root);
								}
			|	MYBEGIN  MYEND	{
									$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=root;
									$$->next_sibling=NULL;
									$$->left_child=NULL; $$->right_child=NULL;
									tree_root=$$;
									//treeTraversal(tree_root);
								}
			;
stmt_list:	stmt  stmt_list  {
					$1->next_sibling=$2;
					//printf("$1 type=%d\n", $1->node_type);
					$$=$1;
					stmt_list_pt=$$;
				}
		|	stmt  {
				$1->next_sibling=NULL;	
				//printf("$1 type=%d\n", $1->node_type);
				$$=$1;
				stmt_list_pt=$$;
				/*if(procedure_cnt==function_body){
					printf("This is the last stmt of function\n");
					if($1->statement==assign){
						printf("this is the last statement and it is assign\n");

					}else{
						yyerror("function has no returning value");
					}
					
				}*/
			}
		;
stmt:	INTEGER  COLON  non_label_stmt  {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=stmt;
				$$->statement=$3->statement;
				$$->left_child=$3; $$->right_child=NULL;
				$$->next_sibling=NULL;
				CopyToLabelTable(atoi(cvalue), $3);
			}
		|  non_label_stmt {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=stmt;
				$$->statement=$1->statement;
				//printf("stmt: $1->statement=%d", $1->statement);
				$$->left_child=$1; $$->right_child=NULL;
				$$->next_sibling=NULL;
			}
		;
non_label_stmt:	assign_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=assign;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| proc_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=proc;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| compound_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=compound;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| if_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=iff;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| repeat_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=repeat;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| while_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=whilee;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| for_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=forr;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| case_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=casee;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				| goto_stmt {
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=gotoo;
						$$->left_child=$1; $$->right_child=NULL;
						$$->next_sibling=NULL;
					}
				;
assign_stmt: ID  ASSIGN  expression SEMI {
					//printf("%s := expression\n",assignID);
					//construct an ID node
					$1=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$1->node_type=anid;
					strcpy($1->id_name, assignID);
					$1->node_value=(struct Node*)malloc(sizeof(struct Node));
					$1->left_child=NULL;
					$1->right_child=NULL;
					$1->next_sibling=NULL;
					idType t=FindIdType(assignID);
					if(t>=0){
						$1->node_value->type=t;
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=stmt;
						$$->statement=assign;
						$$->left_child=$1; $$->right_child=$3;
						$$->next_sibling=NULL;
					}else{//t==-1
						yyerror("Undefined variable");
					}
				}
		   | error ID  ASSIGN  expression SEMI
           | ID LB expression RB ASSIGN expression SEMI{printf("%s[exp] := expression\n",(save_cnt==0)?save:save1);}
           | ID  DOT  ID  ASSIGN  expression SEMI{printf("%s.%s := expression\n", (save_cnt==1)?save:save1, (save_cnt==0)?save:save1);}
           ;
proc_stmt: ID SEMI
		|  ID  LP  args_list  RP  SEMI  {
					printf("                                                         proc_stmt: ID=%s\n", callerID);
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=proc;
					strcpy($$->funct_proce_name, callerID);//$$->funct_proce_name: 函数名
					$$->left_child=FindFuncProcTree(callerID);
					$$->right_child=$3;
					$$->next_sibling=NULL;
					if($$->left_child==NULL) yyerror("Function undefined");
					else {
						//CopyAddHashTable(callerID);
						//hashTableTraversal();
					}
					//treeTraversal($$);
				}
		|  SYS_FUNCT  SEMI{/*write/writeln*/}
		|  SYS_FUNCT  LP  expression_list  RP  SEMI{/*write/writeln*/
					$1=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$1->node_type=sysfunc;
					$1->left_child=$1->right_child=$1->next_sibling=NULL;

					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=proc;
					$$->left_child=$1; $$->right_child=$3;
					$$->next_sibling=NULL;

				}
		|  READ  LP  factor  RP  SEMI {/*printf("read statement\n");*/
					$1=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$1->node_type=read;
					$1->left_child=$1->right_child=$1->next_sibling=NULL;

					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=proc;
					$$->left_child=$1; $$->right_child=$3;
					$$->next_sibling=NULL;
				}
		;
if_stmt:  MYIF  expression  MYTHEN  stmt  else_clause  {	
					printf("if-else statement\n");
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=iff;
					$$->left_child=$2; $$->right_child=NULL;
					$$->next_sibling=NULL;
					$2->right_child=$4;
					$4->right_child=$5;
				}
		| MYIF  expression  MYTHEN  stmt {
					printf("if statement\n");
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=iff;
					$$->left_child=$2; $$->right_child=NULL;
					$$->next_sibling=NULL;
					$2->right_child=$4;
				}
		;
else_clause:	MYELSE stmt{ $$=$2; }
		;
repeat_stmt:	MYREPEAT  stmt_list  MYUNTIL  expression SEMI{
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=repeat;
					$$->left_child=$2; $$->right_child=$4;
					$$->next_sibling=NULL;
				}
			;
while_stmt:		MYWHILE  expression  MYDO  stmt  {
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=whilee;
					$$->left_child=$2; $$->right_child=$4;
					$$->next_sibling=NULL;
				}
			;
for_stmt:	MYFOR  ID  ASSIGN  expression  MYTO  expression  MYDO  stmt  {
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=forr;
					$$->direction=1;//direction
					$2=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$2->node_type=value;
					printf("procedure_cnt=%d  forID=%s\n", procedure_cnt, forID);
					idType tt=FindIdType(forID);
					printf("idType tt=%d\n",tt);
					if(tt>=0){
						$2->node_value=(struct Node*)malloc(sizeof(struct Node));
						$2->node_value->type=tt;
						$2->next_sibling=$4; //expression1
						$2->left_child=NULL; $2->right_child=NULL;
					}else{//tt==-1
						yyerror("Undefined variable");
					}
					$$->left_child=$2; //ID
					$$->right_child=$8;//stmt
					$$->next_sibling=NULL;
					$4->next_sibling=$6; //expression2

					//ID  expression  expression are recorded in left child using sibling methods
				}
			|	MYFOR  ID  ASSIGN  expression  MYDOWNTO  expression  MYDO  stmt  {
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=forr;
					$$->direction=0; //direction
					$2=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$2->node_type=value;
					printf("procedure_cnt=%d  forID=%s\n", procedure_cnt, forID);
					idType tt=FindIdType(forID);
					printf("idType tt=%d\n",tt);
					if(tt>=0){
						$2->node_value=(struct Node*)malloc(sizeof(struct Node));
						$2->node_value->type=tt;
						$2->next_sibling=$4; //expression1
						$2->left_child=NULL; $2->right_child=NULL;
					}else{//tt==-1
						yyerror("Undefined variable");
					}
					$$->left_child=$2; //ID
					$$->right_child=$8;//stmt
					$$->next_sibling=NULL;
					$4->next_sibling=$6; //expression2
					//ID  expression  expression are recorded in left child using sibling methods
				}
			;
case_stmt:	MYCASE expression MYOF case_expr_list  MYEND  {
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=casee;
					$$->left_child=$2; //expression
					$$->right_child=$4; //case_expr_list
					$$->next_sibling=NULL;
				}
		;
case_expr_list:	case_expr  case_expr_list  {
				$1->next_sibling=$2;
				$$=$1;
				//case_expr_list_pt=$$;
			}
		|	case_expr{
				$$=$1;
				//case_expr_list_pt=$$;
			}
		;
case_expr:	const_value  COLON  stmt  {
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=caseexp;
					$$->case_const=$1;
					$$->left_child=NULL;
					$$->right_child=$3;
					$$->next_sibling=NULL;
				}
			|	ID  COLON  stmt  {
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=caseexp;
					$1=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$1->node_type=anid;
					printf("case_expr: ID=%s\n", (save_cnt==0)?save:save1);
					strcpy($1->id_name, (save_cnt==0)?save:save1);
					$1->node_value=(struct Node*)malloc(sizeof(struct Node*));
					$1->node_value->type=FindIdType((save_cnt==0)?save:save1);
					$$->left_child=$1;
					$$->right_child=$3;
					$$->next_sibling=NULL;
        		}
          ;
goto_stmt:	MYGOTO  INTEGER  {
					struct TreeNode* pt=FindLabel(atoi(cvalue));
					$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=stmt;
					$$->statement=gotoo;
					$$->left_child=pt; $$->right_child=NULL; $$->next_sibling=NULL;
				}
		;

procedure_decl:	procedure_head  SEMI  compound_stmt  SEMI  {
					printf("one procedure\n");
					$$=(struct TreeNode *)malloc(sizeof(struct TreeNode));
					$$->node_type=procedure;
					strcpy($$->funct_proce_name, $1->funct_proce_name);
					$$->left_child=$1;//procedure_head
					$$->right_child=$3;//compound_stmt
					$$->next_sibling=NULL;

					hashTableTraversal();
					cur_procedure_vt=cur_procedure_vt->caller_pointer;
					//hashTableTraversal();
					completeDefineRelation($$);
				}
			|	procedure_head  SEMI  procedure_decl  compound_stmt  SEMI  {
					printf("one insert procedure\n");
					$$=(struct TreeNode *)malloc(sizeof(struct TreeNode));
					$$->node_type=procedure;
					strcpy($$->funct_proce_name, $1->funct_proce_name);
					$$->left_child=$1;//procedure_head
					$$->right_child=$4;//compound_stmt
					$$->next_sibling=NULL;

					cur_procedure_vt=cur_procedure_vt->caller_pointer;
					//hashTableTraversal();
					completeDefineRelation($$);
				}

			;
procedure_head:	PROCEDURE ID parameters 
						{	printf("procedure_head: PROCEDURE %s (params)\n", pvalue);
							//addHashTable(pvalue);//name of procedure
							addDefineRelation(pvalue);
							$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
							$$->node_type=procehead;
							strcpy($$->funct_proce_name, pvalue);
							$$->funct_proce_return=NULL;
							$$->left_child=$3;//[optional] parameters
							$$->right_child=NULL; $$->next_sibling=NULL;
						}
			|	PROCEDURE ID
						{	printf("procedure_head: PROCEDURE %s\n", pvalue);
							//addHashTable(pvalue);
							addDefineRelation(pvalue);
							$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
							$$->node_type=procehead;
							strcpy($$->funct_proce_name, pvalue);
							$$->funct_proce_return=NULL;
							$$->left_child=NULL; $$->right_child=NULL; $$->next_sibling=NULL;
						}
			;

expression_list:	expression_list  COMMA  expression  {
						$1->next_sibling=$3;
						//printf("$1 type=%d\n", $1->node_type);
						$$=$1;
						exp_list_pt=$$;
					}
				|   expression 	{
						$1->next_sibling=NULL;	
						printf("$1 type=%d\n", $1->node_type);
						$$=$1;
						exp_list_pt=$$;
					}
				;
expression:	expression  GE  expr{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=comparation;
									$$->operation=ge;
									$$->node_value=(struct Node*)malloc(sizeof(struct Node));
									$$->node_value->type=boolean;
									$$->next_sibling=NULL;
									$$->left_child=$1; $$->right_child=$3;
								}
		|  expression  GT  expr {	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=comparation;
									$$->operation=gt;
									$$->node_value=(struct Node*)malloc(sizeof(struct Node));
									$$->node_value->type=boolean;
									$$->next_sibling=NULL;
									$$->left_child=$1; $$->right_child=$3;
								}
		|  expression  LE  expr {	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=comparation;
									$$->operation=le;
									$$->node_value=(struct Node*)malloc(sizeof(struct Node));
									$$->node_value->type=boolean;
									$$->next_sibling=NULL;
									$$->left_child=$1; $$->right_child=$3;
								}
		|  expression  LT  expr	{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=comparation;
									$$->operation=lt;
									$$->node_value=(struct Node*)malloc(sizeof(struct Node));
									$$->node_value->type=boolean;
									$$->next_sibling=NULL;
									$$->left_child=$1; $$->right_child=$3;
								}
		|  expression  EQUAL  expr{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=comparation;
									$$->operation=eq;
									$$->node_value=(struct Node*)malloc(sizeof(struct Node));
									$$->node_value->type=boolean;
									$$->next_sibling=NULL;
									$$->left_child=$1; $$->right_child=$3;
								}
		|  expression  UNEQUAL  expr  {	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									$$->node_type=comparation;
									$$->operation=ue;
									$$->node_value=(struct Node*)malloc(sizeof(struct Node));
									$$->node_value->type=boolean;
									$$->next_sibling=NULL;
									$$->left_child=$1; $$->right_child=$3;
								}
		|  expr {	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=anoperator;
					$$->operation=none;
					$$->node_value=(struct Node*)malloc(sizeof(struct Node));
					simpleOperandCopy($1->node_value, $$->node_value);
					$$->left_child=$1; $$->right_child=NULL;
					$$->next_sibling=NULL;
				}
		|  expression error expr{ yyerror("undefined operator");}
		;
expr:	   expr  PLUS  term	{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=anoperator;
								$$->operation=add;
								$$->node_value=(struct Node*)malloc(sizeof(struct Node));
								simpleOperation($1->node_value, $3->node_value, '+', $$->node_value);
								$$->next_sibling=NULL;
								$$->left_child=$1; $$->right_child=$3;
							}
		|  expr  MINUS  term {	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=anoperator;
								$$->operation=sub;
								$$->node_value=(struct Node*)malloc(sizeof(struct Node));
								simpleOperation($1->node_value, $3->node_value, '-', $$->node_value);
								$$->next_sibling=NULL;
								$$->left_child=$1; $$->right_child=$3;
							}
		|  expr  MYOR  term {	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=anoperator;
								$$->operation=orr;
								$$->node_value=(struct Node*)malloc(sizeof(struct Node));
								simpleOperation($1->node_value, $3->node_value, '|', $$->node_value);
								$$->next_sibling=NULL;
								$$->left_child=$1; $$->right_child=$3;
							}
		|  term	{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=anoperator;
					$$->operation=none;
					$$->node_value=(struct Node*)malloc(sizeof(struct Node));
					simpleOperandCopy($1->node_value, $$->node_value);
					$$->left_child=$1; $$->right_child=NULL;
					$$->next_sibling=NULL;
				}
		;
term:	   term  MUL  factor{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=anoperator;
								$$->operation=mul;
								$$->node_value=(struct Node*)malloc(sizeof(struct Node));
								simpleOperation($1->node_value, $3->node_value, '*', $$->node_value);
								$$->next_sibling=NULL;
								$$->left_child=$1; $$->right_child=$3;
							}
		|  term  DIV  factor{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=anoperator;
								$$->operation=divv;
								$$->node_value=(struct Node*)malloc(sizeof(struct Node));
								simpleOperation($1->node_value, $3->node_value, '/', $$->node_value);
								$$->next_sibling=NULL;
								$$->left_child=$1; $$->right_child=$3;
							}
		|  term  MOD  factor{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=anoperator;
								$$->operation=mod;
								$$->node_value=(struct Node*)malloc(sizeof(struct Node));
								simpleOperation($1->node_value, $3->node_value, '%', $$->node_value);
								$$->next_sibling=NULL;
								$$->left_child=$1; $$->right_child=$3;
							}
		|  term  MYAND  factor{ $$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=anoperator;
								$$->operation=andd;
								$$->node_value=(struct Node*)malloc(sizeof(struct Node));
								simpleOperation($1->node_value, $3->node_value, '&', $$->node_value);
								$$->next_sibling=NULL;
								$$->left_child=$1; $$->right_child=$3;
							}
		|  factor{	$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
					$$->node_type=anoperator;
					$$->operation=none;
					$$->node_value=(struct Node*)malloc(sizeof(struct Node));
					simpleOperandCopy($1->node_value, $$->node_value);
					$$->left_child=$1; $$->right_child=NULL;
					$$->next_sibling=NULL;
				}
		;
factor:	   ID  {$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=value;
				$$->node_value=(struct Node*)malloc(sizeof(struct Node));
				$$->node_value->type=FindIdType((save_cnt==0)?save:save1);
				//printf("factor type is %d\n", $$->node_value->type);

				$$->left_child=NULL; $$->right_child=NULL;
				$$->next_sibling=NULL;
				}
		|  ID  LP  args_list  RP  {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=value;
				$$->left_child=FindFuncProcTree(callerID);
				$$->right_child=$3; 
				$$->next_sibling=NULL;
				if($$->left_child==NULL){
					yyerror("Function undefined");
					free($$);
				}else{
					//CopyAddHashTable(callerID);
					$$->node_value=(struct Node*)malloc(sizeof(struct Node));
					//$$->node_value->type=idontknow; 
				}
				args_list_pt=NULL;
			}
		|  SYS_FUNCT  LP  args_list  RP  {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=value;
				$$->node_value=(struct Node*)malloc(sizeof(struct Node));
				//$$->node_value->type=idontknow;
				int x=0;
				/*struct TreeNode* tmp=args_list_pt;
				while(tmp!=NULL){
					printf("$3's cnt: %d\n", tmp->node_type);
					tmp=tmp->next_sibling;
				}*/
				args_list_pt=NULL;
			}
		|  const_value  {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=value;
				$$->node_value=(struct Node*)malloc(sizeof(struct Node));
				$$->node_value->type=$1->type;
				switch($1->type){
					case integer: $$->node_value->intValue=$1->intValue; $$->node_value->realValue=(float)$1->intValue;	break;
					case boolean: $$->node_value->boolValue=$1->boolValue; $$->node_value->intValue=$1->boolValue;  break;
					case real:	  $$->node_value->realValue=$1->realValue; $$->node_value->intValue=(int)$1->realValue; break;
					case character:	  $$->node_value->charValue=$1->charValue; break;
					case string:  $$->node_value->strValue=(char *)malloc(sizeof(char)*strlen($1->strValue)); 
								  strcpy($$->node_value->strValue, $1->strValue);
								  break;
				}
				$$->left_child=NULL; $$->right_child=NULL;
				$$->next_sibling=NULL;
			}
		|  LP  expression  RP  {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=comparation;
				$$->node_value=(struct Node*)malloc(sizeof(struct Node));
				$$->node_value->type=$2->node_value->type;
				//printf("(expression) %d\n", $$->node_type);
				$$->left_child=$2; $$->right_child=NULL;
				$$->next_sibling=NULL;
			}
		|  MYNOT  factor  {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=logic;
				$$->node_value=(struct Node*)malloc(sizeof(struct Node));
				$$->node_value->type=boolean;
				$$->left_child=$2; $$->right_child=NULL;
				$$->next_sibling=NULL;
			}
		|  MINUS  factor  {
				$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
				$$->node_type=value;
				$$->node_value=(struct Node*)malloc(sizeof(struct Node));
				$$->node_value->type=$2->node_value->type;
				$$->left_child=$2; $$->right_child=NULL;
				$$->next_sibling=NULL;
			}
		|  ID  LB  expression  RB
		|  ID  DOT  ID	
		;
args_list:	expression  COMMA  args_list  { //args_list: used when a function/procedure is called
				$1->next_sibling=$3;
				//printf("$1 type=%d\n", $1->node_type);
				$$=$1;
				args_list_pt=$$;
				//$$->node_type=expr;
			}
		|  expression {
				$1->next_sibling=NULL;	
				//printf("$1 type=%d\n", $1->node_type);
				$$=$1;
				args_list_pt=$$;
				//$$->node_type=expr;
			}
		;
parameters: LP  para_decl_list  RP  {//parameters: used when a function/procedure is defined
					//printf("parameters: (para_decl_list)\n");
					$$=$2;
				}
		;
para_decl_list:	para_type_list  SEMI  para_decl_list  {
					$1->next_sibling=$3;
					$$=$1;
					para_list_pt=$$;
				}
			|	para_type_list  {/*printf("para_decl_list: \n");*/
					$1->next_sibling=NULL;
					$$=$1;
					para_list_pt=$$;
				}
			;
para_type_list: var_para_list  COLON  simple_type_decl  {/*simple_type_decl is an ExpNode, var type has been saved into hashtable*/
						//printf("para_type_list:var_para_list %d\n", $3->type); 
						CopyToVarTable(1, $3->type);
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=parameter;
						$$->left_child=$1; //only one child to record var_para_list
						$$->right_child=NULL; $$->next_sibling=NULL;
					}
			|	val_para_list  COLON  simple_type_decl  {
						//printf("para_type_list:val_para_list %d\n", $3->type); 
						CopyToVarTable(0, $3->type);
						$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
						$$->node_type=parameter;
						$$->left_child=$1; //only one child to record var_para_list
						$$->right_child=NULL; $$->next_sibling=NULL;
					}
			;
var_para_list: VAR  name_list  {/*nlist[] recorded, but has not been added to vartable, wait until reduced to para_type_list*/
								/*during this scope, nlist[] remains the same, DO NOT CLEAR "name_list_cnt"! */
								$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=varpara;

								struct TreeNode* start=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								struct TreeNode* oldtmp=start;
								struct TreeNode* tmp;
								int i;
								for(i=0;i<name_list_cnt;i++){
									tmp=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									tmp->node_type=anid;
									strcpy(tmp->id_name, nlist[i].name);
									printf("namelist[%d]=%s\n", i, tmp->id_name);
									tmp->next_sibling=tmp->left_child=tmp->right_child=NULL;
									oldtmp->next_sibling=tmp;
									oldtmp=tmp;
								}
								$2=start->next_sibling;
								free(start);
								$$->left_child=$2; $$->right_child=NULL; $$->next_sibling=NULL;
							}
			;
val_para_list: name_list  { /*nlist[] recorded, but has not been added to vartable, wait until reduced to para_type_list*/
							/*during this scope, nlist[] remains the same, DO NOT CLEAR "name_list_cnt"! */
								$$=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								$$->node_type=valpara;
								struct TreeNode* start=(struct TreeNode*)malloc(sizeof(struct TreeNode));
								struct TreeNode* oldtmp=start;
								struct TreeNode* tmp;
								int i;
								for(i=0;i<name_list_cnt;i++){
									tmp=(struct TreeNode*)malloc(sizeof(struct TreeNode));
									tmp->node_type=anid;
									strcpy(tmp->id_name, nlist[i].name);
									printf("namelist[%d]=%s\n", i, tmp->id_name);
									tmp->next_sibling=tmp->left_child=tmp->right_child=NULL;
									oldtmp->next_sibling=tmp;
									oldtmp=tmp;
								}
								$1=start->next_sibling;
								free(start);
								$$->left_child=$1; $$->right_child=NULL; $$->next_sibling=NULL;
							}
			;


%%
void simpleOperandCopy(struct Node* oper, struct Node* res){
	res->type=oper->type;
	/*switch(oper->type){
		case integer:	res->intValue=oper->intValue; res->realValue=oper->realValue; break;
		case character:	res->charValue=oper->charValue; break;
		case real:		res->realValue=oper->realValue; res->intValue=oper->intValue; break;
		case string:	res->strValue=(char*)malloc(sizeof(oper->strValue)); strcpy(res->strValue,oper->strValue); break;
		case boolean:	res->boolValue=oper->boolValue; break;
	}*/
}
void simpleOperation(struct Node* oper1, struct Node* oper2, char operation, struct Node* res){
	if((oper1->type==integer) && (oper2->type==integer)){
		/*res->type=integer;
		switch(operation){
			case '+': res->intValue=oper1->intValue + oper2->intValue; break;
			case '-': res->intValue=oper1->intValue - oper2->intValue; break;
			case '*': res->intValue=oper1->intValue * oper2->intValue; break;
			case '/': res->intValue=oper1->intValue / oper2->intValue; break;
			case '%': res->intValue=oper1->intValue % oper2->intValue; break;
			case '|': res->type=boolean; res->boolValue=oper1->intValue || oper2->intValue; break;
			case '&': res->type=boolean; res->boolValue=oper1->intValue && oper2->intValue; break;
		}*/
		switch(operation){
			case '+': 
			case '-': 
			case '*': 
			case '/': 
			case '%': res->type=integer; break;
			case '|': 
			case '&': res->type=boolean; break;
			default: yyerror("Type error");
		}
	}
	else if( (oper1->type==real && oper2->type==integer) 
			|| (oper1->type==integer && oper2->type==real)
			|| (oper1->type==real && oper2->type==real) )
	{
		/*res->type=real;
		switch(operation){
			case '+': res->realValue=oper1->realValue + oper2->realValue; break;
			case '-': res->realValue=oper1->realValue - oper2->realValue; break;
			case '*': res->realValue=oper1->realValue * oper2->realValue; break;
			case '/': res->realValue=oper1->realValue / oper2->realValue; break;
		}*/
		switch(operation){
			case '+': 
			case '-': 
			case '*': 
			case '/': res->type=real; break;
			default: yyerror("Type error");
		}
	}else if((oper1->type==boolean) && (oper2->type==integer)
			|| (oper1->type==integer) && (oper2->type==boolean)
			|| (oper1->type==boolean) && (oper2->type==integer)
			|| (oper1->type==boolean) && (oper2->type==boolean) )
	{
		/*res->type=boolean;
		switch(operation){
			case '|': res->boolValue=oper1->intValue || oper2->intValue; res->intValue=res->boolValue; break;
			case '&': res->boolValue=oper1->intValue && oper2->intValue; res->intValue=res->boolValue; break;
		}*/
		switch(operation){
			case '|': 
			case '&': res->type=boolean; break;
			default: yyerror("Type error");
		}
	}
	else {yyerror("Type error\n");}
}

struct Node* FindConstValue(char *con){
	int i;
	for(i=0;i<const_cnt;i++){
		if(!strcmp(ctable[i].name, con)){
			return ctable[i].value;
		}
	}
	return NULL;
}

int FindIdValue(char *id){
	int cnt=0;
	int hash=CalculateHashNumber(id);
	struct HashTables* idFinder=cur_procedure_vt;
	while(idFinder!=NULL){
		struct VariableTable* tmp=idFinder->proce_table[hash].next;
		while(tmp!=NULL){
			if(!strcmp(tmp->name, id)){
				return (tmp->value->intValue);
			}
			tmp=tmp->next;
		}
		idFinder=idFinder->caller_pointer;
		cnt++;
	}
	return 0;
}

idType FindIdType(char *id){
	int cnt=0;
	int hash=CalculateHashNumber(id);
	//printf("id=%s hash=%d\n", id, hash);
	struct HashTables* idFinder=cur_procedure_vt;
	while(idFinder!=NULL){
		struct VariableTable* tmp=idFinder->proce_table[hash].next;
		while(tmp!=NULL){
			if(!strcmp(tmp->name, id)){
				//printf("tmp->name=%s\n", tmp->name);
				return (tmp->value->type);
				//printf("tmp->value->type=%d\n", tmp->value);
				//if(tmp->value!=NULL && tmp->value->type!=NULL){
					//printf("done\n");
					//return (tmp->value->type);
				//}else{
				//	yyerror("id has no type");
				//	return -1;
				//}
			}
			tmp=tmp->next;
		}
		idFinder=idFinder->caller_pointer;
		cnt++;
	}
	printf("%s: cnt=%d\n", id, cnt);
	char buf[256];
	strcpy(buf, "variable '");
	strcat(buf, id);
	strcat(buf, "' undefined");
	yyerror(buf);
	return -1;
}

idType FindInTypeTable(char * name){
	int i;
	for(i=0;i<type_cnt;i++){
		if(!strcmp(ttable[i].name, name)){
			return ttable[i].type;
		}
	}
	char buf[256];
	strcpy(buf, "type of '");
	strcat(buf, name);
	strcat(buf, "' undefined");
	yyerror(buf);
	return -1;
}

struct TreeNode* FindLabel(int label){
	int i;
	for(i=0; i<label_cnt; i++){
		if(ltable[i].label==label){
			return ltable[i].node_pt;
		}
	}
	yyerror("Undefined label");
}

void CopyToEnumTable(char *tablename){
	int i;
	for(i=0;i<etable_cnt;i++){
		if(!strcmp(etable[i].name, tablename)){
			yyerror("enumeration redeclared");
			return;
		}
	}
	strcpy(etable[etable_cnt].name, tablename);
	etable[etable_cnt].cnt=name_list_cnt;
	for(i=0;i<name_list_cnt;i++){
		//printf("added to enum table: %s\n", nlist[i].name);
		strcpy(etable[etable_cnt].content[i], nlist[i].name);
	}
	name_list_cnt=0;
	etable_cnt++;
}

void CopyToVarTable(int var_copy_to_caller, idType t){//将type类型赋给当前namelist中所有变量
	int i,j,k;
	struct VariableTable* tmp;
	for(i=0;i<name_list_cnt;i++){
		int hash=CalculateHashNumber(nlist[i].name);
		//printf("hash=%d\n", hash);

		tmp=cur_procedure_vt->proce_table[hash].next;
		while(tmp!=NULL){//traverse the list of current hash number
			if(!strcmp(tmp->name, nlist[i].name)){
				char error_msg[256];
				strcpy(error_msg, "Variable '");
				strcat(error_msg, tmp->name);
				strcat(error_msg, "' redeclared");
				yyerror(error_msg);
				break;
			}
			tmp=tmp->next;
		}
		for(k=0;k<const_cnt;k++){//traverse the const table
			if(!strcmp(ctable[k].name, nlist[i].name)){
				char error_msg[256];
				strcpy(error_msg, "Variable '");
				strcat(error_msg, tmp->name);
				strcat(error_msg, "' redeclared (conflict with const)");
				yyerror(error_msg);
				break;
			}
		}
		if(tmp==NULL && k>=const_cnt){
			/*construct a new node, and insert it into list of hash_table[hash]:*/
			struct VariableTable* toBeInserted=(struct VariableTable*)malloc(sizeof(struct VariableTable));
			strcpy(toBeInserted->name, nlist[i].name);
			toBeInserted->copy_to_caller=var_copy_to_caller;
			toBeInserted->value=(struct Node*)malloc(sizeof(struct Node));
			toBeInserted->value->type=t;
			toBeInserted->next=cur_procedure_vt->proce_table[hash].next;
			cur_procedure_vt->proce_table[hash].next=toBeInserted;
		}
	}
	name_list_cnt=0;
}


void CopyToConstTable(struct Node* n1, struct Node* n2){
	n1->type=n2->type;
	switch(n1->type){
		case integer: n1->intValue=n2->intValue; break;
		case real: n1->realValue=n2->realValue; break;
		case character: n1->charValue=n2->charValue; break;
		case string: n1->strValue=(char *)malloc(sizeof(char)*strlen(n2->strValue)); strcpy(n1->strValue, n2->strValue); break;
	}		
}

void CopyToLabelTable(int label, struct TreeNode* tn){
	ltable[label_cnt].label=label;
	ltable[label_cnt].linenum=linenum;
	ltable[label_cnt].node_pt=tn;
	label_cnt++;
}

/*这个函数不能使用，返回值没有计算出来*/
void getReturnValue(struct Node* return_value, char *name){//Find returning value from hashtable where id=function_name
	int hash=CalculateHashNumber(name);
	struct HashTables* idFinder=cur_procedure_vt;
	while(idFinder!=NULL){
		struct VariableTable* tmp=idFinder->proce_table[hash].next;
		while(tmp!=NULL){
			if(!strcmp(tmp->name, name)){
				switch(return_value->type){
					case integer: return_value->intValue=tmp->value->intValue; break;
					case boolean: return_value->boolValue=tmp->value->boolValue; break;
					case real: return_value->realValue=tmp->value->realValue; break;
					case character: return_value->charValue=tmp->value->charValue; break;
					case string: return_value->strValue=(char *)malloc(sizeof(strlen(tmp->value->strValue)*sizeof(char)));
								 strcpy(return_value->strValue, tmp->value->strValue); break;
				}
				return ;
			}
			tmp=tmp->next;
		}
		idFinder=idFinder->caller_pointer;
	}
}

void yyerror(char *s)
{
	printf(">>Error(%d): %s\n", linenum, s);
}
int main(int argc, char **argv)
{	
	if (argc > 1) {
		yyin = fopen(argv[1], "r");
	}
	else {
		fprintf(stdout, "Usage: config <file_path>\n");
		exit(1);
	}

	if (yyin == NULL) {
		fprintf(stdout, "config: file access error. func=%s ", "fopen()");
		fprintf(stdout, "errno=%d(%s) name=%s\n", errno, strerror(errno), argv[0]);
		exit(1);
	}
	yyparse();
	return 0;
}	


