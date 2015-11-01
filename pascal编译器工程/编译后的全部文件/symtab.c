#include  <stdio.h>
#include  <stdlib.h>
#include  <string.h>
#include  <ctype.h>
#include  "macro.h"
#include  "symtab.h"
#include "yyout.h"

symtab *Global_symtab; //全局符号
symtab *System_symtab[MAX_SYS_FUNCTION]; //系统函数及变量符号表
symtab *symtab_stack[64]; //符号表栈，用于处理子函数或过程
symtab *symtab_queue[128]; //符号表队列，用于检索
int symtab_tos = 63;  //栈顶
extern int Keytable_size; //关键字表大小
static int type_index = 0; //用于唯一标记用户自定义类型，以下类似
int const_index;
int var_index;
int arg_index;
int function_id;
int last_symtab = 0;
int set_align(int);
//以下为对类型，符号，符号表的操作
int stoi(char *s, int radix)
{
	char *ps = s;
	int val = 0;

	if (radix == 8)
	{
		ps++;
		while (*ps)
		{
			val = val * radix + (*ps - '0');
			ps++;
		}
	}
	else if (radix == 16)
	{
		ps++;
		ps++;

		while (*ps)
		{
			if (isdigit(*ps))
			{
				val = val * radix + (*ps - '0');
			}
			else
			{
				val = val * radix + (tolower(*ps) - 'a');
			}
			ps++;
		}
	}
	else
	{
		while (*ps)
		{
			val = val * radix + (*ps - '0');
			ps++;
		}
	}
	return val;
}

type *create_system_type(int base_type)
{
	type *pt;

	pt = allocate(sizeof *(pt));

	pt->type_id = base_type;
	pt->next = NULL;
	pt->begin = pt->end = NULL;

	switch (base_type)
	{
	case TYPE_INTEGER:
		strcpy(pt->name, "integer");
		break;
	case TYPE_CHAR:
		strcpy(pt->name, "char");
		break;
	case TYPE_BOOLEAN:
		strcpy(pt->name, "boolean");
		break;
	case TYPE_REAL:
		strcpy(pt->name, "real");
		break;
	case TYPE_VOID:
		strcpy(pt->name, "void");
		break;
	case TYPE_UNKNOWN:
		strcpy(pt->name, "****");
		break;
	default:
		break;
	}
	return pt;
}

type *new_subrange_type(char *name, int element_type)
{
	type *pt;
	if (element_type != TYPE_INTEGER
		&&element_type != TYPE_CHAR)
		return NULL;

	pt = allocate(sizeof *(pt));

	if (name[0] == '$')
		sprintf(pt->name, "$$$%d", ++type_index);
	else
		strncpy(pt->name, name, NAME_LEN);
	pt->next = NULL;

	pt->begin = new_symbol("$$$", DEF_ELEMENT,
		element_type);

	pt->end = new_symbol("$$$", DEF_ELEMENT,
		element_type);

	pt->begin->next = pt->end;
	pt->type_id = TYPE_SUBRANGE;
	return pt;
}

symbol *copy_symbol_list(symbol *head)
{
    symbol *new_list;
    symbol *ps;
    symbol *qs;
    if(!head)
        return NULL;
    qs = head;
    new_list = ps = copy_symbol(qs);
    qs = ps->next;
    while(qs)
    {
        ps->next = copy_symbol(qs);
        ps = ps->next;
        qs = qs->next;
    }
    ps->next = NULL;
    return new_list;
}

symbol *reverse_parameters(symtab *ptable)
{
    symbol *ps,*qs;
    symbol *new_list = NULL;
    for(ps = ptable->args;ps;)
    {
        qs = ps;
        ps = ps->next;
        qs->next = new_list;
        new_list = qs;
    }
    ptable->args = new_list;
    return ptable->args;
}

int is_symbol(symbol*ps,char*name)
{
    if(strcmp(ps->name,name))
        return  0;
    return 1;
}

int get_symbol_size(symbol*sym)
{
    switch(sym->type->type_id)
    {
    case TYPE_INTEGER:
        return  2;
    case TYPE_CHAR   :
        return  1;
    case TYPE_BOOLEAN:
        return  2;
    case TYPE_REAL   :
        return  4;

    case TYPE_STRING :
        return size (CHAR)
               *(strlen(sym->v.s) + 1);
    case TYPE_ARRAY  :
        return  get_type_size(
                    sym->type_link);

    case TYPE_RECORD  :
        return get_type_size(
                   sym->type_link);
    case  TYPE_VOID   :
        return 0;
    default:
        break;
    }
    return 0;
}

