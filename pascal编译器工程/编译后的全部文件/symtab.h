#ifndef		_SYMTAB_H
#define 	_SYMTAB_H

typedef union val value;
typedef struct var_type type;
typedef struct sym symbol;
typedef struct symbol_table symtab;
//���б������ͣ������Զ������ͺ��ڽ�����
struct var_type
{
	char name[NAME_LEN];
	int size;
	int members; //�Զ������͵ĳ�Ա
	int type_id; //Ψһ��ʶ����
	symbol *begin,*end;
	type *next;
};
//������ֵ
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
//���Զ������͵Ĳ���
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
//���Žṹ
struct sym
{
    char name[NAME_LEN];
    char label[LABEL_LEN]; //�����ڻ���еı�ǩ
	value v;  //���ŵ�ֵ
    int obj_type; //��������
    type* type;	  //���ű�������
    int offset; //��������ǲ������߱��ر���������ƫ�ƣ����ڻ��
    symbol *next,*lchild,*rchild;
    symtab *tab; //�������ڷ��ű�����Ѱ�ҷ���ʱ�ݹ����ϼ����ű����
    type   *type_link;
};
//�Է��ŵĲ���
symbol *find_symbol(symtab *, char *);
symbol *find_element(symtab *, char *);
symbol *find_local_symbol(symtab *, char *);
symbol *find_field(symbol *, char *);
symbol *new_symbol(char *, int, int);
symbol *copy_symbol(symbol *);
symbol *reverse_parameters(symtab *);
symbol *copy_symbol_list(symbol *);
//���ű�ṹ
struct symbol_table
{
    char name[NAME_LEN];
    char label[LABEL_LEN]; //�ڻ���еı�ǩ
	int obj_type; //���ű�����
	type* type;
    int id;
    int level; //���ű�Ƕ�ײ�Σ��ڻ���б�ʶ�Ƿ���main��
    symbol *args,*locals,*lt; //��������̲����򱾵ر����������ڻ��
	int local_size,args_size; //���ڸ���ջ��ָ�����ƫ�ƻ�ȡ����
    type *type_link;
    symtab *parent;
};
//�Է��ű�Ĳ���
symtab *find_routine(char *);
symtab *new_system_sym(KEYENTRY);
symtab *find_sys_routine(int);
symtab *Global_symtab;
symtab *System_symtab[MAX_SYS_FUNCTION];
symtab *pop_symtab_stack();
symtab *top_symtab_stack();
symtab *new_symtab(symtab *);

int current_level;
//���ڷ�������ű�Ĳ���
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