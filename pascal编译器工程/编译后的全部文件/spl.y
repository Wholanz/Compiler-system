%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "macro.h"
#include "symtab.h"
#include "x86.h"
/*head阶段形成符号表，body阶段执行语句查找符号表并汇编*/
extern char *yytext;  //从lex中获取当前term内容
symtab *ptable;       //临时变量
symbol *psymbol, *qsymbol;
type *qtype, *qtype;

extern int error_times; //记录错误次数
symbol *term_stk[MAX_TERM];  //符号栈
int term_stk_tos = MAX_TERM - 1;
symtab*	rtn = NULL;  //子函数返回
symbol*	arg_list = NULL; //参数链表

int is_sysproc = 0;
int sys_type;

%}

%union {
	char 		p_char[NAME_LEN];
	int 		num;
	int 		ascii;
	symbol* 	p_symbol;
	type*		p_type;
	KEYENTRY	*p_lex;
}

%term kAND
%term kARRAY
%term kBEGIN
%term kCASE
%term kCONST
%term kDIV
%term kDO
%term kDOWNTO
%term kELSE
%term kEND
%term kFILE
%term kFOR
%term kFUNCTION
%term kGOTO
%term kIF
%term kIN
%term kLABEL
%term kMOD
%term kNIL
%term kNOT
%term kOF
%term kOR
%term kPACKED
%term kPROCEDURE
%term kPROGRAM
%term kRECORD
%term kREPEAT
%term kSET
%term kTHEN
%term kTO
%term kTYPE
%term kUNTIL
%term kVAR
%term kWHILE
%term kWITH
%term <num>SYS_CON
%term cFALSE
%term cTRUE
%term cMAXINT
%term <p_char>cSTRING
%term <num>cINTEGER
%term <p_char>cREAL
%term <p_char>cCHAR
%term <p_char>cBOOLEAN
%term <p_char>SYS_TYPE
%term tINTEGER
%term tCHAR
%term tREAL
%term tBOOLEAN
%term tTEXT
%term <p_lex>SYS_FUNCT
%term fABS
%term fCHR
%term fODD
%term fORD
%term fPRED
%term fSQR
%term fSQRT
%term fSUCC
%term <p_lex>SYS_PROC
%term pREAD
%term pREADLN

%term  pWRITE
%term  pWRITELN
%term  oPLUS
%term  oMINUS
%term  oMUL
%term  oDIV
%term  oEQUAL
%term  oASSIGN
%term  oUNEQU
%term  oLT
%term  oLE
%term  oGT
%term  oGE
%term  oCOMMA
%term  oSEMI
%term  oCOLON
%term  oQUOTE
%term  oDOT
%term  oDOTDOT
%term  oARROW
%term  oLP
%term  oRP
%term  oLB
%term  oRB
%term  oLC
%term  oRC
%term  <p_char>yNAME


%type  <num>proc_stmt assign_stmt
%type  <num>expression expression_list
%type  <p_symbol>factor term expr
%type  <p_symbol>const_value
%type  <p_symbol>name_list
%type  <p_symbol>val_para_list var_para_list
%type  <num>direction
%type  <p_type>type_decl_list type_definition
%type  <p_type>type_decl simple_type_decl
%type  <p_type>array_type_decl record_type_decl
%type  <p_symbol>field_decl field_decl_list

%start  program

%%

program
:init_env program_head sub_program oDOT
{
	pop_symtab_stack();
	emit_main_epilogue(Global_symtab);
	emit_program_epilogue(Global_symtab);
	return 0;
}
;

init_env //用于初始化
:   
{
	new_symtab(NULL);
	make_system_symtab();
	push_symtab_stack(Global_symtab);
};

program_head
:kPROGRAM yNAME oSEMI 
{
	strcpy(Global_symtab->name, $2);
	snprintf(Global_symtab->label, sizeof(Global_symtab->label), "main");
	Global_symtab->obj_type = DEF_PROG;
	emit_program_prologue(Global_symtab);

}
|error oSEMI
;