symtab *pop_symtab_stack()
{
    return symtab_stack[++symtab_tos];
}
void push_symtab_stack (symtab *tab)
{
    symtab_stack[symtab_tos--] = tab;
}

symtab *top_symtab_stack()
{
    return symtab_stack[symtab_tos + 1];
}

symtab *find_routine(char *name)
{
    int i;
    symtab *ptable;
    for(i=0;i<last_symtab;i++)
    {
        ptable = symtab_queue[i];
        if(!strcmp(ptable->name,name))
            return ptable;
    }
    return NULL;
}

symtab *find_sys_routine(int routine_id)
{
    int i;
    for(i = 1; i < System_symtab[0]->local_size; i++)
        if(System_symtab[i]->id == -routine_id)
            return System_symtab[i];
    return NULL;
}

symbol *find_element(symtab *tab,char *name)
{
    symbol *ps;
    symtab *ptable = tab;
    type *pt;
    while(ptable)
    {
        for(pt = ptable->type_link; pt; pt = pt->next)
            for(ps = pt->begin; ps; ps = ps->next)
                if(is_symbol(ps,name))
                    return ps;
        ptable = ptable->parent;
    }
    return NULL;
}

symbol *find_field(symbol *ps,char *name)
{
    type *pt;
    symbol *qs;

    if(!ps || ps->type->type_id != TYPE_RECORD)
        return NULL;
    pt = ps->type_link;
    for(qs = pt->begin; qs; qs = qs->next)
        if(is_symbol(qs, name))
            return qs;

    return NULL;
}

symbol *find_symbol(symtab *tab,char *name)
{
    symbol *ps;
    symtab *ptable = tab;
    type *pt;

    if(!ptable)
    {
        ps = System_symtab[0]->locals;
        ps->type = TYPE_UNKNOWN;
        return ps;
    }
    while(ptable)
    {
        ps = find_local_symbol(ptable,name);
        if(ps)
            return ps;
        for(pt = ptable->type_link; pt; pt=pt->next)
            for(ps = pt->begin; ps; ps = ps->next)
                if(is_symbol(ps,name))
                    return ps;
        ptable = ptable->parent;
    }
    return NULL;
}
symbol *find_local_symbol(symtab *tab, char *name)
{
    symbol *ps;
    symtab *ptable = tab;
    int i;
    if(!ptable)
        return NULL;
    if(!ptable->lt)
        return NULL;
    ps = ptable->lt;
    while(ps)
    {
        i = strcmp(name, ps->name);
        if(i > 0)
            ps = ps->rchild;
        else if(i < 0)
            ps = ps->lchild;
        else
            return ps;
    }
    return NULL;
}

void set_subrange_bound(type *pt, int lower, int upper)
{
	if (!pt || !pt->begin || !pt->end)
		return;

	if (lower > upper)
	{
		parse_error("Lower bound larger than upper bound", pt->name);
		return;
	}
	pt->begin->v.i = lower;
	pt->end->v.i = upper;
	if (pt->begin->type->type_id == TYPE_CHAR)
	{
		sprintf(pt->begin->label, "%c", lower);
		sprintf(pt->end->label, "%c", upper);
	}
	else
	{
		sprintf(pt->begin->label, "0%xh", lower);
		sprintf(pt->end->label, "0%xh", upper);
	}
	pt->members = upper - lower + 1;
}

type *new_enum_type(char *name)
{
	type *pt;


	pt = allocate(sizeof *(pt));

	if (name[0] == '$')
		sprintf(pt->name, "$$$%d", ++type_index);
	else
		strncpy(pt->name, name, NAME_LEN);

	pt->next = NULL;
	pt->type_id = TYPE_ENUM;
	return pt;
}


void add_enum_elements(type *pt, symbol *symlist)
{
	symbol *ps;
	int n = 0;

	if (!ps || !symlist)
		return;
	pt->begin = symlist;

	for (ps = pt->begin; ps->next; ps = ps->next)
	{
		ps->obj_type = DEF_ELEMENT;
		ps->type = find_type_by_id(TYPE_INTEGER);
		ps->v.i = ++n;
		sprintf(ps->label, "0%xh", ps->v.i);
	}

	ps->obj_type = DEF_ELEMENT;
	ps->type = find_type_by_id(TYPE_INTEGER);
	ps->v.i = ++n;
	sprintf(ps->label, "0%xh", ps->v.i);
	pt->end = ps;
	pt->members = n;
}

