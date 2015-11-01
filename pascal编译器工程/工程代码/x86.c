#include  <stdio.h>
#include  "macro.h"
#include  "symtab.h"
#include  "x86.h"
#include "yyout.h"
#define  MAX_LOOP_LEVEL  16
#define  STMT_STACK_SIZE 64
#define  MAX_CALL_LEVEL 16

static int emit_linux_address = 0;
static symtab *rtn =NULL;
static symbol *arg = NULL;
static int gen_level = 0;
static symbol*   p;
static symtab*  ptab;

 int sym_tos = MAX_LOOP_LEVEL-1;
 int direc_stk[MAX_LOOP_LEVEL];
 int dir_tos = MAX_LOOP_LEVEL-1;
 int stmt_tos = STMT_STACK_SIZE - 1;
 int stmt_stack[STMT_STACK_SIZE];
 symbol *sym_stk[MAX_LOOP_LEVEL];
 int stmt_index = 0;
 int call_tos = MAX_CALL_LEVEL-1;
 symbol *call_sym[MAX_CALL_LEVEL];
 symtab *call_stk[MAX_CALL_LEVEL];
 

 symbol *do_function_call(symtab *);
 void emit_program_head();
 void emit_program_prologue(symtab *);
 void emit_program_epilogue(symtab *);
 void emit_main_prologue(symtab *);
 void emit_main_epilogue(symtab *);
 void emit_routine_prologue(symtab *);
 void emit_routine_epilogue(symtab *);
 void emit_local_args(symtab *);
 void emit_push_op(int);
 void emit_load_value(symbol *);
 void do_function_assign(symtab *,int);
 void do_procedure_call(symtab *);
 void do_assign(symbol *, int);
 void do_if_test();
 void do_if_caluse();
 void do_if_exit();
 void do_repeat_start();
 void do_repeat_exit();
 void do_while_start();
 void do_while_expr();
 void do_while_exit();
 void do_for_start(symbol *);
 void do_for_test(int);
 void do_for_exit();
 void do_expression(symbol *, int);
 void do_negate(symbol *);
 void do_expr(symbol *, int);
 void do_term(symbol *, int);
 void do_factor(symbol *);
 void do_no_factor(symbol *);
 void do_array_factor(symbol *);
 void do_record_factor(symbol *, symbol *);
 void do_first_arg(int);
 void reset_args(symtab *);
 void push_stmt_stack(int);
 int pop_stmt_stack();
 int top_stmt_stack();
 int rout_index = 0;

 void do_sys_routine(int routine_id, int arg_type)
{
    switch(routine_id)
    {
    case fABS:
        emit_abs(arg_type);
        break;
    case fODD:
        emit_odd(arg_type);
        break;
    case  fPRED:
        fprintf(asmfp, "        dec    ax\n");
        break;
    case  fSQR:
        emit_sqr(arg_type);
        break;
    case fSQRT:
        emit_sqrt(arg_type);
        break;
    case fSUCC:
        fprintf(asmfp, "        inc    ax\n");
        break;
    case pREAD:
        emit_read1(arg_type);
        break;
    case pREADLN:
        emit_read1(arg_type);
        break;
    case pWRITE:
        emit_write1(arg_type);
        break;
    case  pWRITELN:
        emit_writeln(arg_type);
        break;
    default:
        break;
    }
}

 void emit_read1(int arg_type)
{
    fprintf(asmfp, "        push    ax\n");
    fprintf(asmfp, "        push    bp\n");
    switch(arg_type)
    {
    case  TYPE_REAL:
        break;
    case  TYPE_INTEGER:
        fprintf(asmfp, "        call    _read_int\n");
        break;
    case TYPE_STRING:
        fprintf(asmfp, "        call    _read_string\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "        call    _read_char\n");
        break;
    case   TYPE_BOOLEAN:
    default:
        parse_error("operand type do not match operator.", "");
		printf("emit_read1\n");
        break;
    }
}

 void emit_write1(int arg_type)
{
    switch(arg_type)
    {
    case TYPE_INTEGER:
	case TYPE_BOOLEAN:
        fprintf(asmfp, "        push    ax\n");
        fprintf(asmfp, "        push    bp\n");
        fprintf(asmfp, "        call    _write_int\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "        mov    dl,al\n");
        fprintf(asmfp, "        mov    ah,2\n");
        fprintf(asmfp, "        int    21h\n");
        break;
    case TYPE_STRING:
        fprintf(asmfp, "        push    ax\n");
        fprintf(asmfp, "        push    bp\n");
        fprintf(asmfp, "        call    _write_string\n");
        break;
    default:
        break;
    }
}

 void emit_writeln(int arg_type)
{
    switch(arg_type)
    {
    case TYPE_INTEGER:
	case TYPE_BOOLEAN:
        fprintf(asmfp, "        push    ax\n");
        fprintf(asmfp, "        push    bp\n");
        fprintf(asmfp, "        call    _writeln_int\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "        mov    dl,al\n");
        fprintf(asmfp, "        mov    ah,2\n");
        fprintf(asmfp, "        int    21h\n");
        fprintf(asmfp, "        mov    dl,13\n");
        fprintf(asmfp, "        int    21h\n");
        fprintf(asmfp, "        mov    dl,10\n");
        fprintf(asmfp, "        int    21h\n");
        break;
    case  TYPE_STRING:
        fprintf(asmfp, "        push    ax\n");
        fprintf(asmfp, "        push    bp\n");
        fprintf(asmfp, "        call    _writeln_string\n");
        break;
    default:
        break;
    }
}

 void emit_abs(int arg_type)
{
    fprintf(asmfp, "        push    bp\n");
    switch(arg_type)
    {
    case TYPE_BOOLEAN:
    case TYPE_INTEGER:
        fprintf(asmfp, "        call    _abs_int\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "        xor    ah,ah\n");
        fprintf(asmfp, "        call    _abs_int\n");
        break;
    default:
        break;
    }
}

 void emit_sqr(int arg_type)
{
    fprintf(asmfp, "        push    bp\n");
    switch(arg_type)
    {
    case TYPE_BOOLEAN:
    case TYPE_INTEGER:
        fprintf(asmfp, "        call    _sqr_int\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "        xor    ah,ah\n");
        fprintf(asmfp, "        call    _sqr_int\n");
        break;
    default:
        break;
    }
}

 void emit_odd(int arg_type)
{
    fprintf(asmfp, "        push    bp\n");
    switch(arg_type)
    {
    case TYPE_BOOLEAN:
    case TYPE_INTEGER:
        fprintf(asmfp, "        call    _odd_int\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "        xor    ah,ah\n");
        fprintf(asmfp, "        call    _odd_int\n");
        break;
    default:
        break;
    }
}

 void emit_sqrt(int arg_type)
{
    fprintf(asmfp, "        push    bp\n");
    switch(arg_type)
    {
    case TYPE_BOOLEAN:
    case TYPE_INTEGER:
        fprintf(asmfp, "        call    _sqrt_int\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "        xor    ah,ah\n");
        fprintf(asmfp, "        call    _sqrt_int\n");
        break;
    default:
        break;
    }
}

 void emit_program_prologue(symtab *ptab)
{
    fprintf(asmfp, " \n;alloc stack space\n");
    fprintf(asmfp, "         db    0%xh dup(?)\n"
            ,STACK_SEG_SIZE);
    fprintf(asmfp,"\n_DATA        ends");
    fprintf(asmfp,"\n\n;---program %s ---",ptab->name);
    fprintf(asmfp,"\n\n_TEXT        segment    public\n\n");
    fprintf(asmfp,"        include    x86rtl.inc\n\n");
    fprintf(asmfp,"%s    equ    word ptr [bp+04h]\n"
            ,LABEL_SLINK);
    fprintf(asmfp,"%s    equ    word ptr [bp-04h]\n",
            LABEL_RETVAL);
    fprintf(asmfp,"%s    equ    word ptr [bp-02h]\n",
            LABEL_HIRETVAL);
    emit_program_head();
    fprintf(tmpfp, " \n_DATA        segment    public\n");
}

/* char datname[]; */
 void emit_program_head()
{
    fprintf(tmpfp,";\n");
	fprintf(tmpfp, "\n\n.MODEL SMALL\n");
}

 void emit_program_epilogue(symtab *ptab)
{
    symbol *p;
    fprintf(asmfp,"\n_TEXT        ends\n");
    fprintf(asmfp,"        end _main\n\n");

    fprintf(tmpfp,"\n;global variables\n");

    for(p = ptab->locals; p; p = p->next)
    {
        switch (p->type->type_id)
        {
        case 	TYPE_CHAR:
            fprintf(tmpfp,"%s        db    ",p->label);
            break;
		case	TYPE_BOOLEAN:
        case 	TYPE_INTEGER:
            fprintf(tmpfp,"%s        dw    ",p->label);
            break;
        case 	TYPE_REAL:
            fprintf(tmpfp,"%s        dd    ",p->label);
            break;
        case 	TYPE_STRING:
            fprintf(tmpfp,"%s        db    %s\n",p->label,
                    p->v.s);
            fprintf(tmpfp,"        db    '$'\n");
            break;
        case TYPE_ARRAY:
            if(p->type_link->end->type->type_id == TYPE_INTEGER
                    || p->type_link->end->type->type_id == TYPE_BOOLEAN)
                fprintf(tmpfp,"%s        dw    0%xh dup (?)\n"
                    ,p->label,p->type_link->members);
            else if(p->type_link->end->type->type_id ==
                    TYPE_CHAR)
                fprintf(tmpfp,"%s        db    0%xh dup (?)\n"
                    ,p->label,p->type_link->members);
            else
                parse_error("complex array element not supported","");
            if(p->obj_type != DEF_CONST)
                continue;
            break;
        case   TYPE_RECORD:
            fprintf(tmpfp,"%s        db    0%xh dup (?)\n"
                    ,p->label,p->type_link->size);
            continue;
        default:
            break;
        }

        if (p->obj_type == DEF_CONST)
        {
            switch(p->type->type_id)
            {
            case TYPE_CHAR:
                fprintf(tmpfp,"'%c'\n",p->v.c);
                break;
            case TYPE_INTEGER:
                if (p->v.i >= 0)
                    fprintf(tmpfp, "0%xh\n", p->v.i);
                break;
            case TYPE_REAL:
                fprintf(tmpfp, "%g\n", p->v.f);
                break;
            case TYPE_STRING:
                break;
            default:
                fprintf(tmpfp,"?\n");
            }
        }
        else
            fprintf(tmpfp,"?\n");
    }
}

 void emit_main_prologue(symtab *ptab)
{
    fprintf(asmfp,"\n\n; --- main routine ----\n");
    fprintf(asmfp,"_main        proc    far\n");
    fprintf(asmfp,"        assume    cs:_TEXT,ds:_DATA\n");
    fprintf(asmfp,"        push    ds\n");
    fprintf(asmfp,"        sub    ax,ax\n");
    fprintf(asmfp,"        push    ax\n");
    fprintf(asmfp,"        mov    ax,_DATA\n");
    fprintf(asmfp,"        mov    ds,ax\n");
}

 void emit_main_epilogue(symtab *ptab)
{
    fprintf(asmfp,"        ret\n");
    fprintf(asmfp,"_main        endp\n");
}

 void emit_routine_prologue(symtab *ptab)
{
    if(ptab->obj_type == DEF_PROG)
        return;
    fprintf(asmfp,"\n\n; routine : %s \n",ptab->name);
    emit_local_args(ptab);
    fprintf(asmfp,";routine code\n");
    fprintf(asmfp,"%s        proc\n", ptab->label);
    fprintf(asmfp,"        assume    cs:_TEXT,ds:_DATA\n");
    fprintf(asmfp,"        mov    ax,_DATA\n");
    fprintf(asmfp,"        mov    ds,ax\n");
    fprintf(asmfp,"        push    bp\n");
    fprintf(asmfp,"        mov    bp,sp\n");
    if(ptab->obj_type == DEF_FUNCT)
        fprintf(asmfp,"        sub    sp, 4\n");
    fprintf(asmfp,"        sub    sp,%04xh\n",ptab->local_size);
}

 void emit_local_args(symtab *ptab)
{
    symbol *p;
    char tp[10];
    fprintf(asmfp,";local variables in %s\n",ptab->name);
    for(p = ptab->locals; p->next; p = p->next)
    {
        switch(p->type->type_id)
        {
        case TYPE_CHAR:
            sprintf(tp, "byte  ptr");
            break;
        case TYPE_INTEGER:
        case TYPE_BOOLEAN:
            sprintf(tp, "word  ptr");
            break;
        case TYPE_REAL:
            sprintf(tp, "dword  ptr");
            break;
        case TYPE_ARRAY:
            if(p->type_link->end->type->type_id ==
                    TYPE_INTEGER
                    || p->type_link->end->type->type_id ==
                    TYPE_BOOLEAN)
                sprintf(tp, "word	ptr");
            else if (p->type_link->end->type->type_id == TYPE_CHAR)
                sprintf(tp, "byte	ptr");
            break;
        case TYPE_RECORD:
            sprintf(tp, "byte  ptr");
            break;
        default:
            break;
        }
        fprintf(asmfp,"	%s        equ    %s	[bp-%04xh]\n",
                p->label,tp,p->offset);
    }

    fprintf(asmfp,"; arguments in %s\n", ptab->name);
    for(p =ptab->args;p ;p = p->next)
    {
        switch(p->type->type_id)
        {
        case    TYPE_CHAR:
            sprintf(tp, "byte  ptr");
            break;
        case    TYPE_INTEGER:
        case    TYPE_BOOLEAN:
            sprintf(tp, "word  ptr");
            break;
        case    TYPE_REAL:
            sprintf(tp, "dword  ptr");
            break;
        default:
            break;
        }
        fprintf(asmfp,"%s        equ    %s	[bp+%04xh]\n",
                p->label,tp,p->offset);
    }
}

 void emit_routine_epilogue(symtab *ptab)
{
    if(ptab->obj_type == DEF_PROG)
        return;
    if(ptab->obj_type == DEF_FUNCT)
    {
        switch(ptab->type->type_id)
        {
        case  TYPE_INTEGER:
        case  TYPE_BOOLEAN:
            fprintf(asmfp,"\n        mov    ax, word ptr %s\n",LABEL_RETVAL);
            break;
        case  TYPE_CHAR:
            fprintf(asmfp,"\n        mov    ah, 0\n");
            fprintf(asmfp,"\n        mov    ax, byte  ptr %s\n",
                    LABEL_RETVAL);
            break;
        case  TYPE_REAL:
            fprintf(asmfp,"\n        mov    ax,%s\n",
                    LABEL_RETVAL);
            fprintf(asmfp,"\n        mov    dx,%s\n",
                    LABEL_HIRETVAL);
            break;
        }
    }
    fprintf(asmfp,"        mov    sp,bp\n");
    fprintf(asmfp,"        pop    bp\n");
    fprintf(asmfp,"        ret    %04xh\n",ptab->args_size + 2);
    fprintf(asmfp,"\n%s        endp\n",ptab->label);
}

 void emit_push_op(int ptype)
{
    switch(ptype)
    {
    case  TYPE_CHAR:
    case  TYPE_BOOLEAN:
    case  TYPE_INTEGER:
        fprintf(asmfp,"        push    ax\n");
        break;
    case  TYPE_REAL:
        fprintf(asmfp,"        push    dx\n");
        fprintf(asmfp,"        push    ax\n");
        break;
    }
}

 void emit_load_value(symbol *p)
{
    if(p->obj_type==DEF_VARPARA)
    {
        fprintf(asmfp,"        mov    bx,word ptr [bp+4]\n");
        switch(p->type->type_id)
        {
        case  TYPE_CHAR:
            fprintf(asmfp,"        xor    ah, ah\n");
            fprintf(asmfp,"        mov    al, byte ptr [bx]\n");
            break;
        case TYPE_REAL:
            fprintf(asmfp,"        mov    ax,word ptr [bx]\n");
            fprintf(asmfp,"        mov    dx,word ptr [bx+2]\n");
            break;
        case  TYPE_INTEGER:
        case  TYPE_BOOLEAN:
            fprintf(asmfp,"        mov    ax,word ptr [bx]\n");
            break;
        }
    }
    else if (p->tab->level==0
             ||p->tab==top_symtab_stack())
    {
        switch(p->type->type_id)
        {
        case  TYPE_CHAR:
            fprintf(asmfp,"        sub    ax.ax\n");
            fprintf(asmfp,"\b        mov    al, byte  ptr %s\n"
                    ,p->label);
            break;
        case  	TYPE_REAL:
            fprintf(asmfp,"            mov    ax, word ptr %s\n",p->label);
            fprintf(tmpfp,"            mov    dx, word ptr %s+2\n",p->label);
            break;
        case  	TYPE_INTEGER:
        case  	TYPE_BOOLEAN:
            fprintf(asmfp,"            mov    ax, word ptr %s\n",p->label);
            break;
        case  	TYPE_ARRAY:
            fprintf(asmfp,"        pop    bx\n");
            if(p->type_link->end->type->type_id ==
                    TYPE_INTEGER
                    ||p->type_link->end->type->type_id ==
                    TYPE_BOOLEAN)
                fprintf(asmfp, "        mov    ax,word ptr [bx]\n");
            else if (p->type_link->end->type->type_id ==
                     TYPE_CHAR)
                fprintf(asmfp, "        mov    al,byte ptr [bx]\n");
            break;
        default:
            break;
        }
    }
}

 void emit_load_address(symbol *p)
{
    symtab *ptab;
    int  n,i;
    switch(p->obj_type)
    {
    case DEF_VARPARA:
        fprintf(asmfp, "        mov    ax,word ptr %s\n",
                p->label);
        break;

    case DEF_VAR:
        if(p->tab->level==0
                || p->tab==top_symtab_stack())
        {
            fprintf(asmfp, "        lea    ax,word ptr %s\n",
                    p->label);
        }
        else
        {
            ptab = top_symtab_stack();
            n = p->tab->level - ptab->level + 1;
            fprintf(asmfp,"        mov    bx,bp\n");
            for (i = 0; i < n; i++)
                fprintf(asmfp, "        mov    bp,%s\n",
                        LABEL_SLINK);
            fprintf(asmfp, "        lea    ax,word ptr %s\n",
                    p->label);
            fprintf(asmfp,"        mov    bp,bx\n");
        }
        break;
    case DEF_VALPARA:
        fprintf(asmfp, "        mov    ax,word ptr %s\n",
                p->label);
        break;
    default:
        break;
    }
}

 void emit_load_element()
{
    fprintf(asmfp, "        mov    cx,ax\n");
    fprintf(asmfp, "        pop    ax\n");
    fprintf(asmfp, "        add    ax,cx\n");
}

 void emit_load_field(symbol*p)
{
    if(!p)
        return;
    fprintf(asmfp, "        pop    bx\n");
    switch(p->type->type_id)
    {
    case  TYPE_INTEGER:
    case  TYPE_BOOLEAN:
        fprintf(asmfp,"        mov    ax,word ptr [bx]\n");
        break;
    case  TYPE_CHAR:
        fprintf(asmfp,"        mov    al,byte ptr [bx]\n");
        break;
    default:
        break;
    }
}

 int pop_stmt_stack()
{
    return stmt_stack[++stmt_tos];
}

 void push_stmt_stack(int index)
{
    stmt_stack[stmt_tos--] = index;
}

 int top_stmt_stack()
{
    return stmt_stack[stmt_tos + 1];
}

 void do_function_assign(symtab *ptab, int srctype)
{
    if(!ptab)
        return;

    if(ptab->type->type_id != srctype)
    {
        parse_error("operand type to not match operator.", "");
        return;
    }
    switch(ptab->type->type_id)
    {
    case  TYPE_CHAR:
        fprintf(asmfp,"        xor    ah,ah\n");
        fprintf(asmfp,"        mov    byte ptr %s,al\n",
                LABEL_RETVAL);
        break;
    case  TYPE_BOOLEAN:
    case  TYPE_INTEGER:
        fprintf(asmfp,"        mov    word ptr %s,ax\n",
                LABEL_RETVAL);
        break;
    case  TYPE_REAL:
        fprintf(asmfp,"        mov    word ptr %s,ax\n",
                LABEL_RETVAL);
        fprintf(asmfp,"        mov    word ptr %s,ax\n",
                LABEL_HIRETVAL);
        break;
    default:
        break;
    }
}

 symbol *do_function_call(symtab *ptab)
{
    int i,n;
    symbol *p;
    symtab *caller;
    symtab *callee;

    caller = top_symtab_stack();
    callee = ptab;
    if(callee->obj_type != DEF_FUNCT)
    {
        parse_error("Undeclared function", callee->name);
        return NULL;
    }
    else if (callee->level == caller->level + 1)
    {
        fprintf(asmfp,"        push    bp\n");
    }
    else if (callee->level == caller->level)
    {
        fprintf(asmfp,"        push    %s\n",LABEL_SLINK);
    }
    else if (callee->level < caller->level)
    {
        fprintf(asmfp,"        mov    bx,bp\n");
        n = caller->level - callee->level + 1;
        for(i =0; i<n; i++)
            fprintf(asmfp, "        mov    bp,%s\n",
                    LABEL_SLINK);

        fprintf(asmfp,"        push    bp\n");
        fprintf(asmfp,"        mov    bp,bx\n");
    }
    else
        return NULL;
    fprintf(asmfp,"        call rtn%03d\n", callee->id);
    for(p = ptab->locals; p->next; p = p->next)
        ;
    return p;
}

 void do_procedure_call(symtab *ptab)
{
    symtab *caller = top_symtab_stack();
    symtab *callee = ptab;
    int n ;
    int i ;

    if(!caller || !callee)
    {
        parse_error("Undeclared procedure","");
        return;
    }
    n = (callee->level) -(caller->level) + 1;
    if(callee->level==caller->level+1)
    {
        fprintf(asmfp,"        push    bp\n");
    }
    else if (callee->level == caller->level)
    {
        fprintf(asmfp, "        push    %s\n",
                LABEL_SLINK);
    }
    else if(callee->level < caller->level)
    {
        fprintf(asmfp,"        mov    bx,bp\n");
        for(i = 0; i < n; i++)
            fprintf(asmfp,"        mov    bp,%s\n",
                    LABEL_SLINK);
        fprintf(asmfp,"        push    bp\n");
        fprintf(asmfp,"        mov    bp,bx\n");
    }
    else
        return;
    fprintf(asmfp,"        call    %s\n", ptab->label);
}

 void reset_args(symtab *ptab)
{
    rtn = ptab;
}

 void do_first_arg(int ptype)
{
    rtn = top_call_stack();
    if(rtn)
        arg = rtn->args;
    else
        return;
    if(!arg)
        return;
    switch(arg->type->type_id)
    {
    case  TYPE_REAL:
        if (ptype!=TYPE_REAL)
            fprintf(asmfp,"        xor    dx,dx\n");
        fprintf(asmfp,"        push    dx\n");
        fprintf(asmfp,"        push    ax\n");
        break;
    case  TYPE_CHAR:
        fprintf(asmfp,"        xor    ah,ah\n");
    case  TYPE_INTEGER:
    case  TYPE_BOOLEAN:
    default:
        fprintf(asmfp,"        push    ax\n");
        break;
    }
}

 void do_args(int ptype)
{
    arg = top_call_symbol();

    if(arg->next)
        arg = arg->next;
    else
        return;
    set_call_stack_top(arg);
    switch(arg->type->type_id)
    {
    case  TYPE_REAL:
        if (ptype!=TYPE_REAL)
            fprintf(asmfp,"        xor    dx,dx\n");
        fprintf(asmfp,"        push    dx\n");
        fprintf(asmfp,"        push    ax\n");
        break;
    case TYPE_CHAR:
        fprintf(asmfp,"        xor    ah.ah\n");
    case  TYPE_INTEGER:
    case  TYPE_BOOLEAN:
    default:
        fprintf(asmfp,"        push    ax\n");
        break;
    }
}

 void do_assign(symbol *p, int srctype)
{
    symtab *ptab;
    int  n,i;
    if (!p)
        return;

	if ((p->type->type_id != TYPE_ARRAY) 
			&& (p->type->type_id != TYPE_RECORD)
			&& (p->type->type_id != srctype))
    {
        parse_error("operand type do not match operator.","");
		printf("do_assign\n");
        return;
    }

    switch(p->obj_type)
    {
    case DEF_VARPARA:
        fprintf(asmfp,"        push    ax\n");
        fprintf(asmfp,"        mov    ax,word ptr %s\n",
                p->label);
        break;
    case DEF_FIELD:
        fprintf(asmfp,"        pop    bx\n");
        if(p->type->type_id==TYPE_INTEGER
                ||p->type->type_id==TYPE_BOOLEAN)
            fprintf(asmfp,"        mov    word ptr [bx],ax\n");
        else if (p->type->type_id==TYPE_BOOLEAN)
            fprintf(asmfp,"        mov    byte ptr [bx],ax\n");
        return;
    case DEF_VAR:
    case DEF_CONST:
    case DEF_ELEMENT:
        if(p->type->type_id==TYPE_ARRAY)
        {
            fprintf(asmfp,"        push    ax\n");
            break;
        }
        if(p->tab->level == 0
                ||p->type->type_id==TYPE_REAL)
            break;
        else if( p->tab->level
                 && p->tab == top_symtab_stack())
        {
            fprintf(asmfp,"        push    ax\n");
            fprintf(asmfp,"        lea    ax,word ptr %s\n",
                    p->label);
            fprintf(asmfp,"        push    ax\n");
            break;
        }
        else
        {
            ptab = top_symtab_stack();
            n = ptab->level - p->tab->level;
            fprintf(asmfp,"        push    ax\n");
            fprintf(asmfp,"        mov    bx,bp\n");
            for(i =0;i<n;i++)
                fprintf(asmfp,"        mov    bp,%s\n",
                        LABEL_SLINK);
            fprintf(asmfp,"        lea    ax,word ptr %s\n",
                    p->label);
            fprintf(asmfp,"        mov    bp,bx\n");
            fprintf(asmfp,"        push    ax\n");
        }
        break;
    case DEF_VALPARA:
        if(p->tab->level==0
                || p->tab==top_symtab_stack())
            fprintf(asmfp,"        push    ax\n");
        fprintf(asmfp,"        lea    ax,word ptr %s\n",
                p->label);
        fprintf(asmfp,"        push    ax\n");
        break;
    default:
        parse_error("lvalue expected.","");
        break;
    }

    switch(p->type->type_id)
    {
    case TYPE_CHAR:
        if(p->tab->level)
        {
            fprintf(asmfp,"        pop    bx\n");
            fprintf(asmfp,"        pop    ax\n");
            fprintf(asmfp,"    mov    byte ptr [bx],al\n");
        }
        else
            fprintf(asmfp,"        mov    byte ptr %s,al\n",
                    p->label);

        break;
    case TYPE_INTEGER:
    case TYPE_BOOLEAN:
        if (p->tab->level)
        {
            fprintf(asmfp, "        pop    bx\n");
            fprintf(asmfp, "        pop    ax\n");
            fprintf(asmfp, "        mov    word  ptr [bx],ax\n");
        }
        else
            fprintf(asmfp, "        mov    word  ptr %s, ax\n",p->label);
        break;

    case TYPE_STRING:
        fprintf(asmfp, "        mov    ex, %04xh\n",
                strlen(p->v.s));
        fprintf(asmfp, "        pop    pop    si\n");
        fprintf(asmfp, "        pop    di\n");
        fprintf(asmfp, "        mov    ax,ds");
        fprintf(asmfp, "        mov    es,ax");
        fprintf(asmfp, "        cld\n");
        fprintf(asmfp, "        rep    movsb\n");
        break;
    case TYPE_REAL:
        fprintf(asmfp, "        mov    ax,%s\n",p->label);
        fprintf(asmfp, "        mov    dx,%s+2n",p->label);
        break;
    case TYPE_ARRAY:
        if (p->type_link->end->type->type_id == TYPE_INTEGER
                ||p->type_link->end->type->type_id == TYPE_BOOLEAN )
        {
            fprintf(asmfp, "        pop    ax\n");
            fprintf(asmfp, "        pop    bx\n");
            fprintf(asmfp, "        mov    word ptr [bx],ax\n");
        }
        else if (p->type_link->end->type->type_id ==
                 TYPE_CHAR)
        {
            fprintf(asmfp, "        pop    ax\n");
            fprintf(asmfp, "        pop    bx\n");
            fprintf(asmfp, "        mov    byte ptr [bx],al\n");
        }
        break;
    default:
        break;
    }
}

 void do_cond_jump(int true_or_false, symbol* label)
{
    fprintf(asmfp, "        cmp    ax,1\n");

    if (true_or_false)
        fprintf(asmfp, "        jge    %s\n", label->name);
    else
        fprintf(asmfp, "        jl    %s\n", label->name);
}

 void do_jump(symbol* label)
{
    fprintf(asmfp, "        jmp %s\n", label->name);
}

 void do_label(symbol* label)
{
    fprintf(asmfp, "%s:\n", label->name);
}

 void do_incr(symbol* sym)
{
    switch (sym->type->type_id)
    {
    case TYPE_BOOLEAN:
    case TYPE_INTEGER:
        fprintf(asmfp, "inc word ptr %s\n", sym->label);
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "inc byte ptr %s\n", sym->label);
        break;
    default:
        parse_error("incr instruction only support char, boolean and int.", "");
        break;
    }
}

 void do_decr(symbol* sym)
{
    switch (sym->type->type_id)
    {
    case TYPE_BOOLEAN:
    case TYPE_INTEGER:
        fprintf(asmfp, "dec word ptr %s\n", sym->label);
        break;
    case TYPE_CHAR:
        fprintf(asmfp, "dec byte ptr %s\n", sym->label);
        break;
    default:
        parse_error("incr instruction only support char, boolean and int.", "");
        break;
    }
}

 void do_if_test()
{
    push_stmt_stack(new_index(stmt));
    fprintf(asmfp, "        cmp    ax,1\n");
    fprintf(asmfp, "        je    if_t%04xh\n",top_stmt_stack( ));
    fprintf(asmfp, "        jmp    if_f%04xh\n",
            top_stmt_stack());
    fprintf(asmfp, "if_t%04xh:\n",top_stmt_stack());
}

 void do_if_clause( )
{
    fprintf(asmfp, "        jmp    if_x%04xh\n",
            top_stmt_stack( ));
    fprintf(asmfp, "if_f%04xh:\n",top_stmt_stack( ));
}

 void do_if_exit()
{
    fprintf(asmfp, "if_x%04xh:\n", pop_stmt_stack());
}

 void do_repeat_start( )
{
    push_stmt_stack(new_index(stmt));
    fprintf(asmfp, "rep_%04xh:\n",top_stmt_stack( ));
}

 void do_repeat_exit( )
{
    fprintf(asmfp, "        cmp    ax,1\n");
    fprintf(asmfp, "        je    rep_x%04xh\n",
            top_stmt_stack());
    fprintf(asmfp, "        jmp    rep_%04xh\n",
            top_stmt_stack());
    fprintf(asmfp, "        rep_x%04xh:\n",
            pop_stmt_stack( ));
}

 void do_while_start( )
{
    push_stmt_stack (new_index(stmt));
    fprintf(asmfp, "wl_tst%04xh:\n",top_stmt_stack());
}

 void do_while_expr( )
{
    fprintf(asmfp, "        cmp    ax,1\n");
    fprintf(asmfp, "        je    wl%04xh\n",
            top_stmt_stack());
    fprintf(asmfp, "        jmp    wl_x%04xh\n",
            top_stmt_stack());
    fprintf(asmfp, "wl%04xh:\n",top_stmt_stack());
}

 void do_while_exit( )
{
    fprintf(asmfp, "        jmp    wl_tst%04xh\n",
            top_stmt_stack());
    fprintf(asmfp, "wl_x%04xh:\n",
            pop_stmt_stack());
}

void push_call_stack(symtab *p)
{
    call_stk[call_tos] = p;
    call_sym[call_tos] = p->args;
    rtn = p;
    call_tos--;
}

symtab *pop_call_stack()
{
    call_tos++;
    rtn = call_stk[call_tos];
    arg = call_sym[call_tos];
    return call_stk[call_tos];
}

symtab *top_call_stack( )
{
    return call_stk[call_tos + 1];
}

void set_call_stack_top(symbol *p)
{
    call_sym[call_tos + 1] = p;
}

symbol *top_call_symbol( )
{
    return call_sym[call_tos + 1];
}

 void do_for_start(symbol *p)
{
    sym_stk[sym_tos] = p;
    sym_tos--;
    switch(p->type->type_id)
    {
    case TYPE_CHAR:
        fprintf(asmfp, "        mov    byte ptr %s,al\n",
                p->label);
        break;
    case TYPE_INTEGER:
    case TYPE_BOOLEAN:
    default:
        fprintf(asmfp, "        mov    word ptr %s,ax\n",
                p->label);
        break;
    }

    push_stmt_stack(new_index(stmt));
    fprintf(asmfp, "for_tst%04xh:\n",top_stmt_stack());
}

 void do_for_test(int dir)
{
    symbol *p = sym_stk[sym_tos+1];
    direc_stk[dir_tos] = dir;


    dir_tos--;
    switch(p->type->type_id)
    {
    case TYPE_CHAR:
        fprintf(asmfp, "        cmp    byte ptr %s,al\n",
                p->label);
        break;
    case TYPE_INTEGER:
    case TYPE_BOOLEAN:
    default:
        fprintf(asmfp, "        cmp    word ptr %s,ax\n",
                p->label);
        break;
    }
    if (dir == kDOWNTO)
        fprintf(asmfp, "        jge    for%04xh\n",
                top_stmt_stack());
    else
        fprintf(asmfp, "        jle    for%04xh\n",
                top_stmt_stack());
    fprintf(asmfp, "        jmp    for_x%04xh\n",
            top_stmt_stack());
    fprintf(asmfp, "for%04xh:\n",top_stmt_stack());
}

 void do_for_exit()
{

    symbol *p = sym_stk[sym_tos + 1];

    switch(p->type->type_id)
    {
    case TYPE_CHAR:
        if (direc_stk[dir_tos + 1] == kTO)
            fprintf(asmfp, "        inc    byte ptr %s\n",
                    p->label);

        else
            fprintf (asmfp,"        dec    byte ptr %s\n",
                     p->label);
        break;
    case TYPE_INTEGER:
    case TYPE_BOOLEAN:
    default:
        if ((direc_stk[dir_tos + 1] == kTO))
            fprintf(asmfp, "        inc    word ptr %s\n",
                    p->label);
        else
            fprintf (asmfp, "        dec    word ptr %s\n",
                     p->label);
        break;
    }

    fprintf (asmfp, "        jmp    for_tst%04xh\n",
             top_stmt_stack());
    fprintf(asmfp, "for_x%04xh:\n", pop_stmt_stack());

    switch(p->type->type_id)
    {
    case TYPE_CHAR:
        if (direc_stk[dir_tos+1] == kTO)
            fprintf(asmfp, "        dec    byte ptr %s\n",
                    p->label);
        else
            fprintf(asmfp, "        inc    byte ptr %s\n",
                    p->label);
        break;
    case TYPE_INTEGER:
    case TYPE_BOOLEAN:
    default:
        if (direc_stk[dir_tos+1] == kTO)
            fprintf(asmfp, "        dec    word ptr %s\n",
                    p->label);
        else
            fprintf(asmfp, "        inc    word ptr %s\n",
                    p->label);
        break;
    }
    sym_tos++;
    dir_tos++;
}

#define    MAX_CASE_LEVEL    8
 int case_list_stk[MAX_CASE_LEVEL];
 int case_list_tos = MAX_CASE_LEVEL-1;
#define  MAX_CASE_ENTRY   32
 symbol *case_con_queue[MAX_CASE_ENTRY];
 int last_con = 0;
 int case_act_index = 1;

 void push_case_stack(int new_list)
{
    case_list_stk[case_list_tos--] = new_list;
}

 int pop_case_stack()
{
    return case_list_stk[++case_list_tos];
}
 int top_case_stack()
{
    if (case_list_tos==MAX_CASE_LEVEL-1)
        return -1;
    return case_list_stk[case_list_tos+1];
}

 void enter_case_queue(symbol *p)
{
    int i;
    if (last_con == 0)
    {
        for(i = 0; i<MAX_CASE_ENTRY; i++)
            case_con_queue[i] = NULL;
    }
    case_con_queue[last_con] = p;
    last_con++;
}

 void do_case_start( )
{
    push_stmt_stack(new_index(stmt));
    fprintf(asmfp, "        push    cx\n");
    fprintf(asmfp, "        mov    cx,ax\n");
    fprintf(asmfp, "        jmp    cs%d_tst\n", top_stmt_stack());
    push_case_stack(last_con);
}

 void do_case_test()
{
    symbol *p;
    int i;
    fprintf (asmfp, "cs%d_tst:\n",top_stmt_stack( ));
    i = top_case_stack();
    for(;i<last_con;i++)
    {
        p = case_con_queue[i];
        switch(p->type->type_id)
        {
        case TYPE_BOOLEAN:
        case TYPE_INTEGER:
            if (p->obj_type==DEF_ELEMENT)
                fprintf(asmfp, "        mov    ax,%s\n",
                        p->label);
            else
                if (p->v.i>=0)
                    fprintf(asmfp, "        mov    ax,0%xh\n",p->v.i);
                else
                    fprintf(asmfp, "        mov    ax,-0%xh\n",-p->v.i);
            break;
        case TYPE_CHAR:
            fprintf(asmfp, "        mov    al,%c,\n",p->v.c);
            break;
        case TYPE_REAL:
            fprintf(asmfp, "        mov    ax,word ptr %s\n",p->label);
            fprintf(asmfp, "        mov    dx,word ptr %s+2\n",p->label);
            break;
        case TYPE_STRING:
            fprintf(asmfp, "        lea    ax,%s\n",p->label);
            break;
        default:
            break;
        }

        if (p->type->type_id == TYPE_INTEGER
                || p->type->type_id == TYPE_BOOLEAN)
            fprintf(asmfp, "        cmp    cx,ax\n");
        else if (p->type->type_id == TYPE_CHAR)
            fprintf(asmfp, "        cmp    cl,al\n");
        fprintf(asmfp, "        jne    cs%dn_0%xh\n",
                top_stmt_stack(),i-top_case_stack()+1);
        fprintf(asmfp, "        jmp    cs%da_%04xh\n",
                top_stmt_stack(),i-top_case_stack()+1);
        fprintf(asmfp, "cs%dn_0%xh:\n",top_stmt_stack()
                ,i-top_case_stack()+1);
        case_con_queue[i] = NULL;
    }
    fprintf(asmfp, "cs%d_x:\n",pop_stmt_stack());
    fprintf(asmfp, "        pop    cx\n");
    last_con = pop_case_stack( );
}

 void add_case_const(symbol *p)
{
    case_act_index = last_con - top_case_stack() + 1;
    enter_case_queue(p);
    fprintf(asmfp, "cs%da_%04xh:\n",top_stmt_stack(),
            case_act_index);
}

 void do_case_jump()
{
    fprintf(asmfp,"        jmp    cs%d_x\n",top_stmt_stack());
}

 int jump_index = 0;

 void do_expression(symbol *p, int op)
{
    if (p->type->type_id == TYPE_INTEGER
            || p->type->type_id == TYPE_BOOLEAN)
    {
        fprintf(asmfp, "        pop    dx\n");
        fprintf(asmfp, "        cmp    dx,ax\n");
    }
    else if(p->type->type_id == TYPE_CHAR)
    {
        fprintf(asmfp, "        pop    dx\n");
        fprintf(asmfp, "        cmp    dl,al\n");
    }
    else if (p->type->type_id == TYPE_STRING)
    {
        fprintf(asmfp,"        pop    di\n");
        fprintf(asmfp, "        pop    si\n");
        fprintf(asmfp, "        mov    ax,ds\n");
        fprintf(asmfp, "        mov    es,ax\n");
        fprintf(asmfp, "        cld\n");
        fprintf(asmfp, "        mov    cx,0%xh\n",strlen(p->v.s));
        fprintf(asmfp, "        repe        cmpsb\n");
    }
    else
    {
        parse_error("standard type expected.", "");
        return;
    }

    fprintf(asmfp, "        mov    ax,1\n");

    switch(op)
    {
    case oGE:
        fprintf(asmfp, "        jge    j_%03d\n",
                new_index(jump));
        break;
    case oLE:
        fprintf(asmfp, "        jle    j_%03d\n",
                new_index(jump));
        break;
    case oGT:
        fprintf(asmfp, "        jg    j_%03d\n",
                new_index(jump));
        break;
    case oLT:
        fprintf(asmfp, "        jl    j_%03d\n",
                new_index(jump));
        break;
    case oEQUAL:
        fprintf(asmfp, "        je    j_%03d\n",
                new_index(jump));
        break;
    case oUNEQU:
        fprintf(asmfp, "        jne    j_%03d\n",
                new_index(jump));
        break;
    }

    fprintf(asmfp, "        sub    ax,ax\n");
    fprintf(asmfp, "j_%03d:\n", jump_index);
}

 void do_negate(symbol *p)
{
    if (!p)
        return;
    if (p->obj_type != DEF_VAR
            && p->obj_type != DEF_VALPARA
            && p->obj_type != DEF_VARPARA
            && p->obj_type != DEF_CONST)
    {
        parse_error("variable required.", "");
        return;
    }
    switch(p->type->type_id)
    {
    case TYPE_INTEGER:
        fprintf(asmfp, "        neg    ax\n");
        break;
    default:
        parse_error("operand type do not match operator.", "");
		printf("do_negate\n");
        break;
    }
}

 void do_expr(symbol *p, int op)
{
    if (!p)
        return;
    switch(op)
    {
    case oPLUS:
        if (p->type->type_id == TYPE_REAL)
        {}
        else if (p->type->type_id == TYPE_INTEGER)
        {
            fprintf(asmfp,"        pop    dx\n");
            fprintf(asmfp, "        add    ax,dx\n");
        }
        else
            parse_error("integer or real type expected.","");
        break;
    case oMINUS:
        if (p->type->type_id == TYPE_REAL)
        {}
        else if (p->type->type_id==TYPE_INTEGER)
        {
            fprintf(asmfp, "        pop    dx\n");
            fprintf(asmfp, "        sub    dx,ax\n");
            fprintf(asmfp, "        mov    ax,dx\n");
        }
        else
            parse_error("integer or real type expected.", "");
		break;
    case kOR:
        if (p->type->type_id == TYPE_BOOLEAN)
        {
            fprintf(asmfp, "        pop    dx\n");
            fprintf(asmfp, "        or    ax,dx\n");
        }
        else
            parse_error("boolean type expected.", "");
        break;
    default:
        break;
    }
}

 void do_term(symbol *p, int op)
{
    if (!p)
        return;


    switch(op)
    {
    case oMUL:
        if (p->type->type_id == TYPE_INTEGER)
        {
            fprintf(asmfp, "        pop    dx\n");
            fprintf(asmfp, "        imul    dx\n");
        }
        else if (p->type->type_id == TYPE_REAL)
        {}
        else
            parse_error("integer or real type expected.", "");
        break;
    case kDIV:
    case oDIV:
        if (p->type->type_id == TYPE_INTEGER)
        {
            fprintf(asmfp,"        mov    cx,ax\n");
            fprintf(asmfp, "        pop    ax\n");
            fprintf(asmfp, "        sub    dx,dx\n");
            fprintf(asmfp, "        idiv    cx\n");
        }
        else
            parse_error("integer type expected.", "");
        break;
    case kMOD:
        if (p->type->type_id == TYPE_INTEGER)
        {
            fprintf(asmfp, "        mov    cx,ax\n");
            fprintf(asmfp, "        pop    ax\n");
            fprintf(asmfp, "        sub    dx,dx\n");
            fprintf(asmfp, "        idiv    cx\n");
            fprintf(asmfp, "        mov    ax,dx\n");
        }
        else
            parse_error("integer type expected.","");
        break;
    case kAND:
        if (p->type->type_id != TYPE_BOOLEAN)
            parse_error("boolean type expected.","");
        else
        {
            fprintf(asmfp, "        pop    dx\n");
            fprintf(asmfp, "        and    ax,dx\n");
        }
        break;
    default:
        break;
    }
}

 void do_factor(symbol *p)
{
    symtab *ptab;
    int i;
    int n;

    if (!p)
        return;

    if (p->type->type_id == TYPE_ARRAY)
    {
        parse_error("array element expected","");
        return;
    }
    if (p->obj_type == DEF_CONST || p->obj_type == DEF_ELEMENT)
    {
        switch(p->type->type_id)
        {
        case TYPE_BOOLEAN:
            fprintf(asmfp, "        mov    ax,%d\n",p->v.b);
            break;
        case TYPE_INTEGER:
            if (p->obj_type == DEF_ELEMENT)
                fprintf(asmfp, "        mov    ax,%s\n",
                        p->label);
            else
                fprintf(asmfp, "        mov    ax,0%0xh\n",
                        p->v.i);
            break;
        case TYPE_CHAR:
            fprintf(asmfp, "        mov    al,'%c'\n",p->v.c);
            break;
        case TYPE_REAL:
            fprintf(asmfp, "        mov    ax,word ptr %s\n",p->label);
            fprintf(asmfp, "        mov    dx,word ptr %s+2\n",p->label);
            break;
        case TYPE_STRING:
            fprintf(asmfp, "        lea    ax,%s\n",p->label);
            break;
        default:
            break;
        }
    }
    else if (p->obj_type == DEF_VARPARA)
    {
        fprintf(asmfp, "        mov    bx,word ptr %s\n",
                p->label);
        fprintf(asmfp, "        mov    ax,word ptr [bx]\n");
    }
    else if (p->obj_type == DEF_VAR
             ||p->obj_type == DEF_VALPARA)

    {
        if (p->tab == top_symtab_stack()
                || p->tab->level == 0)
        {
            switch(p->type->type_id)
            {
            case TYPE_CHAR:
                fprintf(asmfp, "        sub    ax,ax\n");
                fprintf(asmfp, "        mov    al,byte ptr %s\n",p->label);
				break;
            case TYPE_INTEGER:
			case TYPE_BOOLEAN:
                fprintf(asmfp, "        mov    ax,word ptr %s\n",p->label);
                break;
            case TYPE_REAL:
                fprintf(asmfp, "        mov    ax,word ptr %s\n",p->label);
                fprintf(asmfp, "        mov    dx,word ptr %s+2n",p->label);
                break;
            }
        }
        if (p->obj_type == DEF_VAR)
        {
            ptab = top_symtab_stack();
            n = ptab->level - p->tab->level;
            if (n <= 0)
                return;
            fprintf(asmfp, "        mov    bx,bp\n");
            for(i = 0; i<n; i++)
                fprintf(asmfp, "        mov    bp,%s\n",
                        LABEL_SLINK);
            switch(p->type->type_id)
            {
            case TYPE_INTEGER:
            case TYPE_BOOLEAN:
                fprintf(asmfp, "        mov    ax,word ptr %s\n",p->label);
                break;
            case TYPE_CHAR:
                fprintf(asmfp, "        mov    al,byte ptr %s\n",p->label);
                break;
            default:
                break;
            }
            fprintf(asmfp,"        mov    bp,bx\n");
        }
    }
}

 void do_not_factor(symbol *p)
{
    if (!p)
        return;
    if (p->type->type_id!= TYPE_BOOLEAN)
        parse_error("Boolean type expected. ","");
    do_factor(p);

    fprintf(asmfp, "        and    ax, 1\n");
    fprintf(asmfp, "        xor    ax, 1\n");
}

 void do_array_factor(symbol *p)
{
    if (p->type_link->begin->v.i >= 0)
        fprintf(asmfp, "        sub    ax,0%xh\n",
                p->type_link->begin->v.i);
    else
        fprintf(asmfp, "        sub    ax,-0%xh\n",
                -(p->type_link->begin->v.i));
    fprintf(asmfp, "        mov    cx,0%xh\n",
            get_symbol_size(p->type_link->end));
    fprintf(asmfp, "        imul    cx\n");
    fprintf(asmfp, "        pop    dx\n");
    if (p->tab->level)
        fprintf(asmfp, "        sub    dx,ax\n");
    else
        fprintf(asmfp, "        add    dx,ax\n");

    fprintf(asmfp, "        push    dx\n");
}

 void do_record_factor(symbol *var, symbol *p)
{
    if (!var || !p || p->obj_type != DEF_FIELD)
        return;
    fprintf(asmfp, "        pop    ax\n");
    fprintf(asmfp, "        mov    dx,0%xh\n",p->offset);
    if (var->tab->level)
        fprintf(asmfp, "        sub    ax,dx\n");
    else
        fprintf(asmfp, "        add    ax,dx\n");
    fprintf(asmfp, "        push    ax\n");
}

 void new_line(){
	 

	 fprintf(asmfp, "        push     dx\n");
	 fprintf(asmfp, "        mov      dl, 0dh\n");
	 fprintf(asmfp, "        int 	  21h\n");
	 fprintf(asmfp, "        mov	  dl, 0ah\n");
	 fprintf(asmfp, "        int	  21h\n");
	 fprintf(asmfp, "        pop      dx\n");
		
 }