sub_program
:routine_head
{
	emit_main_prologue(Global_symtab);

}
routine_body
{
}
;

name_list
:name_list oCOMMA yNAME 
{
	psymbol = new_symbol($3, DEF_UNKNOWN, TYPE_UNKNOWN);
	for(qsymbol = $1; qsymbol->next; qsymbol = qsymbol->next);
	qsymbol->next = psymbol; psymbol ->next = NULL;
	$$ = $1;
}
|yNAME
{
	psymbol = new_symbol($1, DEF_UNKNOWN, TYPE_UNKNOWN);
	$$ = psymbol;
}
|yNAME error oSEMI{}
|yNAME error oCOMMA{}
;

sub_routine
:routine_head routine_body
;

routine_head
:label_part const_part type_part var_part routine_part
{
	emit_routine_prologue(top_symtab_stack());
}
;

label_part
:
;

const_part
:kCONST const_expr_list
|
;

const_expr_list
:const_expr_list yNAME oEQUAL const_value oSEMI
{
	/* change name of symbol const_value to yNAME */
	strncpy($4->name, $2, NAME_LEN);
	add_symbol_to_table(
		top_symtab_stack(), $4);
}
|yNAME oEQUAL const_value oSEMI
{
	/* change name of symbol const_value to yNAME */
	strncpy($3->name, $1, NAME_LEN);
	add_symbol_to_table(
		top_symtab_stack(),$3);
}
;

const_value
:cINTEGER
{
	psymbol = new_symbol("$$$", DEF_CONST,
		TYPE_INTEGER);
	psymbol->v.i = $1;
	$$ = psymbol;
}
|cREAL
{
	psymbol = new_symbol("$$$",DEF_CONST,
		TYPE_REAL);

	psymbol->v.f = atof($1);
	$$ = psymbol;
}
|cCHAR
{
	psymbol = new_symbol("$$$", DEF_CONST,
		TYPE_CHAR);

	psymbol->v.c= $1[1];
	$$ = psymbol;
}
|cSTRING
{
	psymbol = new_symbol("$$$",DEF_CONST,
		TYPE_STRING);

	psymbol->v.s = strdup($1);
	$$ = psymbol;
}
|SYS_CON
{
	psymbol = new_symbol("$$$", DEF_CONST,
		TYPE_UNKNOWN);

	switch($1)
	{
	case cMAXINT:
		strcpy(psymbol->label, "maxint");
		psymbol->v.i = 2147483647;
		psymbol->type = find_type_by_id(TYPE_INTEGER);
		break;

	case cFALSE  :
		strcpy(psymbol->label, "0");
		psymbol->v.b = 0;
		psymbol->type = find_type_by_id(TYPE_BOOLEAN);
		break;
		  
	case cTRUE:
		strcpy(psymbol->label, "1");
		psymbol->v.b = 1;
		psymbol->type = find_type_by_id(TYPE_BOOLEAN);
		break; 

	default:
		psymbol->type = find_type_by_id(TYPE_VOID);
		break;
	}

	$$ = psymbol;
}
;

type_part
:kTYPE type_decl_list
|
;

type_decl_list
:type_decl_list type_definition
|type_definition
;

type_definition
:yNAME oEQUAL type_decl oSEMI
{
	if($3->name[0] == '$')
	{
		/* a new type. */
		$$ = $3;
		strncpy($$->name, $1, NAME_LEN);
	}
	else{
		/* an existed type. */
		$$ = clone_type($3);
		strncpy($$->name, $1, NAME_LEN);
		add_type_to_table(
			top_symtab_stack(), $$);
	}
}
;

type_decl
:simple_type_decl
|array_type_decl
|record_type_decl
;

array_type_decl
:kARRAY oLB simple_type_decl oRB kOF type_decl
{
	$$ = new_array_type("$$$", $3, $6);
	add_type_to_table(
		top_symtab_stack(),$$);
} 
;

record_type_decl
:kRECORD field_decl_list kEND
{ 
	qtype = new_record_type("$$$", $2);
 	add_type_to_table(top_symtab_stack(), qtype);
	$$ = qtype;
}
;