type *new_array_type(char *name, type *pindex,
	type *pelement)
{
	type *pt;

	if (!pindex || !pelement)
		return NULL;
	if (!pindex->begin
		|| !pindex->end
		|| pindex->begin == pindex->end)
	{
		parse_error("index bound expcted", name);
		return NULL;
	}

	pt = allocate(sizeof *(pt));

	strncpy(pt->name, name, NAME_LEN);
	pt->type_id = TYPE_ARRAY;
	pt->members = pindex->end->v.i -
		pindex->begin->v.i + 1;

	pt->begin = pindex->begin;
	pt->end = new_symbol("$$$", DEF_ELEMENT,
		pelement->type_id);
	sprintf(pt->end->label, "ary_ele");
	return pt;
}

type *new_record_type(char *name, symbol *fields)
{
	type *pt;
	symbol *ps;

	pt = allocate(sizeof *(pt));

	strncpy(pt->name, name, NAME_LEN);
	pt->type_id = TYPE_RECORD;
	pt->next = NULL;
	pt->begin = fields;
	pt->size = 0;
	pt->members = 0;

	for (ps = fields; ps; ps = ps->next)
	{
		ps->obj_type = DEF_FIELD;
		ps->offset = pt->size;
		pt->size += set_align(get_symbol_size(ps));
		pt->members++;
	}
	return pt;
}

void add_type_to_table(symtab *ptable, type *pt)
{
	type *qt;
	symbol *ps;

	if (!ptable || !pt)
		return;
	for (qt = ptable->type_link; qt; qt = qt->next)
	if (!strcmp(qt->name, pt->name))
	{
		parse_error("Duplicate type name", pt->name);
		return;
	}

	pt->next = ptable->type_link;
	ptable->type_link = pt;
	if (pt->type_id == TYPE_ENUM
		|| pt->type_id == TYPE_RECORD)
	for (ps = pt->begin; ps; ps = ps->next)
		add_var_to_localtab(ptable, ps);
}


type *find_local_type_by_name(char *name)
{
	type *pt;
	symtab *ptable;

	ptable = top_symtab_stack();
	if (!ptable)
		return NULL;

	for (pt = ptable->type_link; pt; pt = pt->next)
	if (!strcmp(name, pt->name))
		return pt;

	for (pt = System_symtab[0]->type_link; pt;
		pt = pt->next)
	if (!strcmp(name, pt->name))
		return pt;
	ptable = ptable->parent;
	while (ptable)
	{
		for (pt = ptable->type_link; pt; pt = pt->next)
		if (!strcmp(name, pt->name))
			return pt;
	}
	return NULL;
}

type *find_type_by_name(char *name)
{
	type *pt;
	symtab *ptable;

	ptable = top_symtab_stack();
	if (!ptable)
		return NULL;

	for (pt = ptable->type_link; pt; pt = pt->next)
	if (!strcmp(name, pt->name))
		return pt;

	for (pt = System_symtab[0]->type_link; pt; pt = pt->next)
	if (!strcmp(name, pt->name))
		return pt;

	ptable = ptable->parent;
	while (ptable)
	{
		for (pt = ptable->type_link; pt; pt = pt->next)
		if (!strcmp(name, pt->name))
			return pt;
		ptable = ptable->parent;
	}

	return NULL;
}

void add_symbol_to_table(symtab*tab, symbol *sym)
{
	switch (sym->obj_type)
	{
	case DEF_FUNCT:
	case DEF_PROC:
	case DEF_VAR:
	case DEF_CONST:
		add_local_to_table(tab, sym);
		break;
	case DEF_VARPARA:
	case DEF_VALPARA:
		add_arg_to_table(tab, sym);
		break;
	case DEF_PROG:
	default:
		break;
	}
}

void add_var_to_localtab(symtab *tab, symbol *sym)
{
	symbol *ps;
	int i;

	if (!tab || !sym)
		return;

	if (!tab->lt)
	{
		tab->lt = sym;
		return;
	}
	ps = tab->lt;
	while (1)
	{
		i = strcmp(sym->name, ps->name);
		if (i > 0)
		{
			if (ps->rchild)
				ps = ps->rchild;
			else
			{
				ps->rchild = sym;
				break;
			}
		}
		else if (i < 0)
		{
			if (ps->lchild)
				ps = ps->lchild;
			else
			{
				ps->lchild = sym;
				break;
			}
		}
		else
		{
			parse_error("Duplicate identifier.",sym->name);
			break;
		}
	}
}

