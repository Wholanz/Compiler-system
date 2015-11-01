#ifndef		_SYMTAB_H
#define 	_SYMTAB_H

typedef union val value;
typedef struct var_type type;
typedef struct sym symbol;
typedef struct symbol_table symtab;
//所有变量类型，包括自定义类型和内建类型
struct var_type
{
	char name[NAME_LEN];
	int size;
	int members; //自定义类型的成员
	int type_id; //唯一标识类型
	symbol *begin,*end;
	type *next;
};
//变量的值
union val {
	int i;
	float f;
	boolean b;
	long l;
    char c;
    char *s;
    unsigned long u;
    long double d;
};
//对自定义类型的操作
type *create_system_type(int);
type *new_subrange_type(char *, int);
type *new_enum_type(char *);
type *new_record_type(char *, symbol *);
type *clone_type(type *);
type *find_type_by_name(char *);
type *find_type_by_id(int);
type *find_local_type(char *);
type *new_array_type(char *name, type *pindex, type *pelement);
type *find_local_type_by_name(char *name);
//符号结构
struct sym
{
    char name[NAME_LEN];
    char label[LABEL_LEN]; //符号在汇编中的标签
	value v;  //符号的值
    int obj_type; //符号类型
    type* type;	  //符号变量类型
    int offset; //如果符号是参数或者本地变量，计算偏移，便于汇编
    symbol *next,*lchild,*rchild;
    symtab *tab; //符号所在符号表，便于寻找符号时递归向上级符号表查找
    type   *type_link;
};
//对符号的操作
symbol *find_symbol(symtab *, char *);
symbol *find_element(symtab *, char *);
symbol *find_local_symbol(symtab *, char *);
symbol *find_field(symbol *, char *);
symbol *new_symbol(char *, int, int);
symbol *copy_symbol(symbol *);
symbol *reverse_parameters(symtab *);
symbol *copy_symbol_list(symbol *);
//符号表结构
struct symbol_table
{
    char name[NAME_LEN];
    char label[LABEL_LEN]; //在汇编中的标签
	int obj_type; //符号表类型
	type* type;
    int id;
    int level; //符号表嵌套层次，在汇编中标识是否在main中
    symbol *args,*locals,*lt; //函数或过程参数或本地变量链表，便于汇编
	int local_size,args_size; //用于根据栈顶指针计算偏移获取变量
    type *type_link;
    symtab *parent;
};
//对符号表的操作
symtab *find_routine(char *);
symtab *new_system_sym(KEYENTRY);
symtab *find_sys_routine(int);
symtab *Global_symtab;
symtab *System_symtab[MAX_SYS_FUNCTION];
symtab *pop_symtab_stack();
symtab *top_symtab_stack();
symtab *new_symtab(symtab *);

int current_level;
//关于符号与符号表的操作
void push_symtab_stack(symtab *);
void add_symbol_to_table(symtab *, symbol *);
void add_local_to_table(symtab *, symbol *);
void add_arg_to_table(symtab *, symbol *);
void add_var_to_localtab(symtab *, symbol *);
void add_type_to_table(symtab *ptab, type *pt);
int is_symbol(symbol *p, char *);
int get_symbol_size(symbol *);
int get_type_size(type *);
int stoi(char *s,int radix);
void set_subrange_bound(type *pt,int lower,int upper);
void add_enum_elements(type *pt, symbol *symlist);
int set_align(int);
void make_system_symtab();

#endif