field_decl_list
:field_decl_list field_decl
{
    for(psymbol = $1; psymbol->next; psymbol = psymbol->next);
	psymbol->next = $2;
	$$ = $1;  
}
|field_decl
{
	$$ = $1;
}
;

field_decl
:name_list oCOLON type_decl oSEMI
{    
	for(psymbol = $1; psymbol; psymbol = psymbol->next) {
		if($3->type_id == TYPE_SUBRANGE)
			psymbol->type = $3->begin->type;
		else if($3->type_id == TYPE_ENUM)
			psymbol->type = find_type_by_id(TYPE_INTEGER);
		else
			psymbol->type = find_type_by_id($3->type_id);

		psymbol->type_link = $3;
		psymbol->obj_type = DEF_FIELD;
	}
	$$ = $1;
}
;

simple_type_decl
:SYS_TYPE
{
	qtype = find_type_by_name($1);
	if(!qtype)
		parse_error("Undeclared type name",$1);
	$$ = qtype;
}
|yNAME
{
	qtype = find_type_by_name($1);
	if (!qtype)
	{
		parse_error("Undeclared type name", $1);
		return 0;
	}
	$$ = qtype;
}
|oLP name_list oRP
{
	$$ = new_enum_type("$$$");
	add_enum_elements($$, $2);
	add_type_to_table(
		top_symtab_stack(),$$);
}
|const_value oDOTDOT const_value
{
	if($1->type->type_id != $3->type->type_id){
		parse_error("type mismatch","");
		return 0;
	}
	$$ = new_subrange_type("$$$", $1->type->type_id);
	add_type_to_table(
		top_symtab_stack(), $$);

	if($1->type->type_id == TYPE_INTEGER)
		set_subrange_bound($$,
			(int)$1->v.i,(int)$3->v.i);
	else if ($1->type->type_id == TYPE_BOOLEAN)
		set_subrange_bound($$,
			(int)$1->v.b,(int)$3->v.b);
	else if ($1->type->type_id == TYPE_CHAR)
		set_subrange_bound($$,
			(int)$1->v.c,(int)$3->v.c);
	else
		parse_error("invalid element type of subrange","");
}
|oMINUS const_value oDOTDOT const_value
{
	if($2->type->type_id != $4->type->type_id){
		parse_error("type mismatch","");
		/* return 0; */
	}

	$$ = new_subrange_type("$$$",
		$2->type->type_id);
		
	add_type_to_table(
		top_symtab_stack(),$$);

	if($2->type->type_id == TYPE_INTEGER){
		$2->v.i= -$2->v.i;
		set_subrange_bound($$,
			(int)$2->v.i,(int)$4->v.i);
	}
	else if ($2->type->type_id == TYPE_BOOLEAN){
		$2->v.b ^= 1;
		set_subrange_bound($$,
			(int)$2->v.b,(int)$4->v.b);
	}
	else if ($2->type->type_id == TYPE_CHAR)
		parse_error("invalid operator","");
	else
   		parse_error("invalid element type of subrange","");
}
|oMINUS const_value oDOTDOT oMINUS const_value
{
	if($2->type->type_id != $5->type->type_id) {
		parse_error("type mismatch.","");
		return  0;
	}
	
	$$ = new_subrange_type("$$$", $2->type->type_id);

	add_type_to_table(
		top_symtab_stack(),$$);

	if($2->type->type_id == TYPE_INTEGER){
		$2->v.i = -$2->v.i;
		$5->v.i = -$5->v.i;
	
		set_subrange_bound($$,(int)$2->v.i,
			(int)$5->v.i);
	}
	else if ($2->type->type_id == TYPE_BOOLEAN){
		$2->v.b ^= 1;
		$5->v.b ^= 1;
		set_subrange_bound($$,(int)$2->v.b,
		(int)$5->v.b);
	}
	else if ($2->type->type_id == TYPE_CHAR)
		parse_error("invalid operator","");
	else
		parse_error("invalid element type of subrange","");
}
|yNAME oDOTDOT yNAME
{
	psymbol = find_element(top_symtab_stack(), $1);

	if(!psymbol){
		parse_error("Undeclared identifier", $1);
		psymbol = new_symbol($1, DEF_ELEMENT, TYPE_INTEGER);
		add_local_to_table(top_symtab_stack(), psymbol);
	}
	
	if(psymbol->obj_type != DEF_ELEMENT){
		parse_error("not an element identifier", $1);
		/* return 0; */
	}
	
	qsymbol = find_element(top_symtab_stack(), $3);
	if(!qsymbol){
		parse_error("Undeclared identifier", $3);
		psymbol = new_symbol($3, DEF_ELEMENT, TYPE_INTEGER);
		add_local_to_table(top_symtab_stack(), psymbol);	
		/* return 0; */
	}
	if(qsymbol->obj_type != DEF_ELEMENT){
		parse_error("Not an element identifier", $3);
		/* return 0; */
	}
	
	if(psymbol && qsymbol){
		$$ = new_subrange_type("$$$", TYPE_INTEGER);
		add_type_to_table(
			top_symtab_stack(),$$);
		set_subrange_bound($$, psymbol->v.i, qsymbol->v.i);
	}
	else
		$$ = NULL;
}
;