void add_local_to_table(symtab *tab, symbol *sym)
{
	if (!tab || !sym)
		return;
	if (sym->obj_type == DEF_CONST)
		sprintf(sym->label, "c%c_%03d",
		sym->name[0], new_index(const));
	else
		sprintf(sym->label, "v%c_%03d",
		sym->name[0], new_index(var));
	if (tab->level)
	{
		if (tab->obj_type == DEF_FUNCT
			&& sym->obj_type != DEF_FUNCT)
		{
			sym->offset = tab->local_size + 3 * 2;
			tab->local_size += set_align(get_symbol_size(sym));
		}
		else if (tab->obj_type == DEF_PROC
			&& sym->obj_type != DEF_PROC)
		{
			sym->offset = tab->local_size + 2;
			tab->local_size += set_align(get_symbol_size(sym));
		}
	}

	sym->next = tab->locals;
	tab->locals = sym;
	sym->tab = tab;
	add_var_to_localtab(tab, sym);
}

void add_arg_to_table(symtab *tab, symbol *sym)
{
	symbol *ps;
	int var_size;
	if (!tab || !sym)
		return;
	sym->next = tab->args;
	tab->args = sym;
	sym->tab = tab;
	sym->offset = 3 * 2;
	sprintf(sym->label, "a%c_%03d",
		sym->name[0], new_index(arg));
	var_size = set_align(get_symbol_size(sym));
	tab->args_size += var_size;
	for (ps = tab->args->next; ps; ps = ps->next)
		ps->offset += var_size;
	add_var_to_localtab(tab, sym);
}

extern KEYENTRY Keytable[];

void make_system_symtab()
{
	int i, n;
	symtab *ptable;
	type *pt;

	for (i = 0; i < MAX_SYS_FUNCTION; i++)
		System_symtab[i] = NULL;


	ptable = allocate(sizeof *(ptable));
	System_symtab[0] = ptable;

	ptable = System_symtab[0];
	sprintf(ptable->name, "system_table");
	sprintf(ptable->label, "null");

	ptable->type_link =
		create_system_type(TYPE_INTEGER);
	pt = ptable->type_link;
	pt->next = create_system_type(TYPE_CHAR);
	pt = pt->next;
	pt->next = create_system_type(TYPE_BOOLEAN);
	pt = pt->next;
	pt->next = create_system_type(TYPE_REAL);
	pt = pt->next;
	pt->next = create_system_type(TYPE_VOID);
	pt = pt->next;
	pt->next = create_system_type(TYPE_STRING);
	pt = pt->next;
	pt->next = create_system_type(TYPE_UNKNOWN);
	pt = pt->next;

	push_symtab_stack(ptable);

	ptable->id = -1;
	ptable->level = -1;
	ptable->obj_type = DEF_UNKNOWN;
	ptable->type = TYPE_UNKNOWN;
	ptable->local_size = 0;
	ptable->args_size = 0;
	ptable->args = NULL;
	ptable->parent = NULL;
	ptable->locals = new_symbol("", DEF_UNKNOWN,
		TYPE_UNKNOWN);

	n = 1;

	for (i = 0; i < Keytable_size; i++)
	{
		if (Keytable[i].key == SYS_FUNCT ||
			Keytable[i].key == SYS_PROC)
		{
			System_symtab[n] =
				new_system_sym(Keytable[i]);
			n++;
		}
		else if (Keytable[i].key == LAST_ENTRY)
			break;
	}

	pop_symtab_stack();

	ptable->local_size = n;
}

symtab* new_system_sym(KEYENTRY entry)
{
	symtab *ptable;
	symbol *ps;

	ptable = allocate(sizeof *(ptable));
	strcpy(ptable->name, entry.name);

	sprintf(ptable->label, "_f_%s", entry.name);

	ptable->id = -entry.attr;
	ptable->level = -1;
	ptable->obj_type = DEF_FUNCT;
	ptable->type = find_type_by_id(entry.ret_type);
	ptable->local_size = 0;
	ptable->args_size = 0;
	ptable->args = NULL;
	ptable->lt = NULL;
	ptable->locals = NULL;
	ptable->parent = System_symtab[0];

	ps = allocate(sizeof *(ps));

	strcpy(ps->name, ptable->name);
	strcpy(ps->label, ptable->label);
	ps->obj_type = DEF_FUNCT;
	ps->type = find_type_by_id(entry.ret_type);
	ps->offset = 0;
	ps->next = NULL;
	ps->tab = ptable;
	ps->type_link = NULL;
	ptable->locals = ps;
	if (entry.arg_type)
	{
		ps = allocate(sizeof *(ps));

		strcpy(ps->name, "arg");
		ps->obj_type = DEF_VALPARA;
		ps->type = find_type_by_id(entry.arg_type);
		add_arg_to_table(ptable, ps);
	}
	return ptable;
}

