#ifndef _RES_H
#define _RES_H
#endif

#ifndef MAX_HASHTABLE_SIZE
#define MAX_HASHTABLE_SIZE 23
#endif
typedef enum{boolean,integer,real,character,string,record,array,subrange,enumeration}idType;//ÉùÃ÷ÀàÐÍ
typedef enum {out_scale, program_head, const_define, type_define, var_define, function_define, function_body, procedure_define, procedure_body, mainprogram}program_flow;
typedef enum {anoperator, anid, value, namelist, comparation, logic, stmt, expr, root, valpara, varpara, parameter, 
			function, functhead, procedure, procehead, sysfunc, read,  idontknow}treeNodeType;
typedef enum {add, sub, mul, divv, mod, orr, andd, nott, ge, gt, le, lt, eq, ue, none}operationType;
typedef enum {assign, proc, compound, iff, repeat, whilee, forr, casee, gotoo, write, caseexp}stmtType;
struct Node
{
	idType type;
	int intValue;
	float realValue;
	char charValue;
	char* strValue;
	int boolValue;
};//¶ÔÓÚÊ÷ÖÐ½ÚµãÀàÐÍµÄ¶¨Òå

struct ExpNode
{
	idType type;
	int upper;//used if type==subrange
	int lower;
};

struct LabelTable{
	int label;
	int linenum;
	struct TreeNode* node_pt;
}ltable[100];

struct ConstTable{
	char name[30];
	struct Node* value;
}ctable[100];

struct TypeTable{
	char name[30];
	idType type;
}ttable[100];

struct EnumTable{
	char name[30];
	char content[100][30];
	int cnt;
}etable[50];
/*
struct VarTable{
	char name[30];
	struct Node* value;
}vtable[100];
*/

struct VariableTable{
	char name[30];
	struct Node* value;
	int copy_to_caller;
	struct VariableTable* next;
};

struct HashTables{
	char proce_name[30];
	struct VariableTable proce_table[MAX_HASHTABLE_SIZE];
	struct HashTables* caller_pointer;
};
struct HashTables* root_vt;
struct HashTables* cur_procedure_vt;

/*struct FunctProceHeadNode{
	char funct_proce_name[30];
	idType funct_proce_return_type;
};*/

struct TreeNode{
	struct TreeNode* next_sibling;
	struct TreeNode* left_child;
	struct TreeNode* right_child;
	treeNodeType node_type;//every treenode has a node_type
	operationType operation;//used if node_type==anoperator
	stmtType statement;//used if node_type==stmt
	int direction;//if node_type==stmt && statement==forr  0--TO; 1--DOWNTO 
	struct Node* case_const;//used if node_type==stmt && statement==cases
	struct Node* node_value;//used if node_type==value
	char id_name[30];//used if node_type==anid
	char funct_proce_name[30];//used if node_type==function/procedure
	//idType funct_proce_return_type;//used if node_type==function
	struct Node* funct_proce_return;//used if node_type==function
};
struct TreeNode* tree_root;
struct TreeNode* cur_function_head;
struct TreeNode* cur_procedure_head;


struct NameList{
	char name[30];
}nlist[100];
/*
struct Params{
	char name[30];
	idType type;
	int intValue;
	float realValue;
	char charValue;
	char* strValue;
	int boolValue;
};

struct DefineRelation{//双向链表
	char funct_proce_name[30];
	struct Params* params[20];//at most 20 params
	struct DefineRelation* subprocedure;//子级定义的过程
	struct DefineRelation* parentprocedure;//父级定义的过程
	struct DefineRelation* nextprocedure;//同级定义的过程
};
struct DefineRelation* define_main;
struct DefineRelation* cur_define;
*/

struct DefineRelation{
	char name[30];
	struct HashTables* curhashtable;
	struct TreeNode* node_pt;
	//struct DefineRelation* subprocedure[10];//子级定义的过程
	int parent_index;//父级定义的过程
	//struct DefineRelation* nextprocedure;//同级定义的过程
	//int sub_define_cnt;
}define_table[20];



char save[30];
char save1[30];
char type_define_save[30];
char var_define_save[30];
char cvalue[30];
char sys_type[30];
char fvalue[30];
char pvalue[30];
char assignID[30];
char forID[30];
char callerID[30];


void getId(char *);
void getConst(char *s);
void getAssignID(char *s);
void getForID(char *s);
void getType(char *s);
void getCallerID(char *s);

int CalculateHashNumber(char* varname);
void replaceInCaller(struct HashTables* caller, char* name, int hash, struct Node* src);
void initHashTable();
void addHashTable(char* proce_name);
void deleteHashTable();

void addToNameList(char *s);

void enumTableTraversal();
void hashTableTraversal();
void constTableTraversal();