var_part
:kVAR var_decl_list
|
;

var_decl_list
:var_decl_list var_decl
|var_decl
;

var_decl
:name_list oCOLON type_decl oSEMI
{    
	ptable = top_symtab_stack();
	
	for(psymbol = $1; psymbol ;){
		if($3->type_id == TYPE_SUBRANGE)
			psymbol->type = find_type_by_id($3->begin->type->type_id);
		else if($3->type_id == TYPE_ENUM)
			psymbol->type = find_type_by_id(TYPE_INTEGER);
		else
			psymbol->type = find_type_by_id($3->type_id);

		psymbol->type_link = $3;
		psymbol->obj_type = DEF_VAR;

		qsymbol = psymbol; psymbol = psymbol->next;
		qsymbol->next = NULL;
		add_symbol_to_table(ptable, qsymbol);
	}
	$1 = NULL;
}
;

routine_part
:routine_part function_decl
|routine_part procedure_decl
|function_decl
|procedure_decl
|
;

function_decl
:function_head oSEMI sub_routine oSEMI 
{
	emit_routine_epilogue(top_symtab_stack());

	pop_symtab_stack();
}
;

function_head
:kFUNCTION
{

	ptable = new_symtab(top_symtab_stack());
	push_symtab_stack(ptable);
}
yNAME parameters oCOLON
simple_type_decl
{
	ptable = top_symtab_stack();
	strncpy(ptable->name, $3, NAME_LEN);
	sprintf(ptable->label, "rtn%03d",ptable->id);
	ptable->obj_type = DEF_FUNCT;
	
	if($6->type_id == TYPE_SUBRANGE)
		ptable->type = $6->begin->type;
	else if($6->type_id == TYPE_ENUM)
		ptable->type = find_type_by_id(TYPE_INTEGER);
	else
		ptable->type = find_type_by_id($6->type_id);

	psymbol = new_symbol($3, DEF_FUNCT, ptable->type->type_id);
	psymbol->type_link = $6;
	add_symbol_to_table(ptable, psymbol);
	reverse_parameters(ptable);
}
;

procedure_decl
:procedure_head oSEMI sub_routine oSEMI
{
	emit_routine_epilogue(top_symtab_stack());

	pop_symtab_stack();
}
;

procedure_head
:kPROCEDURE
{

	ptable = new_symtab(top_symtab_stack());
	push_symtab_stack(ptable);
}
yNAME parameters
{
	ptable = top_symtab_stack();
	strncpy(ptable->name, $3, NAME_LEN);
	sprintf(ptable->label, "rtn%03d",ptable->id);
	ptable->obj_type = DEF_PROC;
	psymbol = new_symbol($3, DEF_PROC, TYPE_VOID);
	add_symbol_to_table(ptable,psymbol);
	reverse_parameters(ptable);

}
;