type *find_type_by_id(int id)
{
	type *pt;
	symtab *ptable;

	ptable = top_symtab_stack();
	if (!ptable)
		return NULL;

	for (pt = ptable->type_link; pt; pt = pt->next)
	if (id == pt->type_id)
		return pt;

	for (pt = System_symtab[0]->type_link; pt; pt = pt->next)
	if (id == pt->type_id)
		return pt;

	ptable = ptable->parent;
	while (ptable)
	{
		for (pt = ptable->type_link; pt; pt = pt->next)
		if (id == pt->type_id)
			return pt;
	}

	return NULL;
}

type *clone_type(type *src)
{
	type *pt;
	symbol *ps;

	if (!src)
		return NULL;

	switch (src->type_id)
	{
	case TYPE_ENUM:
		pt = new_enum_type(src->name);
		pt->begin = copy_symbol_list(src->begin);
		for (ps = pt->begin; ps->next; ps = ps->next)
			;
		pt->end = ps;
		break;
	case TYPE_SUBRANGE:
		pt = new_subrange_type(src->name,
			src->begin->type->type_id);
		pt->begin = copy_symbol(src->begin);
		pt->end = copy_symbol(src->end);
		pt->begin->next = pt->end;
		break;
	case  TYPE_INTEGER:
	case  TYPE_CHAR:
	case  TYPE_BOOLEAN:
	case  TYPE_REAL:
		pt = create_system_type(src->type_id);
		break;
	default:
		pt = NULL;
		break;
	}
	return pt;
}

int get_type_size(type *pt)
{
	if (!pt)
		return 0;

	switch (pt->type_id)
	{
	case TYPE_ARRAY:
		return pt->members*
			get_symbol_size(pt->begin);
	case TYPE_RECORD:
		return pt->size;
	}
	return 0;
}

int set_align(int bytes)
{
	while (bytes % 2)
		bytes++;
	return bytes;
}

void enter_symtab_queue(symtab *tab)
{
	if (last_symtab < 128)
		symtab_queue[last_symtab++] = tab;
}

symtab *new_symtab(symtab *parent)
{
	symtab *ps;

	ps = allocate(sizeof *(ps));

	ps->parent = parent;
	ps->args_size = 0;
	ps->args = NULL;
	ps->lt = NULL;
	ps->locals = NULL;
	ps->type_link = NULL;
	if (parent)
	{
		ps->level = parent->level + 1;
	}
	else
	{
		function_id = 0;
		Global_symtab = ps;
		current_level = 0;
		ps->level = 0;
	}
	ps->obj_type = DEF_UNKNOWN;
	ps->type = find_type_by_id(TYPE_VOID);
	ps->id = function_id++;
	ps->local_size = 0;
	enter_symtab_queue(ps);
	return ps;
}

symbol *new_symbol(char *name, int obj_type, int typeid)
{
	symbol *ps;
	static int imp_index = 0;

	ps = allocate(sizeof *(ps));

	if (!strcmp(name, "$$$"))
		sprintf(ps->name, "z%d", ++imp_index);
	else
		strncpy(ps->name, name, NAME_LEN);
	ps->label[0] = '\0';
	ps->obj_type = obj_type;
	ps->type = find_type_by_id(typeid);
	ps->offset = 0;
	ps->next = NULL;
	ps->lchild = ps->rchild = NULL;
	ps->tab = NULL;
	ps->type_link = NULL;
	return ps;

}
symbol *copy_symbol(symbol *origin)
{
	symbol *ps;
	if (!origin)
		return NULL;
	ps = allocate(sizeof *(ps));
	strncpy(ps->name, origin->name, NAME_LEN);
	strncpy(ps->name, origin->label, LABEL_LEN);
	ps->obj_type = origin->obj_type;
	ps->type = origin->type;
	ps->offset = 0;
	ps->next = NULL;
	ps->tab = NULL;
	if (ps->type->type_id == TYPE_STRING)
		ps->v.s = strdup(origin->v.s);
	else
		ps->v.f = origin->v.f;
	return ps;
}