parameters
:oLP para_decl_list oRP
{
	ptable = top_symtab_stack();
	ptable->local_size = 0;
}
|
;

para_decl_list
:para_decl_list oSEMI para_type_list
|para_type_list
;

para_type_list
: val_para_list oCOLON simple_type_decl
{
	ptable = top_symtab_stack();
	for(psymbol = $1; psymbol ;){
		if($3->type_id
			== TYPE_SUBRANGE)
			psymbol->type = $3->begin->type;
		else if ($3->type_id == TYPE_ENUM)
			psymbol->type = find_type_by_id(TYPE_INTEGER);
		else
			psymbol->type = find_type_by_id($3->type_id);
		psymbol->type_link = $3;
		psymbol->obj_type = DEF_VALPARA;

		qsymbol = psymbol; psymbol = psymbol->next;
		qsymbol->next = NULL;
		add_symbol_to_table(ptable,qsymbol);
	}

	$1 = NULL;
}
| var_para_list oCOLON simple_type_decl
{
	ptable = top_symtab_stack();
	for(psymbol = $1; psymbol;){
		if($3->type_id == TYPE_SUBRANGE)
			psymbol->type = $3->begin->type;
		else if($3->type_id == TYPE_ENUM)
			psymbol->type = find_type_by_id(TYPE_INTEGER);
		else
			psymbol->type = find_type_by_id($3->type_id);
		psymbol->type_link = $3;
		psymbol->obj_type = DEF_VARPARA;
		qsymbol = psymbol; psymbol = psymbol->next;
		qsymbol->next=NULL;
		add_symbol_to_table(ptable,qsymbol);
	}
	$1 = NULL;
}
;

val_para_list
:name_list
;

var_para_list
:kVAR name_list
{
	$$ = $2;
}
;

routine_body
:compound_stmt
;

stmt_list
:stmt_list stmt oSEMI
|stmt_list error oSEMI
|
;

stmt
:cINTEGER oCOLON non_label_stmt
| non_label_stmt
;

non_label_stmt
:assign_stmt
| proc_stmt
| compound_stmt
| if_stmt
| repeat_stmt
| while_stmt
| for_stmt
| case_stmt
| goto_stmt
|
;

assign_stmt
:yNAME oASSIGN expression
{
	psymbol = find_symbol(top_symtab_stack(), $1);
	if (psymbol == NULL)
	{
		parse_error("Undefined identifier", $1);
		psymbol = new_symbol($1, DEF_VAR, TYPE_INTEGER);
		add_local_to_table(top_symtab_stack(), psymbol);	
	}
	if(psymbol->type->type_id == TYPE_ARRAY
		||psymbol->type->type_id == TYPE_RECORD)
	{
		parse_error("lvalue expected","");
		/* return 0; */
	}

	if (psymbol && psymbol->obj_type != DEF_FUNCT)
	{
		if(psymbol->type->type_id != $3)
		{
			parse_error("type mismatch","");
			/* return 0; */
		}
	}
	else
	{
		ptable = find_routine($1);
		if(ptable)
		{
			if(ptable->type->type_id != $3)
			{
				parse_error("type mismatch","");
				/* return 0; */
			}
		}
		else{
			parse_error("Undeclared identifier.",$1);
			psymbol = new_symbol($1, DEF_VAR, $3);
			add_local_to_table(top_symtab_stack(), psymbol);	

			/* return 0; */
		}
	}

	
	if (psymbol && psymbol->obj_type != DEF_FUNCT)
	{
		do_assign(psymbol, $3);
	}
	else
	{
		do_function_assign(ptable, $3);
	}
}
|yNAME oLB
{
	psymbol = find_symbol(top_symtab_stack(), $1);
	if(!psymbol || psymbol->type->type_id != TYPE_ARRAY){
		parse_error("Undeclared array name",$1);
		return 0;
	}
	
	term_stk[term_stk_tos--] = psymbol;
	emit_load_address(psymbol);
	emit_push_op(TYPE_INTEGER);
}
expression oRB
{
	psymbol = term_stk[term_stk_tos + 1];
	do_array_factor(psymbol);
}
oASSIGN expression
{
	psymbol = term_stk[++term_stk_tos];
	do_assign(psymbol, $8);
}
|yNAME oDOT yNAME
{
	psymbol = find_symbol(top_symtab_stack(),$1);
	if(!psymbol || psymbol->type->type_id != TYPE_RECORD){
		parse_error("Undeclared record vaiable",$1);
		return 0;
	}

	qsymbol = find_field(psymbol,$3);
	if(!qsymbol || qsymbol->obj_type != DEF_FIELD){
		parse_error("Undeclared field",$3);
		return 0;
	}

	emit_load_address(psymbol);
	emit_push_op(TYPE_INTEGER);
	do_record_factor(psymbol,qsymbol);
	term_stk[term_stk_tos--] = psymbol;
	term_stk[term_stk_tos--] = qsymbol;
}
oASSIGN expression
{
	qsymbol = term_stk[++term_stk_tos];
	psymbol = term_stk[++term_stk_tos];
	do_assign(qsymbol, $6);
}
;

proc_stmt
:yNAME
{
	ptable = find_routine($1);
	if(!ptable || ptable->obj_type != DEF_PROC){
		parse_error("Undeclared procedure",$1);
		return 0;
	}

	do_procedure_call(ptable);
}
|yNAME
{
	ptable = find_routine($1);
	if(!ptable || ptable->obj_type != DEF_PROC){
			parse_error("Undeclared procedure",$1);
			return 0;
	}
	push_call_stack(ptable);
}
oLP args_list oRP
{
	do_procedure_call(top_call_stack());
	pop_call_stack();
}
|SYS_PROC
{
	do_sys_routine($1->attr, 0);
}
|SYS_PROC 
{
	rtn = find_sys_routine($1->attr);

	if(rtn)
		arg_list = rtn->args;
	else
	{
		arg_list = NULL;
	}

	push_call_stack(rtn);
	is_sysproc = 1;
	sys_type = $1 -> attr;
}
oLP expression_list oRP 
{
	//do_sys_routine($1->attr, $4);
	
	new_line();

	pop_call_stack();
	is_sysproc = 0;
}
|pREAD oLP factor oRP
{
	if(!$3){
		parse_error("too few parameters in call to", "read");
		return 0;
	}
	emit_load_address($3);
	do_sys_routine(pREAD, $3->type->type_id);
}
;

compound_stmt
:kBEGIN
{
}
stmt_list
kEND
{
}
;

if_stmt
:kIF 
{
}
expression kTHEN
{
	do_if_test();
}
stmt
{
	do_if_clause();
}
else_clause
{
	do_if_exit();
}
|kIF error 
{
	printf("expression expected.\n");
}
kTHEN 
{
	printf("then matched.\n");
}
stmt else_clause
;

else_clause
:kELSE stmt
|
;

repeat_stmt
:kREPEAT
{
	do_repeat_start();
}
stmt_list kUNTIL expression
{
	do_repeat_exit();
}
;

while_stmt
:kWHILE
{
	do_while_start();
}
expression kDO
{
	do_while_expr();
}
stmt
{
	do_while_exit();
}
;

for_stmt
:kFOR yNAME oASSIGN expression
{
	psymbol = find_symbol(top_symtab_stack(),$2);
	if(!psymbol || psymbol->obj_type != DEF_VAR)
	{
		parse_error("lvalue expected","");
		return 0;
	}

	if(psymbol->type->type_id == TYPE_ARRAY
		||psymbol->type->type_id == TYPE_RECORD)
	{
		parse_error("lvalue expected","");
		return 0;
	}
	do_for_start(psymbol);
}
direction expression kDO
{
	do_for_test($6);
}
stmt
{
	do_for_exit();
}
;

direction
:kTO
{
	$$ = kTO;
}
|kDOWNTO
{
	$$ = kDOWNTO;
}
;

case_stmt
:kCASE 
{
}
expression kOF
{
	do_case_start();
}
case_expr_list
{
	do_case_test();
}
kEND
;

case_expr_list
:case_expr_list case_expr
|case_expr
;

case_expr
:const_value
{
	add_case_const($1);
}
oCOLON stmt
{
	do_case_jump();
}
oSEMI
|yNAME
{
	psymbol = find_symbol(
		top_symtab_stack(),$1);
	if(!psymbol){
			parse_error("Undeclared identifier",$1);
			psymbol = new_symbol($1, DEF_CONST, TYPE_INTEGER);
			add_local_to_table(top_symtab_stack(), psymbol);	

			/* return 0; */
	}
	if(psymbol->obj_type != DEF_ELEMENT
		&&psymbol->obj_type != DEF_CONST){
			parse_error("Element name expected","");
			return 0;
	}
	emit_load_value(psymbol);
	add_case_const(psymbol);
}
oCOLON stmt
{
	do_case_jump();
}
oSEMI
;

goto_stmt
:kGOTO cINTEGER
;

expression_list
:expression_list  oCOMMA  expression
{
}
|expression
{
}
;

expression
:expression
{
    emit_push_op($1);
}
oGE expr
{
	do_expression($4, oGE);
	$$ = TYPE_BOOLEAN;
}
|expression
{
   	emit_push_op($1);
}
oGT expr
{
	do_expression($4, oGT);
	$$ = TYPE_BOOLEAN;
}
|expression
{
   emit_push_op($1);
}
oLE expr
{
	do_expression($4,oLE);
	$$ = TYPE_BOOLEAN;
}
|expression
{
	emit_push_op($1);
}
oLT expr
{
	do_expression($4,oLT);
	$$ = TYPE_BOOLEAN;
}
|expression
{
	emit_push_op($1);
}
oEQUAL expr
{
	do_expression($4,oEQUAL);
	$$ = TYPE_BOOLEAN;
}
|expression
{
	emit_push_op($1);
}
oUNEQU  expr
{
	do_expression($4,oUNEQU);
	$$ = TYPE_BOOLEAN;
}
|expr
{
	$$ = $1->type->type_id;
}
;

expr:expr
{
	emit_push_op($1->type->type_id);
}
oPLUS term
{
	do_expr($4,oPLUS);
}
|expr
{
	emit_push_op($1->type->type_id);
}
oMINUS  term
{
	do_expr($4 ,oMINUS);
}
|expr
{
	emit_push_op($1->type->type_id);
}
kOR term
{
	do_expression($4,kOR);
}
|term
{
}
;

term    :term
{
        emit_push_op($1->type->type_id);
}
oMUL  factor
{
	do_term($4,oMUL);
}
|  term
{
	emit_push_op($1->type->type_id);
}
oDIV factor
{
	do_term($4,kDIV);
}
|term
{
	emit_push_op($1->type->type_id);

}
kDIV factor
{
	do_term($4, kDIV);
}
|term
{
	emit_push_op($1->type->type_id);

}
kMOD factor
{
	do_term($4, kMOD);
}
|term
{
	emit_push_op($1->type->type_id);
}
kAND factor
{
	do_term($4,kAND);
}
|factor
{
	$$ = $1;
}
;

factor: yNAME
{ 
	psymbol = NULL;

	if((psymbol = find_symbol(
		top_symtab_stack(),$1)))
	{
		if(psymbol->type->type_id == TYPE_ARRAY
			||psymbol->type->type_id == TYPE_RECORD)
		{
			parse_error("rvalue expected",  "");
			return 0;
		}
		
	}
	
	else if ((ptable = find_routine($1)) == NULL)
	{
		parse_error("Undeclard identificr",$1);
		psymbol = new_symbol($1, DEF_VAR, TYPE_INTEGER);
		add_local_to_table(top_symtab_stack(), psymbol);	

		/* return  0; */
	}
	if(psymbol)
	{
		$$ = psymbol;
		do_factor(psymbol);

		if(is_sysproc){
			if(sys_type != pWRITELN){
				do_sys_routine(sys_type, psymbol->type->type_id);
			}
			else{
				do_sys_routine(pWRITE, psymbol->type->type_id);
			}
		}

	}
	

	else 
	{
		$$ = do_function_call(ptable);
	}
}
|yNAME
{
	if((ptable = find_routine($1)))
  		push_call_stack(ptable);
	else
	{
		parse_error("Undeclared funtion",$1);
		return  0;
	}
}
oLP args_list oRP
{
	$$ = do_function_call(top_call_stack());
	pop_call_stack();
}
|SYS_FUNCT
{
	ptable = find_sys_routine($1->attr);
	do_sys_routine(ptable->id, ptable->type->type_id);
	$$ = ptable->locals;
}
|SYS_FUNCT
{
	ptable = find_sys_routine($1->attr);
	push_call_stack(ptable);
}
oLP args_list oRP
{
	ptable = top_call_stack();
	ptable = top_call_stack();
	do_sys_routine(-ptable->id, ptable->type->type_id);
	ptable = pop_call_stack();
	$$ = ptable->locals;
}
|const_value
{	
	switch($1->type->type_id){
		case TYPE_REAL:
		case TYPE_STRING:
			add_symbol_to_table(Global_symtab, $1);
			break;
		case TYPE_BOOLEAN:
			sprintf($1->label, "%d", (int)($1->v.b));
			break;
		case TYPE_INTEGER:
			if($1->v.i > 0)
				sprintf($1->label,"0%xh", $1->v.i);
			else
				sprintf($1->label, "-0%xh", -($1->v.i));
			break;
		case TYPE_CHAR:
			sprintf($1->label, "'%c'", $1->v.c);
			break;
		default:
			break;
	}
	do_factor($1);
	if(is_sysproc){
			if(sys_type != pWRITELN){
				do_sys_routine(sys_type, $1->type->type_id);
			}
			else{
				do_sys_routine(pWRITE, $1->type->type_id);
			}
		}
}
|oLP expression oRP
{
	$$ = find_symbol(NULL, "");
	$$->type = find_type_by_id($2);
}
|kNOT factor
{
	do_not_factor($2);
	$$ = $2;
}
|oMINUS factor
{
	do_negate($2);
	$$ = $2;
}
|yNAME  oLB
{
	psymbol = find_symbol(
		top_symtab_stack(), $1);
		   
	if(!psymbol || psymbol->type->type_id != TYPE_ARRAY){
		parse_error("Undeclared array  name",$1);
		return  0;
	}

	term_stk[term_stk_tos--] = psymbol;

	emit_load_address(psymbol);
  	emit_push_op(TYPE_INTEGER);
}
expression oRB
{
	psymbol = term_stk[++term_stk_tos];
	do_array_factor(psymbol);
	emit_load_value(psymbol);
	$$ = psymbol->type_link->end;
}
|yNAME oDOT yNAME
{
	psymbol = find_symbol(top_symtab_stack(), $1);
	if(!psymbol || psymbol->type->type_id != TYPE_RECORD) {
		parse_error("Undeclared record variable",$1);
		return  0;
	}
	qsymbol = find_field(psymbol, $3);
	if(!qsymbol || qsymbol->obj_type != DEF_FIELD){
		parse_error("Undeclared field ",$3);
		return 0;
	}
	
	emit_load_address(psymbol);
	emit_push_op(TYPE_INTEGER);
	do_record_factor(psymbol,qsymbol);
	emit_load_field(qsymbol);
	$$ = qsymbol;
}
;

args_list
:args_list  oCOMMA  expression 
{
	do_args($3);
}
|expression 
{
	do_first_arg($1);
}
;

%%

void yyerror(const char *info)
{
    parse_error(info,"");
}

void parse_error(const char *info, char *name)
{
    fprintf(stderr, "\nError at line %d:\n", line_no);
    fprintf(stderr, "%s\n", line_buf);

    if (*name)
        fprintf(stderr, " : %s %s", info, name);
    else
        fprintf(stderr, " : %s \n", info);

    error_times++;
}